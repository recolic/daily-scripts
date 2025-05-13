import time
import pytz
from datetime import datetime, timedelta
from smartrent import async_login
import asyncio
import os

def get_api():
    async def _wrapped():
        return await async_login('bensong.liu@microsoft.com', '_____________________________________________')
    return asyncio.run(_wrapped())

alarm_muted_until = None

def mute_alarm_once():
    alarm_muted_until = now + timedelta(minutes=30)
    mute_log_message = f"{pst_now.strftime('%Y-%m-%d %H:%M:%S')} PST - Alarm muted for 30 minutes"
    print(mute_log_message)

def beep_until_muted():


def check_lock_status_and_beep():
    global lock, alarm_muted_until

    now = datetime.now(pytz.utc)
    pst_now = now.astimezone(pytz.timezone("US/Pacific"))

    if pst_now.hour >= 0 and pst_now.hour < 8:
        locked = get_api().get_locks()[0].get_locked()
        print(f"{pst_now.strftime('%Y-%m-%d %H:%M:%S')} PST - Door lock status: {'locked' if locked else 'unlocked'}")
        if not locked:
            if alarm_muted_until is None or now > alarm_muted_until:
		while true:
                os.system("while true; do [[ -f /tmp/stop-alarm ]] && break || beep; done")
                if os.path.isfile("/tmp/stop-alarm"):
                    os.remove("/tmp/stop-alarm")
                    mute_alarm_once()

    time.sleep(2)

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
        self.send_response(200)
        if self.path.startswith('/trigger'):
            self.send_header("Content-type", "text/plain; charset=utf-8")
            self.end_headers()
            with open('/tmp/stop-alarm', 'w+') as f:
                f.write("1")
            self.wfile.write('ok'.encode('utf-8'))
            return
        self.send_response(403)
        self.send_header("Content-type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write('invalid get query.'.encode('utf-8'))

def http_thread(arg):
    listen_port = 30402
    server = http.server.HTTPServer(('', listen_port), my_handler)
    print('Listening *:' + str(listen_port))
    server.serve_forever()

thread = Thread(target = http_thread, args = (0, ))
thread.start()
print("started http thread")
# ====================== end http server =====================

while True:
    check_lock_status_and_beep()
    time.sleep(2)

