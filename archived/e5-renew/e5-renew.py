#!/usr/bin/python3 -u

import requests as req
import json,sys,time,random,os
#先注册azure应用,确保应用有以下权限:
#files:	Files.Read.All、Files.ReadWrite.All、Sites.Read.All、Sites.ReadWrite.All
#user:	User.Read.All、User.ReadWrite.All、Directory.Read.All、Directory.ReadWrite.All
#mail:  Mail.Read、Mail.ReadWrite、MailboxSettings.Read、MailboxSettings.ReadWrite
#注册后一定要再点代表xxx授予管理员同意,否则outlook api无法调用

###################################################################
#在下方单引号内填入应用id                                         #
id='xxxxxxxxxxxxx'
#在下方单引号内填入应用秘钥                                       #
secret=r'xxxxxxxxxxxxx'
###################################################################

rtoken_path = sys.path[0] + os.sep + 'rtoken.txt'
success_count = 0

def gettoken(refresh_token):
    headers={'Content-Type':'application/x-www-form-urlencoded'}
    data={
        'grant_type': 'refresh_token',
        'refresh_token': refresh_token,
        'client_id':id,
        'client_secret':secret,
        'redirect_uri':'http://localhost:53682/'
    }
    html = req.post('https://login.microsoftonline.com/common/oauth2/v2.0/token',data=data,headers=headers)
    jsontxt = json.loads(html.text)
    refresh_token = jsontxt['refresh_token']
    access_token = jsontxt['access_token']
    with open(rtoken_path, 'w+') as f:
        f.write(refresh_token)
    return access_token
def iterate_apis():
    global success_count
    with open(rtoken_path, "r+") as f:
        refresh_token = f.read()
    access_token=gettoken(refresh_token)
    headers={
        'Authorization':access_token,
        'Content-Type':'application/json'
    }
    endpoints = [
        'https://graph.microsoft.com/v1.0/me/drive/root',
        'https://graph.microsoft.com/v1.0/me/drive',
        'https://graph.microsoft.com/v1.0/users',
        'https://graph.microsoft.com/v1.0/me/messages',
        'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messageRules',
        'https://graph.microsoft.com/v1.0/me/drive/root/children',
        'https://api.powerbi.com/v1.0/myorg/apps',
        'https://graph.microsoft.com/v1.0/me/mailFolders',
        'https://graph.microsoft.com/v1.0/me/outlook/masterCategories'
    ]
    for endpoint in endpoints:
        try:
            if req.get(endpoint, headers=headers).status_code == 200:
                success_count += 1
                print('[API_SUCCESS] count={}, endpoint={}'.format(success_count, endpoint))
        except:
            print("Exception caught at endpoint:", endpoint)

# Main
while True:
    iterate_apis()
    sleep_time = random.randint(150,300)
    print('Sleeping for {} seconds...'.format(sleep_time))
    time.sleep(sleep_time)

