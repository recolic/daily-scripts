from collections import defaultdict, deque
import simpledb
import time

buffers = defaultdict(lambda: deque())  # chat_id -> deque (acts as a queue)
BUFFER_SIZE = 16
SAVE_FUTURE_CONTEXT = True

def evacuate_buffer(buf):
    while buf:
        simpledb.append(buf.popleft())

def handle_msg_txt(tg, chat_id, sender_id, msg_id, is_outgoing, message_text):
    buf = buffers[chat_id]
    msg = {
        "ts": int(time.time()),
        "chat_id": chat_id,
        "is_outgoing": is_outgoing,
        "sender_id": sender_id,
        "msg_id": msg_id,
        "message_text": message_text,
    }
    if SAVE_FUTURE_CONTEXT:  # save both previous msg and following msg
        if is_outgoing:
            evacuate_buffer(buf)
            buf.append(msg)  # stay at buffer head!
        else:  # Incoming
            buf.append(msg)
            if len(buf) > BUFFER_SIZE:
                if buf[0]['is_outgoing']:
                    evacuate_buffer(buf)
                else:
                    buf.popleft()
    else:  # save only previous msg
        buf.append(msg)
        if is_outgoing:
            evacuate_buffer(buf)
        elif len(buf) > BUFFER_SIZE:
            buf.popleft()
    return False  # don't stop other modules

def handle_telegram_exit(tg):
    for k in buffers:
        buf = buffers[k]
        if buf and buf[0]['is_outgoing']:
            evacuate_buffer(buf)
