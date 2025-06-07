from collections import defaultdict, deque
import simpledb

buffers = defaultdict(lambda: deque())  # chat_id -> deque (acts as a queue)
BUFFER_SIZE = 16

def evacuate_buffer(buf):
    while buf:
        simpledb.append(buf.popleft())

def handle(chat_id, is_outgoing, sender_id, msg_id, message_text):
    buf = buffers[chat_id]
    msg = { 
        "chat_id": chat_id,
        "is_outgoing": is_outgoing,
        "sender_id": sender_id,
        "msg_id": msg_id,
        "message_text": message_text,
    }   
    if is_outgoing:
        evacuate_buffer(buf)
        buf.append(msg) # stay at buffer head!
    else:  # Incoming  
        buf.append(msg)  
        if len(buf) > BUFFER_SIZE:
            if buf[0]['is_outgoing']:  
                evacuate_buffer(buf)
            else:  
                buf.popleft()

#    for i in range(22):
#        message_handler("c1", False, i, f"incoming-{i}")
#    # send outgoing, should cause log of previous 16
#    message_handler("c1", True, 22, "OUTGOING!")
#    for i in range(22):
#        message_handler("c1", False, i, f"incoming-{i}")

