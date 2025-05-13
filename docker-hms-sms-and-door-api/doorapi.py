import time
import pytz
from datetime import datetime, timedelta
from smartrent import async_login
import asyncio
import os

HTTP_AUTH_TOKEN = 'SEC_PLACEHOLDER_HMSAPI_KEY'

def get_api():
    async def _wrapped():
        return await async_login('bensong.liu@microsoft.com', 'SEC_PLACEHOLDER_SMARTRENT_KEY')
    return asyncio.run(_wrapped())

def set_locked(lock_obj, true_or_false):
    async def _wrapped2(l, tf):
        return await l.async_set_locked(tf)
    return asyncio.run(_wrapped2(lock_obj, true_or_false))

alarm_muted_until = datetime.now(pytz.utc)

def mute_alarm_once():
    global alarm_muted_until
    now = datetime.now(pytz.utc)
    alarm_muted_until = now + timedelta(minutes=30)
    mute_log_message = f"{now.strftime('%Y-%m-%d %H:%M:%S')} UTC - Alarm muted for 30 minutes"
    print(mute_log_message)

def beep_until_muted():
    global alarm_muted_until
    while datetime.now(pytz.utc) > alarm_muted_until:
        os.system("echo -e '\a' > /dev/tty0")
        time.sleep(0.2)

def check_lock_status_and_beep():
    global alarm_muted_until

    now = datetime.now(pytz.utc)
    pst_now = now.astimezone(pytz.timezone("US/Pacific"))

    if pst_now.hour >= 0 and pst_now.hour < 8:
        locked = get_api().get_locks()[0].get_locked()
        print(f"{now.strftime('%Y-%m-%d %H:%M:%S')} UTC - Door lock status: {'locked' if locked else 'unlocked'}")
        if not locked:
            beep_until_muted()

# ====================== start http server =====================
from threading import Thread
import http.server, socketserver
import subprocess

class my_handler(http.server.BaseHTTPRequestHandler):
    def do_HEAD(self):
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.send_response(200)
    def do_GET(self):
        stat = [400, 'bad query']
        if HTTP_AUTH_TOKEN not in self.path:
            stat = [403, 'invalid auth token']
        else:
            if self.path.startswith('/mute'):
                mute_alarm_once()
                stat = [200, 'ok']
            elif self.path.startswith('/unlock'):
                set_locked(get_api().get_locks()[0], False)
                stat = [200, 'ok']
            elif self.path.startswith('/lock'):
                set_locked(get_api().get_locks()[0], True)
                stat = [200, 'ok']

        self.send_response(stat[0])
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(stat[1].encode('utf-8'))

def http_thread(arg):
    listen_port = 30802
    server = http.server.HTTPServer(('', listen_port), my_handler)
    print('Listening *:' + str(listen_port))
    server.serve_forever()

thread = Thread(target = http_thread, args = (0, ))
thread.start()
print("started http thread")
# ====================== end http server =====================

while True:
    try:
        check_lock_status_and_beep()
    except Exception as e:
        print("EXCEPTION in main: ", e)
        pass
    time.sleep(4)

