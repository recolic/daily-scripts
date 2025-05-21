# usage: python archived/py/listemail.py (genpasswd btest@recolic.net)
import imaplib
import email
from email.header import decode_header
import sys

IMAP_SERVER = "imap.recolic.net"
USERNAME = "btest@recolic.net"
PASSWORD = sys.argv[1]

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

# Get list of email IDs
email_ids = messages[0].split()

# Fetch and print subject lines
for eid in email_ids:
    status, msg_data = mail.fetch(eid, "(RFC822.HEADER)")
    if status != "OK":
        continue

    msg = email.message_from_bytes(msg_data[0][1])
    subject, encoding = decode_header(msg["Subject"])[0]
    if isinstance(subject, bytes):
        subject = subject.decode(encoding or "utf-8", errors="ignore")
    print(subject)

mail.logout()

