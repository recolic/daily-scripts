#!/usr/bin/python3 -u

from telegram.client import Telegram
import subprocess, sys, os, importlib.util
def rsec(k): return subprocess.run(['rsec', k], check=True, capture_output=True, text=True).stdout.strip()
prefix = '.'

tg = Telegram(
    api_id=rsec("Telegram_API_ID"),
    api_hash=rsec("Telegram_API_HASH"),
    phone=rsec("PHONE"),
    database_encryption_key='any_password',
    files_directory=prefix+'/tdlib_files.gi',
)

# Load all modules from ./modules/
modules = []
modules_dir = os.path.join(os.path.dirname(__file__), 'modules')
if modules_dir not in sys.path:
    sys.path.insert(0, modules_dir)
for fname in sorted(os.listdir(modules_dir)):
    if fname.endswith('.py') and fname.startswith('mod_'):
        fpath = os.path.join(modules_dir, fname)
        spec = importlib.util.spec_from_file_location(fname[:-3], fpath)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        modules.append(mod)
        print(f"Loaded module: {fname}")

def new_message_handler(update):
    try:
        msg = update.get('message')
        chat_id = sender_id = msg_id = content = message_text = None
        is_text = False

        if msg:
            content = msg['content']
            sender = msg['sender_id']
            chat_id = msg['chat_id']
            msg_id = msg['id']
            sender_id = sender['user_id'] if sender['@type'] == 'messageSenderUser' else sender['chat_id']
            is_outgoing = msg['is_outgoing']
            is_text = content['@type'] == 'messageText'
            if is_text:
                message_text = content.get('text', {}).get('text', '')

        for mod in modules:
            stop = False
            if hasattr(mod, 'handle_update'):
                stop = mod.handle_update(tg, update)
            elif msg and hasattr(mod, 'handle_msg'):
                stop = mod.handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, content)
            elif msg and is_text and hasattr(mod, 'handle_msg_txt'):
                stop = mod.handle_msg_txt(tg, chat_id, sender_id, msg_id, is_outgoing, message_text)
            if stop:
                break
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

    for mod in modules:
        if hasattr(mod, 'handle_telegram_startup'):
            mod.handle_telegram_startup()
    tg.add_message_handler(new_message_handler)
    tg.idle()  # blocking waiting for CTRL+C
    for mod in modules:
        if hasattr(mod, 'handle_telegram_exit'):
            mod.handle_telegram_exit()
    tg.stop()  # you must call `stop` at the end of the script

