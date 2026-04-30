# Example module — all three handlers are OPTIONAL.
# Implement only the one(s) you need in your real module.
#
# Handler priority (only the most general one a module defines is called):
#   handle_update  >  handle_msg  >  handle_msg_txt
#
# Return True to stop dispatching to subsequent modules; return False/None to continue.
#
# Everything is single-threaded. Don't worry about race condition but don't block.


# OPTIONAL: called for every update (messages, edits, reads, etc.)
def handle_update(tg, update):
    # print(f"[example_mod] handle_update: type={update.get('@type')}")
    return False  # don't stop


# OPTIONAL: called only when the update contains a message (any content type)
def handle_msg(tg, chat_id, sender_id, msg_id, is_outgoing, message_content):
    print(f"[example_mod] handle_msg: chat={chat_id} sender={sender_id} msg={msg_id} is_outgoing={is_outgoing} type={message_content.get('@type')}")
    return False  # don't stop


# OPTIONAL: called only for plain-text messages
def handle_msg_txt(tg, chat_id, sender_id, msg_id, is_outgoing, message_text):
    print(f"[example_mod] handle_msg_txt: chat={chat_id} sender={sender_id} msg={msg_id} is_outgoing={is_outgoing} text={message_text!r}")
    return False  # don't stop


# OPTIONAL: called after login and chat preload, just before entering the event loop.
def handle_telegram_startup(tg):
    print("[example_mod] handle_telegram_startup: run your init task here...")


# OPTIONAL: called when the bot is shutting down. Return value is ignored.
def handle_telegram_exit(tg):
    print("[example_mod] handle_telegram_exit: run your cleanup here...")
