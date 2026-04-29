# Example module — all three handlers are OPTIONAL.
# Implement only the one(s) you need in your real module.
#
# Handler priority (only the most general one a module defines is called):
#   handle_update  >  handle_msg  >  handle_msg_txt
#
# Return True to stop dispatching to subsequent modules; return False/None to continue.


# OPTIONAL: called for every update (messages, edits, reads, etc.)
def handle_update(tg, update):
    # print(f"[example_mod] handle_update: type={update.get('@type')}")
    return False  # don't stop


# OPTIONAL: called only when the update contains a message (any content type)
def handle_msg(tg, chat_id, sender_id, msg_id, message_content):
    print(f"[example_mod] handle_msg: chat={chat_id} sender={sender_id} msg={msg_id} type={message_content.get('@type')}")
    return False  # don't stop


# OPTIONAL: called only for plain-text messages
def handle_msg_txt(tg, chat_id, sender_id, msg_id, message_text):
    print(f"[example_mod] handle_msg_txt: chat={chat_id} sender={sender_id} msg={msg_id} text={message_text!r}")
    return False  # don't stop
