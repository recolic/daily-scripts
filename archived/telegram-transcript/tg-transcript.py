#!/usr/bin/python3 -u

from telegram.client import Telegram
import subprocess, sys
import handler_impl, simpledb
def rsec(k): return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()
prefix = '.'

tg = Telegram(
    api_id=rsec("Telegram_API_ID"),
    api_hash=rsec("Telegram_API_HASH"),
    phone=rsec("PHONE"),
    database_encryption_key='any_password',
    files_directory=prefix+'/tdlib_files.gi',
)

simpledb.dbpath = prefix+'/data.db.gi'

def new_message_handler(update):
    try:
        message_content = update['message']['content']
        sender = update['message']['sender_id']

        chat_id = update['message']['chat_id']
        msg_id = update['message']['id']
        sender_id = sender['user_id'] if sender['@type'] == 'messageSenderUser' else sender['chat_id']
        is_outgoing = update['message']['is_outgoing']
        message_text = message_content.get('text', {}).get('text', '')

        if message_content['@type'] == 'messageText':
            # print("Extract: text=", message_text, file=open(prefix+'/debug.log.gi', 'a'))
            handler_impl.handle(chat_id, is_outgoing, sender_id, msg_id, message_text)
        else:
            print("ignore non-text msg:" + str(message_content), msg_id, file=open(prefix+'/debug.log.gi', 'a'))
    except Exception as e:
        print(update, file=open(prefix+'/debug.log.gi', 'a'))
        print(type(e).__name__, e, file=open(prefix+'/debug.log.gi', 'a'))

if __name__ == "__main__":
    tg.login()

    # if this is the first run, library needs to preload all chats
    # otherwise the message will not be sent
    result = tg.get_chats()
    result.wait()
    print("Started Telegram Antispam Watchdog. API test by listing your chats: ", result.update)

    tg.add_message_handler(new_message_handler)
    tg.idle()  # blocking waiting for CTRL+C
    handler_impl.flush_on_exit()
    tg.stop()  # you must call `stop` at the end of the script

