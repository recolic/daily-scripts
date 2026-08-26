import json
import time
from functools import cache

##################### Configuration Begin ######################
ENABLED_GROUPS = []
DRYRUN_GROUPS = []
NEW_MEMBER_MAX_AGE = 2 * 24 * 60 * 60
BAN_TIME = 60 * 60
DRYRUN_LOG_FILE = './antispam_admin_dryrun.log.gi'
##################### Configuration End ########################


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


def check_condition_3_is_spam(message_content):
    # TODO: Replace this placeholder with the real spam check.
    return False


@cache
def _get_bio_text(tg, sender_id):
    user_info = _wait(tg.get_user_full_info(sender_id))
    return user_info.get('bio', {}).get('text', '')


def _log_dryrun_violation(tg, chat_id, sender_id, msg_id, message_content, now):
    entry = {'timestamp': now, 'chat_id': chat_id, 'sender_id': sender_id, 'msg_id': msg_id, 'message_text': _message_text(message_content), 'bio_text': _get_bio_text(tg, sender_id)}
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
    if not check_condition_3_is_spam(message_content):
        return False

    _log_dryrun_violation(tg, chat_id, sender_id, msg_id, message_content, now)
    if chat_id in DRYRUN_GROUPS:
        return False

    print(f'DEBUG: deleting spam and banning user for one hour: chat={chat_id} user={sender_id} msg={msg_id}')
    _wait(tg.delete_messages(chat_id, [msg_id]))
    _wait(tg.call_method('setChatMemberStatus', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}, 'status': {'@type': 'chatMemberStatusBanned', 'banned_until_date': now + BAN_TIME}}))
    return True