#!/usr/bin/python3 -u

##################### Configuration Begin ######################
YOUR_QUESTION = '12 + 16 = ?'
YOUR_ANSWER = '28'
##################### Configuration End ########################

import threading, time, os

whitelist_filename = 'whitelisted_chats.log'
whitelisted_chat_ids = []

magic_text = '[tqYH5C]'
msg_verify = 'This account is protected by Telegram Antispam WatchDog.\nPlease answer the question to continue:\n请正确回答以下问题:\n\n' + YOUR_QUESTION
msg_whitelisted = '[Telegram Antispam Watchdog] Whitelisted this chat.'
msg_passed = 'You have passed the verification. Thanks!\n你已经通过验证, 感谢你的理解!'

def read_whitelist_from_disk(fname):
    try:
        with open(fname, 'r') as f:
            for l in f.read().split('\n'):
                if l != '':
                    whitelisted_chat_ids.append(int(l))
    except FileNotFoundError:
        pass

def write_whitelist_to_disk(fname):
    with open(fname, 'w+') as f:
        f.write('\n'.join([str(i) for i in whitelisted_chat_ids]))

def mark_msg_read(tg, chat_id, msg_id):
    # This function must be called multiple times. For example, call it once a second, for 8 times.
    # You must call mark_msg_read_finish() after the last mark_msg_read(). You must wait as long as possible before calling mark_msg_read_finish(), to make the mark_msg_read reliable.
    # This problem only appears in GMS notification.
    fn_data = {
        '@type': 'openChat',
        'chat_id': chat_id,
    }
    tg._tdjson.send(fn_data)

    fn_data = {
        '@type': 'viewMessages',
        'chat_id': chat_id,
        'message_ids': [msg_id],
        'force_read': True,
    }
    tg._tdjson.send(fn_data)

def mark_msg_read_finish(tg, chat_id):
    fn_data = {
        '@type': 'closeChat',
        'chat_id': chat_id,
    }
    tg._tdjson.send(fn_data)



def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    message_text = message_content.get('text', {}).get('text', '')

    # This handler will block all message which satisfies ALL of the following condition:
    # 1. Incoming
    # 2. Not from group chat (Personal chat)
    # 3. chat_id is not in whitelist
    # 4. chat_id is not 777000 (Telegram official notification)
    # Maybe we can whitelist sender_id instead of chat_id, but I think it doesn't make a difference.

    if chat_id < 0 or chat_id == 777000:
        return
    if chat_id in whitelisted_chat_ids:
        return
    if is_outgoing:
        # Send any outgoing message to add unknown chat to whitelist. (Except verification message)
        if magic_text not in message_text:
            whitelisted_chat_ids.append(chat_id)
            write_whitelist_to_disk(whitelist_filename)
            tg.send_message(chat_id=chat_id, text=msg_whitelisted)
        return

    print("DEBUG: Received a new private chat message which needs verification, chat_id=", chat_id)

    # Mark as read to suppress the notification.
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read(tg, chat_id, msg_id)
    mark_msg_read_finish(tg, chat_id)

    if message_content['@type'] == 'messageText' and message_text.lower() == YOUR_ANSWER.lower():
        # Answer is correct: add to whitelist and send hello
        print("DEBUG: good answer")
        whitelisted_chat_ids.append(chat_id)
        write_whitelist_to_disk(whitelist_filename)
        tg.send_message(chat_id=chat_id, text=msg_passed)
    else:
        # Answer is not correct: send verification message and delete his message.
        print("DEBUG: bad answer")
        tg.send_message(chat_id=chat_id, text=magic_text + msg_verify)
        tg.delete_messages(chat_id, [msg_id])
##### tmp: this is later found unnecessary... spamming mark_msg_read in handler is enough.
# #         with remove_gms_notify_queue_lock:
# #             remove_gms_notify_queue.append((chat_id, msg_id, 16))
##### tmp: this is later found unnecessary... spamming mark_msg_read in handler is enough.
# # # We need to mark_message_read() for 30 times, with one second interval. That's the only method to eliminate GMS notification.
# # # Format: [(chat_id, msg_id, count), ...]
# # # count will decrease from 30 to 0 by a timer in another thread.
# # remove_gms_notify_queue = []
# # remove_gms_notify_queue_lock = threading.Lock()
# # def timer_handler(tg):
# #     # In every second, check if there is any message to be marked as read.
# #     global remove_gms_notify_queue
# #     with remove_gms_notify_queue_lock:
# #         result_list = []
# #         for entry in remove_gms_notify_queue:
# #             chat_id, msg_id, count = entry
# #             mark_msg_read(tg, chat_id, msg_id)
# #             if count-1 > 0:
# #                 result_list.append((chat_id, msg_id, count-1))
# #             else:
# #                 mark_msg_read_finish(tg, chat_id)
# #         remove_gms_notify_queue = result_list
# # def timer_thread_func(tg):
# #     while True:
# #         timer_handler(tg)
# #         time.sleep(1)

def handle_telegram_startup(tg):
    read_whitelist_from_disk(whitelist_filename)
    
    print("Started Telegram Antispam Watchdog. (mod)")

    ## tmp: this is later found unnecessary... spamming mark_msg_read in handler is enough.
    ## threading.Thread(target=timer_thread_func, args=(tg,)).start()

