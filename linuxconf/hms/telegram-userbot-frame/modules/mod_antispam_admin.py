import json
import importlib.util
import os
import sys
import time
import traceback
from functools import cache

##################### Configuration Begin ######################
ENABLED_GROUPS = [-1001561894350]
DRYRUN_GROUPS = [-1003337407536, -1001224518181, -1001792060257, -1001262613096]
NEW_MEMBER_AGE = 3 * 24 * 60 * 60
WHITELIST_FILE = './whitelist.gi'
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
多模型 API 接入，主页有说明

spam username example:
simon 全球IDC-免实名可测
{看-个-签}7·折·出·iphOne17·水·果·机·全·系·列

spam bio example:
中转站 @ababab 资源群：https://t.me/ababab_token
g此.号不回复.宝子!日保底2k稿.咪入口：https://t.me/+K7C5swg-rnkzMTY1 客服: @lulutop0 /
"""

NOTICE_TEMPLATE = '''User ID: __user_id__
Based on our review, we determined that your account violated Telegram Terms of Service. As a result, your account has been permanently banned.
We are unable to disclose the specific policies or criteria used to reach this decision.
To submit an appeal, please contact @pakstv.
Thank you.'''

# -1 for banned; 0-2 for number of good msg; >2 for whitelisted.
decision_cache = {}

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
    # joined within 3 days
    member = _wait(tg.call_method('getChatMember', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}}))
    joined_at = member.get('joined_chat_date', 0)
    return (not joined_at) or (joined_at <= now and now - joined_at <= NEW_MEMBER_AGE)


def check_condition_2(tg, sender_id, message_content):
    # bio or message has contact link
    if _contains_contact_link(_message_text(message_content)):
        return True
    return _contains_contact_link(_get_bio_text(tg, sender_id))


def check_condition_3(username, bio_text, message_content):
    # GPT check if msg is spam
    if recogpt is None:
        print('[mod_antispam_admin] AI unavailable; assuming not_spam', file=sys.stderr)
        return False
    prompt = f'''Your job: match the following input with these attached examples, to tell if a message is advertisement or not. Outout a single word `spam` or `not_spam`.
Internal log message from other bot are not spam.

Input username: {username}
Input bio: {bio_text}
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
    bio = user_info.get('bio')
    if bio is None:
        print(f'[mod_antispam_admin] invalid user info for user {sender_id}: {json.dumps(user_info, ensure_ascii=False, default=repr)}', file=sys.stderr)
        return ''
    return bio.get('text', '')


@cache
def _get_username(tg, sender_id):
    user = _wait(tg.get_user(sender_id))
    return ' '.join(part for part in (user.get('first_name', ''), user.get('last_name', '')) if part)


def on_decision(tg, chat_id, sender_id, msg_id, message_content, now, decision):
    ## 1 - debug log
    entry = {'timestamp': now, 'chat_id': chat_id, 'sender_id': sender_id, 'username': _get_username(tg, sender_id), 'msg_id': msg_id, 'message_text': _message_text(message_content), 'bio_text': _get_bio_text(tg, sender_id), 'decision': decision}
    line = 'ANTISPAM DRYRUN: ' + json.dumps(entry, ensure_ascii=False)
    print(line)
    with open(DRYRUN_LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')
    ## 2 - action: update cache
    if decision == 'ban':
        decision_cache[sender_id] = -1
    else:
        decision_cache[sender_id] = decision_cache.get(sender_id, 0) + 1
    ## 3 - action: ban
    if decision == 'ban' and chat_id in ENABLED_GROUPS:
        print(f'DEBUG: deleting spam and permanently banning user: chat={chat_id} user={sender_id} msg={msg_id}')
        _wait(tg.delete_messages(chat_id, [msg_id]))
        _wait(tg.call_method('setChatMemberStatus', params={'chat_id': chat_id, 'member_id': {'@type': 'messageSenderUser', 'user_id': sender_id}, 'status': {'@type': 'chatMemberStatusBanned', 'banned_until_date': 0}}))
        # _wait(tg.send_message(chat_id=chat_id, text=NOTICE_TEMPLATE.replace('__user_id__', str(sender_id))))


def handle_telegram_startup(tg):
    if not os.path.exists(WHITELIST_FILE):
        return
    with open(WHITELIST_FILE, encoding='utf-8') as f:
        decision_cache.update((int(sender_id), decision) for sender_id, decision in json.load(f).items())


def handle_telegram_exit(tg):
    with open(WHITELIST_FILE, 'w', encoding='utf-8') as f:
        json.dump(decision_cache, f, sort_keys=True)



def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    now = int(time.time())
    if is_outgoing or (chat_id not in ENABLED_GROUPS and chat_id not in DRYRUN_GROUPS) or sender_id <= 0:
        return False
    
    if decision_cache.get(sender_id, 0) >= 3:
        return False
    if decision_cache.get(sender_id, 0) == -1:
        on_decision(tg, chat_id, sender_id, msg_id, message_content, now, 'ban')
        return True

    if not check_condition_1(tg, chat_id, sender_id, now):
        on_decision(tg, chat_id, sender_id, msg_id, message_content, now, 'c1pass')
        return False
    if not check_condition_2(tg, sender_id, message_content):
        on_decision(tg, chat_id, sender_id, msg_id, message_content, now, 'c2pass')
        return False
    if not check_condition_3(_get_username(tg, sender_id), _get_bio_text(tg, sender_id), message_content):
        on_decision(tg, chat_id, sender_id, msg_id, message_content, now, 'c3pass')
        return False
    on_decision(tg, chat_id, sender_id, msg_id, message_content, now, 'ban')
    return True
