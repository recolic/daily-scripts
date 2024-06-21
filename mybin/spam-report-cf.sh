#!/bin/bash

eml="$1"
[ "$eml" = "" ] && echo "Usage: $0 path/to/export.eml" && exit 1

fname="phish-evidence-$RANDOM$RANDOM.eml"
mv "$1" "/tmp/$fname"

netpush "/tmp/$fname"

echo "
1 - Report Hosting Provider >>    https://abuse.cloudflare.com/phishing
>>>>>>>>>>>>>>>>>>
Recolic K

cloudflare@me.recolic.net

Software Engineer

[url]

EVERY SPAMMER & PHISHER ARE USING CLOUDFLARE!!!

EVERY SPAMMER & PHISHER ARE PROTECTED BY CLOUDFLARE!!!

EVERY SPAMMER & PHISHER ARE USING CLOUDFLARE!!!

EVERY SPAMMER & PHISHER ARE PROTECTED BY CLOUDFLARE!!!

Spammer is sending phishing email with cloudflare hosted url (see evidence URL). It contains fake website (which is phishing), and also violates Marketing laws in both federal marketing law and california law.

Evidence of email (original eml file) is also attached here: (sorry you dont allow uploading file, I have to use a link): https://recolic.net/tmp/$fname
>>>>>>>>>>>>>>>>>>
[ABUSE] Phishing website hosted with your IP address []

Spammer is sending phishing email with your VPS (see evidence URL). It contains fake website (which is phishing), and also violates Marketing laws in both federal marketing law and california law.

Evidence of email (original eml file) is also attached here: https://recolic.net/tmp/phish-evidence-1211918241.eml

Evidence URL: []

Evidence URL is hosting phishing website with your IP address: []
>>>>>>>>>>>>>>>>>>
"

echo "2 - Report sender IP >>    https://ipinfo.io"
grep 'Received: from' /tmp/$fname | grep -v 127.0.0.1
senderip=`grep 'Received: from' /tmp/$fname | grep -v 127.0.0.1 | grep -Eo '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+'`

echo "
>>>>>>>>>>>>>>>>>>
[ABUSE] Phishing email sent from your IP address $senderip
>>>>>>>>>>>>>>>>>>
Phishing email sent from your IP address $senderip. It contains fake website (which is phishing), and also violates Marketing laws in both federal marketing law and california law.

Evidence of phishing email attached at https://recolic.net/tmp/$fname.

PLEASE ban the fukking phisher.
>>>>>>>>>>>>>>>>>>
(attach file /tmp/$fname)
"

