# python archived/py/listemail2.py (genpasswd btest@recolic.net)
import imaplib
import email
import re
from email.header import decode_header
import sys

IMAP_SERVER = "imap.recolic.net"
USERNAME = "btest@recolic.net"
PASSWORD = sys.argv[1]
Search_Regex = r"<b>\$[0-9\.]*</b>"

# Connect and upgrade to TLS
mail = imaplib.IMAP4(IMAP_SERVER, 143)
mail.starttls()
mail.login(USERNAME, PASSWORD)

# Select inbox
mail.select("INBOX")

# Search all emails
status, messages = mail.search(None, "ALL")
if status != "OK":
    print("Failed to fetch emails")
    exit()

email_ids = messages[0].split()

for eid in email_ids:
    status, msg_data = mail.fetch(eid, "(RFC822)")
    if status != "OK":
        continue

    msg = email.message_from_bytes(msg_data[0][1])

    # Decode subject
    subject, encoding = decode_header(msg["Subject"])[0]
    if isinstance(subject, bytes):
        subject = subject.decode(encoding or "utf-8", errors="ignore")
    print(f"Subject: {subject}")

    # Extract body
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            if content_type == "text/html":
                try:
                    body = part.get_payload(decode=True).decode(part.get_content_charset() or "utf-8", errors="ignore")
                    break
                except:
                    continue
    else:
        if msg.get_content_type() == "text/html":
            body = msg.get_payload(decode=True).decode(msg.get_content_charset() or "utf-8", errors="ignore")

    # Regex matches
    matches = re.findall(Search_Regex, body)
    for m in matches:
        print(f"  Match: {m}")

mail.logout()

