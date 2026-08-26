import json
import importlib.util
import os
import sys
import time
import traceback
from functools import cache

##################### Configuration Begin ######################
ENABLED_GROUPS = []
DRYRUN_GROUPS = []
NEW_MEMBER_MAX_AGE = 2 * 24 * 60 * 60
BAN_TIME = 60 * 60
DRYRUN_LOG_FILE = './antispam_admin_dryrun.log.gi'
SPAM_EXAMPLE_FILE = './spam_example.log.gi'
RECOGPT_RELPATH = '../../../files/mybin/lib/recogpt.py'
##################### Configuration End ########################


def _try_import_rel(relpath, module_name):
    path = os.path.join(os.path.dirname(__file__), relpath)
    if not os.path.exists(path):
        return None
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        return None
    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except Exception:
        print(f'[mod_antispam_admin] failed to import {path}', file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        return None
    return mod


recogpt = _try_import_rel(RECOGPT_RELPATH, 'recogpt_antispam_admin')


def _wait(result):
    result.wait()
    update = result.update or {}
    if update.get('@type') == 'error':
        raise RuntimeError(f"Telegram error {update.get('code')}: {update.get('message')}")
    return update


def _contains_contact_link(text):
    return 't.me/' in text.lower() or '@' in text


def _message_text(message_content):
    text = message_content.get('text', {}).get('text', '')
    caption = message_content.get('caption', {}).get('text', '')
    return '\n'.join(part for part in (text, caption) if part)


def check_condition_1(tg, chat_id, sender_id, now):
    # joined within 2 days
    member = _wait(tg.call_method('getChatMember', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}}))
    joined_at = member.get('joined_chat_date', 0)
    return bool(joined_at and joined_at <= now and now - joined_at <= NEW_MEMBER_MAX_AGE)


def check_condition_2(tg, sender_id, message_content):
    # bio or message has contact link
    if _contains_contact_link(_message_text(message_content)):
        return True
    return _contains_contact_link(_get_bio_text(tg, sender_id))


def check_condition_3_is_spam(username, message_content):
    try:
        with open(SPAM_EXAMPLE_FILE, 'r', encoding='utf-8') as f:
            spam_examples = f.read()
    except OSError as e:
        print(f'[mod_antispam_admin] spam examples unavailable; assuming not_spam: {e}', file=sys.stderr)
        return False
    if recogpt is None:
        print('[mod_antispam_admin] AI unavailable; assuming not_spam', file=sys.stderr)
        return False
    prompt = f'''Your job: match the following username and message with these attached examples, to tell if a message is advertisement or not. Outout a single word `spam` or `not_spam`.

Input username: {username}
Input message: {_message_text(message_content)}

{spam_examples}'''
    for attempt in range(1, 4):
        try:
            response = recogpt.complete(recogpt.prompt_user(prompt), recogpt.impl_load("gpt56t")).strip().lower()
            if response == 'spam':
                return True
            if response == 'not_spam':
                return False
            raise ValueError(f'unexpected response: {response!r}')
        except Exception as e:
            print(f'[mod_antispam_admin] AI attempt {attempt}/3 failed: {type(e).__name__}: {e}', file=sys.stderr)
    print('[mod_antispam_admin] AI failed after 3 attempts; assuming not_spam', file=sys.stderr)
    return False


@cache
def _get_bio_text(tg, sender_id):
    user_info = _wait(tg.get_user_full_info(sender_id))
    return user_info.get('bio', {}).get('text', '')


@cache
def _get_username(tg, sender_id):
    user = _wait(tg.get_user(sender_id))
    usernames = user.get('usernames') or {}
    active_usernames = usernames.get('active_usernames') or []
    return usernames.get('editable_username') or (active_usernames[0] if active_usernames else '') or user.get('username', '')


def _log_violation(tg, chat_id, sender_id, msg_id, message_content, now):
    entry = {'timestamp': now, 'chat_id': chat_id, 'sender_id': sender_id, 'username': _get_username(tg, sender_id), 'msg_id': msg_id, 'message_text': _message_text(message_content), 'bio_text': _get_bio_text(tg, sender_id)}
    line = 'ANTISPAM DRYRUN: ' + json.dumps(entry, ensure_ascii=False)
    print(line)
    with open(DRYRUN_LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')


def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    if is_outgoing or (chat_id not in ENABLED_GROUPS and chat_id not in DRYRUN_GROUPS) or sender_id <= 0:
        return False

    now = int(time.time())
    if not check_condition_1(tg, chat_id, sender_id, now):
        return False
    if not check_condition_2(tg, sender_id, message_content):
        return False
    if not check_condition_3_is_spam(_get_username(tg, sender_id), message_content):
        return False

    _log_violation(tg, chat_id, sender_id, msg_id, message_content, now)
    if chat_id in DRYRUN_GROUPS:
        return False

    print(f'DEBUG: deleting spam and banning user for one hour: chat={chat_id} user={sender_id} msg={msg_id}')
    _wait(tg.delete_messages(chat_id, [msg_id]))
    _wait(tg.call_method('setChatMemberStatus', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}, 'status': {'@type': 'chatMemberStatusBanned', 'banned_until_date': now + BAN_TIME}}))
    return True