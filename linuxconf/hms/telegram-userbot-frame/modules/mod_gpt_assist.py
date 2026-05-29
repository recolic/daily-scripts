import json
import sys


CHAIN_LIMIT = 10
COMMAND_PREFIX = '!test'


def _wait_result(result, timeout=5):
    result.wait(timeout=timeout, raise_exc=False)
    if result.error:
        print(f"[mod_gpt_assist] Telegram API error: {result.error_info}", file=sys.stderr)
        return None
    return result.update


def _message_text(message):
    content = message.get('content') or {}
    if content.get('@type') != 'messageText':
        return None
    return content.get('text', {}).get('text', '')


def _sender_id(message):
    sender = message.get('sender_id') or {}
    if sender.get('@type') == 'messageSenderUser':
        return sender.get('user_id')
    if sender.get('@type') == 'messageSenderChat':
        return sender.get('chat_id')
    return None


def _message_summary(message):
    return {
        'chat_id': message.get('chat_id'),
        'msg_id': message.get('id'),
        'sender_id': _sender_id(message),
        'is_outgoing': message.get('is_outgoing'),
        'content_type': (message.get('content') or {}).get('@type'),
        'text': _message_text(message),
    }


def _reply_target(message):
    reply_to = message.get('reply_to')
    if isinstance(reply_to, dict) and reply_to.get('@type') == 'messageReplyToMessage':
        msg_id = reply_to.get('message_id')
        if msg_id:
            return reply_to.get('chat_id') or message.get('chat_id'), msg_id

    # Older TDLib versions used reply_to_message_id directly on the message.
    msg_id = message.get('reply_to_message_id')
    if msg_id:
        return message.get('chat_id'), msg_id

    return None


def _get_message(tg, chat_id, msg_id):
    if not chat_id or not msg_id:
        return None
    return _wait_result(tg.get_message(chat_id=chat_id, message_id=msg_id))


def _previous_message(tg, message):
    chat_id = message.get('chat_id')
    msg_id = message.get('id')
    if not chat_id or not msg_id:
        return None

    history = _wait_result(tg.get_chat_history(chat_id=chat_id, from_message_id=msg_id, offset=0, limit=3))
    if not history:
        return None

    for candidate in history.get('messages') or []:
        if candidate and candidate.get('id') != msg_id:
            return candidate
    return None


def _next_context_message(tg, message):
    target = _reply_target(message)
    if target:
        chat_id, msg_id = target
        return _get_message(tg, chat_id, msg_id)
    return _previous_message(tg, message)


def _print_context_chain(buf):
    print('context chain')
    for i, message in enumerate(buf, start=1):
        print(f"[{i}] {json.dumps(_message_summary(message), ensure_ascii=False, sort_keys=True)}")


def handle_update(tg, update):
    message = update.get('message')
    if not message or not message.get('is_outgoing'):
        return False

    text = _message_text(message)
    if text is None or not text.startswith(COMMAND_PREFIX):
        return False

    buf = []
    curr = message
    for _ in range(CHAIN_LIMIT):
        if not curr:
            break
        buf.append(curr)
        curr = _next_context_message(tg, curr)

    print(json.dumps([_message_summary(m) for m in buf], ensure_ascii=False, indent=2), file=sys.stderr)
    _print_context_chain(buf)
    return False
