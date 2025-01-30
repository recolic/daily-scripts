#!/usr/bin/python3
import smtplib
from email.mime.text import MIMEText
from email.utils import formatdate
import sys, ssl

receiver, subj, text = sys.argv[1:]

msg=MIMEText(text)
msg['Subject'] = subj
msg['From'] = 'no-reply@recolic.net'
msg['To'] = receiver
msg["Date"] = formatdate(localtime=True)

# s = smtplib.SMTP_SSL('smtp.recolic.org', 465)
s = smtplib.SMTP('smtp.recolic.org', 587)
s.starttls()

s.login('no-reply@recolic.net', '______________')

s.send_message(msg)
s.quit()


