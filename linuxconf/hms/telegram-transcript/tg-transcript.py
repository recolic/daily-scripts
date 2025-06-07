#!/usr/bin/python3 -u

from telegram.client import Telegram
import subprocess, sys
import handler_impl, simpledb
def rsec(k): return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()
prefix = sys.argv[1] if len(sys.argv) > 1 else '.'

tg = Telegram(
    api_id=rsec("Telegram_API_ID"),
    api_hash=rsec("Telegram_API_HASH"),
    phone=rsec("PHONE"),
    database_encryption_key='any_password',
    files_directory=prefix+'/tdlib_files.gi',
)

whitelist_filename = prefix+'/whitelisted_chats.log'
whitelisted_chat_ids = []
simpledb.dbpath = prefix+'/data.db.gi'

def read_whitelist_from_disk(fname):
    try:
        with open(fname, 'r') as f:
            for l in f.read().split('\n'):
                if l != '':
                    whitelisted_chat_ids.append(int(l))
    except FileNotFoundError:
        pass

def new_message_handler(update):
    try:
        message_content = update['message']['content']
        sender = update['message']['sender_id']

        chat_id = update['message']['chat_id']
        msg_id = update['message']['id']
        sender_id = sender['user_id'] if sender['@type'] == 'messageSenderUser' else sender['chat_id']
        is_outgoing = update['message']['is_outgoing']
        message_text = message_content.get('text', {}).get('text', '')

        if chat_id in whitelisted_chat_ids:
            return

        if message_content['@type'] == 'messageText':
            print("Extract: text=", message_text, file=open(prefix+'/debug.log.gi', 'a'))
            handler_impl.handle(chat_id, is_outgoing, sender_id, msg_id, message_text)
        else:
            print("ignore non-text msg", msg_id)
    except Exception as e:
        print(update, file=open(prefix+'/debug.log.gi', 'a'))
        print(type(e).__name__, e, file=open(prefix+'/debug.log.gi', 'a'))

if __name__ == "__main__":
    read_whitelist_from_disk(whitelist_filename)
    tg.login()

    # if this is the first run, library needs to preload all chats
    # otherwise the message will not be sent
    result = tg.get_chats()
    result.wait()
    print("Started Telegram Antispam Watchdog. API test by listing your chats: ", result.update)

    tg.add_message_handler(new_message_handler)
    tg.idle()  # blocking waiting for CTRL+C
    tg.stop()  # you must call `stop` at the end of the script

