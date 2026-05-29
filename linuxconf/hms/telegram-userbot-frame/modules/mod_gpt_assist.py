import json
import importlib.util
import os
import sys
import traceback


CHAIN_LIMIT = 10
COMMAND_PREFIX = '!llm'
RECOGPT_RELPATH = '../../../files/mybin/lib/recogpt.py'
MAX_TELEGRAM_EDIT_TEXT = 4096
PRIVACY_FOOTNOTE = 'Privacy: recolic.net/s/privacy_s'


def _try_import_rel(relpath, module_name):
    path = os.path.join(os.path.dirname(__file__), relpath)
    if not os.path.exists(path):
        return None

    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        return None

    mod = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(mod)
    except Exception:
        print(f"[mod_gpt_assist] failed to import {path}", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        return None
    return mod


recogpt = _try_import_rel(RECOGPT_RELPATH, 'recogpt')


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


def _format_message_for_prompt(message):
    sender = 'me' if message.get('is_outgoing') else 'them'
    text = _message_text(message)
    if text is None:
        text = f"<{(message.get('content') or {}).get('@type', 'non-text message')}>"
    return f"{sender} (sender_id={_sender_id(message)}, msg_id={message.get('id')}): {text}"


def _strip_command(text):
    return text[len(COMMAND_PREFIX):].strip()


def _build_llm_prompt(buf):
    user_instruction = _strip_command(_message_text(buf[0]) or '')
    prior_context = list(reversed(buf[1:]))
    if prior_context:
        context_text = '\n'.join(_format_message_for_prompt(message) for message in prior_context)
    else:
        context_text = '(No earlier context was found.)'

    system_prompt = (
        "You are drafting a Telegram message for the account owner. "
        "The owner typed a message beginning with !llm; your output will replace that entire message. "
        "Use the provided conversation context and the owner's instruction to write only the final message text. "
        "Do not mention that you are an AI, do not include analysis, and do not quote the !llm command. "
        "Match the language, tone, and level of detail requested by the owner. "
        "If the context is insufficient, still produce the best useful reply without inventing private facts."
    )
    user_prompt = (
        "Conversation context, oldest to newest:\n"
        f"{context_text}\n\n"
        "Owner instruction from the !llm message:\n"
        f"{user_instruction or '(No extra instruction; respond appropriately to the context.)'}"
    )
    return recogpt.prompt_system(system_prompt) + recogpt.prompt_user(user_prompt)


def _telegram_safe_text(text):
    text = str(text).strip()
    if not text:
        return '[mod_gpt_assist] Empty AI response.'
    if len(text) <= MAX_TELEGRAM_EDIT_TEXT:
        return text
    suffix = '\n\n[truncated]'
    return text[:MAX_TELEGRAM_EDIT_TEXT - len(suffix)] + suffix


def _complete_from_context(buf):
    impl = recogpt.impl_load(recogpt.default_impl)
    return recogpt.complete(_build_llm_prompt(buf), impl)


def _edit_message_text(tg, chat_id, msg_id, text):
    return _wait_result(tg._send_data({
        '@type': 'editMessageText',
        'chat_id': chat_id,
        'message_id': msg_id,
        'input_message_content': {
            '@type': 'inputMessageText',
            'text': {
                '@type': 'formattedText',
                'text': text,
                'entities': [],
            },
        },
    }))


def handle_update(tg, update):
    if recogpt is None:
        return False

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

    try:
        response = _telegram_safe_text(_complete_from_context(buf) + f"\n{PRIVACY_FOOTNOTE}")
    except Exception as e:
        print('[mod_gpt_assist] LLM completion failed', file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        response = _telegram_safe_text(f"[mod_gpt_assist] LLM error: {type(e).__name__}: {e}")

    _edit_message_text(tg, message.get('chat_id'), message.get('id'), response)
    return False
