#!/usr/bin/env python3
# GPT 5.6 sol. list email, or print one email, for other script.

import argparse
import getpass
import imaplib
import ssl
import sys
from datetime import date, timedelta
from email.header import decode_header, make_header
from email.parser import BytesParser
from email.policy import default


def parse_args():
    parser = argparse.ArgumentParser(
        description="List subjects and raw body lengths for messages from the last month."
    )
    parser.add_argument("server", help="IMAP server address")
    parser.add_argument("username", help="IMAP username")
    parser.add_argument("--password", help="IMAP password (prompted if omitted)")
    parser.add_argument("--port", type=int, default=143, help="IMAP port (default: 143)")
    parser.add_argument("--mailbox", default="INBOX", help="Mailbox name (default: INBOX)")
    parser.add_argument("--days", type=int, default=30, help="number of recent days to search (default: 30)")
    parser.add_argument("--startswith", metavar="STRING", help="filter messages by subject prefix")
    parser.add_argument("--download-first", action="store_true", help="print the first filtered message body and exit")
    return parser.parse_args()


def extract_bytes(response):
    return b"".join(
        item[1] for item in response if isinstance(item, tuple) and isinstance(item[1], bytes)
    )


def decode_subject(header_bytes):
    message = BytesParser(policy=default).parsebytes(header_bytes, headersonly=True)
    subject = message.get("Subject")
    if subject is None:
        return "(no subject)"
    try:
        return str(make_header(decode_header(str(subject))))
    except (LookupError, UnicodeError):
        return str(subject)


def main():
    args = parse_args()
    password = args.password if args.password is not None else getpass.getpass("Password: ")
    since = (date.today() - timedelta(days=args.days)).strftime("%d-%b-%Y")

    client = imaplib.IMAP4(args.server, args.port)
    try:
        client.starttls(ssl_context=ssl.create_default_context())
        client.login(args.username, password)

        status, _ = client.select(args.mailbox, readonly=True)
        if status != "OK":
            raise RuntimeError(f"Could not select mailbox: {args.mailbox}")

        status, data = client.search(None, "SINCE", since)
        if status != "OK":
            raise RuntimeError("IMAP search failed")

        message_ids = data[0].split()
        for message_id in message_ids:
            status, header_data = client.fetch(
                message_id, "(BODY.PEEK[HEADER.FIELDS (SUBJECT)])"
            )
            if status != "OK":
                print(f"{message_id.decode()}: (failed to fetch subject)")
                continue

            subject = decode_subject(extract_bytes(header_data))
            if (
                args.startswith is not None
                and not subject.startswith(args.startswith)
            ):
                continue

            status, body_data = client.fetch(message_id, "(BODY.PEEK[TEXT])")
            if status != "OK":
                print(f"{message_id.decode()}: (failed to fetch body)")
                continue

            body = extract_bytes(body_data)
            if args.download_first:
                sys.stdout.buffer.write(body)
                return
            print(f"{message_id.decode()}\t{subject}\tlen={len(body)}")
    finally:
        try:
            client.logout()
        except imaplib.IMAP4.error:
            pass


if __name__ == "__main__":
    main()
