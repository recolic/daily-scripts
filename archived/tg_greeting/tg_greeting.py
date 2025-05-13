from telethon import TelegramClient, events, sync
import schedule, time
import requests, base64

api_id = 2677777
api_hash = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
client = TelegramClient('session_name', api_id, api_hash)
client.start()

print('Successfully login as ', client.get_me().username)

def do_send(msg):
    success = False
    for dialog in client.get_dialogs():
        if dialog.name == 'river' or dialog.title == 'river':
            res = dialog.send_message(msg)
            success = True
    return success

def mail_alert_error(msg):
    print('Sending error mail: ', msg)
    encoded = base64.b64encode(bytes(msg, 'utf-8'))
    encoded_title = base64.b64encode(b'river-telegram-autogreet ERROR report')
    r = requests.get('https://recolic.net/api/email-notify.php?apiKey=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&recvaddr=root@recolic.net&b64Title=' + encoded_title + '&b64Content=' + encoded)
    print(r.status_code)
    print(r.content)

def fetch_word(fname, fallback_str):
    with open(fname) as f:
        ar = f.read().split('\n')
    if len(ar) == 1:
        mail_alert_error('Warning: {} have used all words. Please refill in 24hour!'.format(fname))
    result_txt = '\n'.join(ar[1:]) # it's ok to join empty array in python
    with open(fname, 'w+') as f:
        f.write(result_txt)

    word = ar[0]
    return fallback_str if word.strip() == '' else word

def job_night():
    if not do_send(fetch_word('night.list', 'Hey. Good night!')):
        mail_alert_error('night greet failed. No conversation named river')
    
def job_morning():
    if not do_send(fetch_word('morning.list', 'Hey. Good morning!')):
        mail_alert_error('morning greet failed. No conversation named river')

# # UTC+8
schedule.every().day.at("23:30").do(job_night)
schedule.every().day.at("07:30").do(job_morning)

# # UTC
# schedule.every().day.at("15:30").do(job_night)
# schedule.every().day.at("23:30").do(job_morning)

while True:
    schedule.run_pending()
    time.sleep(10)

