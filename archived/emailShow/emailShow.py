import datetime
prev_call = datetime.datetime.now()
def timed_cache(func):
    def _wrapped():
        global prev_call
        if datetime.datetime.now() - prev_call > datetime.timedelta(seconds=3):
            prev_call = datetime.datetime.now()
            return func()
    return _wrapped
################################## BEGIN EMAIL LOGIC ###########################################
import time, base64
from itertools import chain
import email
import imaplib

#imap_ssl_host = 'imap.recolic.org'  # imap.mail.yahoo.com
#imap_ssl_port = 993
#username = 'baidu_public_1@recolic.org'
#password = 'dummy_pass'
imap_ssl_host = 'imap.sina.com'  # imap.mail.yahoo.com
imap_ssl_port = 993
username = 'iayrpklnkk22@sina.com'
password = 'dummy_pass'

# Restrict mail search. Be very specific.
# Machine should be very selective to receive messages.
criteria = {
    #'FROM':    'a@b.cc',
    #'SUBJECT': 'SPECIAL SUBJECT LINE',
    #'BODY':    'SECRET SIGNATURE',
}
uid_max = 0


def search_string(uid_max, criteria):
    c = list(map(lambda t: (t[0], '"'+str(t[1])+'"'), criteria.items())) + [('UID', '%d:*' % (uid_max+1))]
    return '(%s)' % ' '.join(chain(*c))
    # Produce search string in IMAP format:
    #   e.g. (FROM "me@gmail.com" SUBJECT "abcde" BODY "123456789" UID 9999:*)


def get_first_text_block(msg):
    _type = msg.get_content_maintype()
    if _type == 'multipart':
        for part in msg.get_payload():
            if part.get_content_maintype() == 'text':
                return part.get_payload()
    elif _type == 'text':
        return msg.get_payload()


server = imaplib.IMAP4_SSL(imap_ssl_host, imap_ssl_port)
server.login(username, password)
server.select('INBOX')
result, data = server.uid('search', None, search_string(uid_max, criteria))
uids = [int(s) for s in data[0].split()]
if uids:
    uid_max = max(uids)
    # Initialize `uid_max`. Any UID less than or equal to `uid_max` will be ignored subsequently.

server.logout()

allEmails = 'Messages since {} :<br />'.format(datetime.datetime.now())
@timed_cache
def checkEmail():
    global allEmails, uid_max
    # Have to login/logout each time because that's the only way to get fresh results.
    server = imaplib.IMAP4_SSL(imap_ssl_host, imap_ssl_port)
    server.login(username, password)
    server.select('INBOX')

    result, data = server.uid('search', None, search_string(uid_max, criteria))

    uids = [int(s) for s in data[0].split()]
    for uid in uids:
        # Have to check again because Gmail sometimes does not obey UID criterion.
        if uid > uid_max:
            result, data = server.uid('fetch', str(uid), '(RFC822)')  # fetch entire message
            msg = email.message_from_string(data[0][1].decode('utf-8'))
            uid_max = uid
            text = get_first_text_block(msg)
            text = '\n'.join([line for line in text.split('\n') if 'font-family' in line])
            #text = base64.b64decode(text).decode('utf-8')
            allEmails += '<p>TIME:{}, {}</p><br />'.format(datetime.datetime.now(), text)
            print('DEBUG: receiving: ', text)
    server.logout()

# Keep checking messages ...
# I don't like using IDLE because Yahoo does not support it.
#while True:
#    checkEmail()
#    print(allEmails)
#    sleep(5)

########################### HTTP BEGIN ######################################
#!/usr/bin/python
from http.server import BaseHTTPRequestHandler,HTTPServer

PORT_NUMBER = 8080

class myHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/html; charset=utf-8')
        self.end_headers()
        # Send the html message
        checkEmail()
        self.wfile.write(allEmails.encode('utf-8'))
        return

server = HTTPServer(('', PORT_NUMBER), myHandler)
print('Started httpserver on port ' , PORT_NUMBER)
server.serve_forever()

