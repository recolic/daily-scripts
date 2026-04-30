import threading
import time
import os

##################### Configuration Begin ######################
YOUR_QUESTION = '12 + 16 = ?'
YOUR_ANSWER = '28'
##################### Configuration End ########################

WHITELIST_FILE = './whitelisted_chats.log'
magic_text = '[tqYH5C]'
msg_verify = 'This account is protected by Telegram Antispam WatchDog.\nPlease answer the question to continue:\n请正确回答以下问题:\n\n' + YOUR_QUESTION
msg_whitelisted = '[Telegram Antispam Watchdog] Whitelisted this chat.'
msg_passed = 'You have passed the verification. Thanks!\n你已经通过验证, 感谢你的理解!'

whitelisted_chat_ids = []
remove_gms_notify_queue = []
remove_gms_notify_queue_lock = threading.Lock()
_timer_thread = None
_running = False


def _timer_loop(tg):
    while _running:
        with remove_gms_notify_queue_lock:
            remaining = []
            for chat_id, msg_id, count in remove_gms_notify_queue:
                tg._tdjson.send({'@type': 'openChat', 'chat_id': chat_id})
                tg._tdjson.send({'@type': 'viewMessages', 'chat_id': chat_id, 'message_ids': [msg_id], 'force_read': True})
                if count - 1 > 0:
                    remaining.append((chat_id, msg_id, count - 1))
                else:
                    tg._tdjson.send({'@type': 'closeChat', 'chat_id': chat_id})
            remove_gms_notify_queue[:] = remaining
        time.sleep(1)


def handle_telegram_startup(tg):
    global _running, _timer_thread
    try:
        with open(WHITELIST_FILE, 'r') as f:
            for l in f.read().split('\n'):
                if l:
                    whitelisted_chat_ids.append(int(l))
    except FileNotFoundError:
        pass
    _running = True
    _timer_thread = threading.Thread(target=_timer_loop, args=(tg,), daemon=True)
    _timer_thread.start()


def handle_telegram_exit(tg):
    global _running
    _running = False


def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    # Only handle private chats, skip groups and Telegram system
    if chat_id < 0 or chat_id == 777000:
        return False
    if chat_id in whitelisted_chat_ids:
        return False

    message_text = message_content.get('text', {}).get('text', '')

    if is_outgoing:
        # Any outgoing message (except our own verification) whitelists the chat
        if magic_text not in message_text:
            whitelisted_chat_ids.append(chat_id)
            with open(WHITELIST_FILE, 'w+') as f:
                f.write('\n'.join(str(i) for i in whitelisted_chat_ids))
            tg.send_message(chat_id=chat_id, text=msg_whitelisted)
        return False

    # Incoming unverified message: suppress notification
    tg._tdjson.send({'@type': 'openChat', 'chat_id': chat_id})
    tg._tdjson.send({'@type': 'viewMessages', 'chat_id': chat_id, 'message_ids': [msg_id], 'force_read': True})

    if message_content['@type'] == 'messageText' and message_text.lower() == YOUR_ANSWER.lower():
        whitelisted_chat_ids.append(chat_id)
        with open(WHITELIST_FILE, 'w+') as f:
            f.write('\n'.join(str(i) for i in whitelisted_chat_ids))
        tg.send_message(chat_id=chat_id, text=msg_passed)
    else:
        tg.send_message(chat_id=chat_id, text=magic_text + msg_verify)
        tg.delete_messages(chat_id, [msg_id])
        with remove_gms_notify_queue_lock:
            remove_gms_notify_queue.append((chat_id, msg_id, 16))

    return True  # stop other modules from processing unverified private messages
