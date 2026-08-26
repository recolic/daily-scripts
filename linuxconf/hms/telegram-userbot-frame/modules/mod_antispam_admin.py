import json
import importlib.util
import os
import sys
import time
import traceback
from functools import cache

##################### Configuration Begin ######################
ENABLED_GROUPS = []
DRYRUN_GROUPS = [-1001561894350, -1003337407536, -1001224518181, -1001792060257, -1001262613096]
NEW_MEMBER_AGE = 2 * 24 * 60 * 60
DRYRUN_LOG_FILE = './antispam_admin_dryrun.log.gi'
RECOGPT_RELPATH = '../../../files/mybin/lib/recogpt.py'
##################### Configuration End ########################

SPAM_EXAMPLE_TEXT = """
spam message example:
团队‌缺几​个没事做​‧的兄弟​，下个⁠月‌一起提奔​驰！‍安排到​位⁠，看​煮叶
他‌奶‌奶的‌  ​这个·兄弟相‌木·这么⁠牛·逼‌吗  ⁠一​天搞好‌几·个‌Ｗ  👀煮页 缺人⁠速教⁠
找几·位‍空闲的‧哥们⁠一‌起干点‍·事，两⁠个月‍·后·直‍接开宝‍马‍，给⁠你安​排到‧位​，看‍我‧筑‍夜
解决域名被墙无法访问  @RaySun101
出香港🇭🇰美国🇺🇸新加坡🇸🇬服务器❤️‍🔥 免测✅ 免实名✅ 不限内容✅ 需要可以联系我哦    @RaySun101
最·近缺收入⁠‧的看‧过⁠来‌💰　⁠拍‍照兼职，日结７０0⁠左‍右​！
有‧没有闲‌着‌的？手‌机‍拍‌照就​能做‍📱‌  ‌无⁠经⁠验⁠也可以！‌
会用手机拍‌照​·就‌行‌📸 不需​专⁠业​，完‌成⁠当天结⁠算！
想找‍轻·松兼职吗‍？⁠📸‍　‍按‌要求​拍⁠照，完‍成就结‌‧算！⁠
广东iepl专线 ✔️低延迟 · 高稳定 · 少丢包 ✔️全天候稳定在线 ✔️独享带宽 💬咨询：@zorlink000  📢群组：@zorlink222
美西高性能独服上线，1G带宽不限速跑满，电信联通移动三网优化，CIA+CMI回国精品线路，支持测试。
有没有想学搭建的
⚡️ 【皮卡丘专线 · 华为云 BGP 震撼来袭】 ⚡️还在为延迟和通报发愁？顶配网络它来了！🥇 极致三网调优：畅享丝滑体验，延迟低到难以想象！  🛡 双重安全护航：官方独家提供售后整改，可吃 2 次通报！💰 性价比之王：价格美丽，配置拉满，绝不让您踩坑！🌐 官方正版通道，认准皮卡丘：@abc787888

spam username example:
simon 全球IDC-免实名可测
{看-个-签}7·折·出·iphOne17·水·果·机·全·系·列
"""

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
    return (not joined_at) or (joined_at <= now and now - joined_at <= NEW_MEMBER_AGE)


def check_condition_2(tg, sender_id, message_content):
    # bio or message has contact link
    if _contains_contact_link(_message_text(message_content)):
        return True
    return _contains_contact_link(_get_bio_text(tg, sender_id))


def check_condition_3(username, message_content):
    # GPT check if msg is spam
    if recogpt is None:
        print('[mod_antispam_admin] AI unavailable; assuming not_spam', file=sys.stderr)
        return False
    prompt = f'''Your job: match the following username and message with these attached examples, to tell if a message is advertisement or not. Outout a single word `spam` or `not_spam`.
Only check for these matching existing pattern. Internal log message from other bot are not spam.

Input username: {username}
Input message: {_message_text(message_content)}

{SPAM_EXAMPLE_TEXT}'''
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
    if not check_condition_3(_get_username(tg, sender_id), message_content):
        return False

    _log_violation(tg, chat_id, sender_id, msg_id, message_content, now)
    if chat_id in DRYRUN_GROUPS:
        return False

    print(f'DEBUG: deleting spam and permanently banning user: chat={chat_id} user={sender_id} msg={msg_id}')
    _wait(tg.delete_messages(chat_id, [msg_id]))
    _wait(tg.call_method('setChatMemberStatus', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}, 'status': {'@type': 'chatMemberStatusBanned', 'banned_until_date': 0}}))
    notice = f'''User ID: {sender_id}
Based on our review, we determined that your account violated Telegram Terms of Service. As a result, your account has been permanently banned.
We are unable to disclose the specific policies or criteria used to reach this decision.
To submit an appeal, please contact @pakstv.
Thank you.'''
    _wait(tg.send_message(chat_id=chat_id, text=notice))
    return True