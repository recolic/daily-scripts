import hashlib,os

fd=open('dat','r')
rstr=fd.read()
fd.close()

def getHash(str):
    obj=hashlib.md5(str.encode())
    return obj.hexdigest()

rarr=rstr.split("\n")
for r in rarr:
    if r == '':
        continue
    ar=r.split('|')
    id=ar[0]
    pswd=ar[1]
    #print('id=', id, 'pswd=', pswd)
    if pswd == getHash(id):
        print('Hit:', id)
    else:
        print('Miss:', id)
