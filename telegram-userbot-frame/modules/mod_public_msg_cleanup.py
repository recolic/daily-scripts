import os
import time

# This module auto-cleans old self-sent messages in non-whitelisted group chats.
# Cache format is plain text: one row per event as "timestamp:chatid:msgid".

WHITELIST_CHATS = ['-690297292', '-1001950885622']
MSG_ALIVE_TIME = 24 * 60 * 60  # Delete messages older than 1 day.
CACHE_FILE = './msg_cleanup.db.gi'

_prev_ts = None


def result_of(async_result):
    async_result.wait()
    return async_result.update


def _chat_is_whitelisted(chat_id):
    return chat_id in WHITELIST_CHATS or str(chat_id) in WHITELIST_CHATS


def _day_id(ts):
    return time.strftime('%Y-%m-%d', time.localtime(ts))


def _parse_row(line):
    line = line.strip()
    if not line:
        return None
    try:
        ts_str, chat_id_str, msg_id_str = line.split(':', 2)
        return int(ts_str), int(chat_id_str), int(msg_id_str)
    except Exception:
        return None


def _append_cache_record(ts, chat_id, msg_id):
    with open(CACHE_FILE, 'a', encoding='utf-8') as f:
        f.write(f'{int(ts)}:{int(chat_id)}:{int(msg_id)}\n')


def _run_cleanup_by_cache(tg, now_ts):
    if not os.path.exists(CACHE_FILE):
        return

    current_day = _day_id(now_ts)
    keep_rows = []
    delete_by_chat = {}

    with open(CACHE_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            row = _parse_row(line)
            if row is None:
                continue
            ts, chat_id, msg_id = row

            # Keep current-day rows; delete rows from previous days.
            if _day_id(ts) == current_day:
                keep_rows.append((ts, chat_id, msg_id))
                continue

            if _chat_is_whitelisted(chat_id):
                continue

            delete_by_chat.setdefault(chat_id, []).append(msg_id)

    for chat_id, msg_ids in delete_by_chat.items():
        try:
            tg.delete_messages(str(chat_id), msg_ids)
        except Exception as e:
            print(type(e).__name__, e)

    with open(CACHE_FILE, 'w', encoding='utf-8') as f:
        for ts, chat_id, msg_id in keep_rows:
            f.write(f'{ts}:{chat_id}:{msg_id}\n')


# Module interface: called on every message update.
def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    global _prev_ts

    if not is_outgoing:
        return False
    if _chat_is_whitelisted(chat_id):
        return False

    now_ts = int(time.time())

    _append_cache_record(now_ts, chat_id, msg_id)

    if _prev_ts is not None and _day_id(_prev_ts) != _day_id(now_ts):
        _run_cleanup_by_cache(tg, now_ts)

    _prev_ts = now_ts

    return False
