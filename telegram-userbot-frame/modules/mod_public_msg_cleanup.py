import os
import time

# This module auto-cleans old self-sent messages in non-whitelisted group chats.
# Cache format is plain text: one row per event as "timestamp:chatid:msgid".

WHITELIST_CHATS = ['-690297292', '-1001950885622']
MSG_ALIVE_TIME = 24 * 60 * 60  # Delete messages older than 1 day.
CACHE_FILE = './msg_cleanup.db.gi'

_prev_ts = None


def slow_cleanup(tg, now_ts):
    if not os.path.exists(CACHE_FILE):
        return

    keep_rows = []
    delete_by_chat = {}

    with open(CACHE_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ts, chat_id, msg_id = [int(s) for s in line.split(':', 2)]
                if now_ts - ts > MSG_ALIVE_TIME:
                    delete_by_chat.setdefault(chat_id, []).append(msg_id)
                else:
                    keep_rows.append((ts, chat_id, msg_id))
            except Exception:
                continue

    for chat_id, msg_ids in delete_by_chat.items():
        try:
            print(f"DEBUG: delete msg chat={chat_id} msg={msg_ids}")
            tg.delete_messages(str(chat_id), msg_ids)
        except Exception as e:
            print(type(e).__name__, e)

    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        for ts, chat_id, msg_id in keep_rows:
            f.write(f'{ts}:{chat_id}:{msg_id}\n')


# Module interface: called on every message update.
def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    global _prev_ts

    if is_outgoing and str(chat_id) not in WHITELIST_CHATS:
        now_ts = int(time.time())

        with open(CACHE_FILE, 'a', encoding='utf-8') as f:
            f.write(f'{now_ts}:{int(chat_id)}:{int(msg_id)}\n')

        if _prev_ts and (_prev_ts // 86400) != (now_ts // 86400):
            slow_cleanup(tg, now_ts)

        _prev_ts = now_ts

    return False
