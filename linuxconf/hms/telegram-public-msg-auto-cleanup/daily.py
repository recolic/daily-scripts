#!/usr/bin/python3 -u

# This script will automatically delete your history message in all joined groups.
# It will check the latest messages (until `n` seconds ago) of each joined group, and delete the message if:
#    1. It was sent from you
#    2. The group is not whitelisted in (WHITELIST_CHATS)
#    3. The group was sent at least `t` seconds ago
#
# `n` is MSG_DOWNLOAD_LIMIT, `t` is MSG_ALIVE_TIME
# It's recommended to auto-run this script daily.

##################### Configuration Begin ######################
WHITELIST_CHATS = ['-690297292', '-1001950885622']

MSG_DOWNLOAD_TIME_LIMIT = 3*24*60*60 # 2 days ago. Set to '0' for dry-run, set to a huge number for first-run.
MSG_ALIVE_TIME = 24*60*60 # 1 day
##################### Configuration End ########################

from telegram.client import Telegram
import time
import subprocess, sys
def rsec(k): return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()
prefix = sys.argv[1] if len(sys.argv) > 1 else '.'

tg = Telegram(
    api_id=rsec("Telegram_API_ID"),
    api_hash=rsec("Telegram_API_HASH"),
    phone=rsec("PHONE"), # you can pass 'bot_token' instead
    database_encryption_key='my_password',
    files_directory=prefix+'/tdlib_files',
)

def result_of(async_result):
    async_result.wait()
    return async_result.update

def delete_all_msg_from_me(telegram, group_id, pull_time_limit, my_userid):
    receive = True
    from_message_id = 0
    stats_data = {}
    processed_msg_count = 0
    current_timestamp = time.time()

    while receive:
        response = telegram.get_chat_history(
            chat_id=group_id,
            limit=1000,
            from_message_id=from_message_id,
        )
        response.wait()

        msg_to_delete = []
        for message in response.update['messages']:
            if message['date'] < current_timestamp - pull_time_limit:
                receive = False
                break
            if message['sender_id']['@type'] != 'messageSenderUser':
                # Not sent from user. Ignore it.
                from_message_id = message['id']
                continue
            if message['sender_id']['user_id'] == my_userid and message['date'] < current_timestamp - MSG_ALIVE_TIME:
                msg_to_delete.append(message['id'])
            else:
                from_message_id = message['id']

        if msg_to_delete != []:
            print("DEBUG: delete msg count=", len(msg_to_delete))
            tg.delete_messages(group_id, msg_to_delete)

        if not response.update['total_count']:
            receive = False

        processed_msg_count += len(response.update['messages'])
        print(f'[{processed_msg_count}] processed')


if __name__ == '__main__':
    tg.login()

    my_id = result_of(tg.get_me())['id']
    print("myid=", my_id)

    for chatid in result_of(tg.get_chats())['chat_ids']:
        if chatid >= 0:
            print(f"Ignore chat_id {chatid}, not a group")
            continue
        group_title = result_of(tg.get_chat(chatid))['title']
        print("Will cleaning up chat_id ", chatid, group_title)
        if chatid in WHITELIST_CHATS or str(chatid) in WHITELIST_CHATS:
            print(f"Ignore chat_id {chatid}, whitelisted")
            continue
        delete_all_msg_from_me(tg, str(chatid), MSG_DOWNLOAD_TIME_LIMIT, my_id)

    tg.stop()

