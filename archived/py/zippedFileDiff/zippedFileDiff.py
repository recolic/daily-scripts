#!/usr/bin/env python3
import zipfile, os, shutil
import sys
import hashlib
import functools

def __main():
    if len(sys.argv) < 3:
        print('Usage: ./this.py 1.zip 2.zip')
        exit(1)

    zipNames = sys.argv[1], sys.argv[2]

    def isunzipped(name):
        return os.path.isdir(name)
    def name2dest(name):
        return name + '_dir' if not isunzipped(name) else name
    def unzipF(name, dest):
        if isunzipped(name):
            print('[INFO] Not recognizing `{}` as zip.'.format(name))
            return
        try:
            os.mkdir(dest)
        except FileExistsError:
            shutil.rmtree(dest)
            os.mkdir(dest)
        with zipfile.ZipFile(name, 'r') as z:
            z.extractall(dest)

    [unzipF(name, name2dest(name)) for name in zipNames]

    def getHash(filename, block_size = 65536):
        obj=hashlib.sha256()
        with open(filename, 'rb') as f:
            for block in iter(lambda: f.read(block_size), b''):
                obj.update(block)
        return obj.hexdigest()
    def listInfo(dest):
        return [(fl, getHash(dest + '/' + fl)) for fl in os.listdir(dest)]

    leftList, rightList = [listInfo(name2dest(name)) for name in zipNames]
    [shutil.rmtree(name2dest(name)) if not isunzipped(name) else 0 for name in zipNames]

    def showList(listPrinted, listSearched):
        for (fl, _hash) in listPrinted:
            hit = functools.reduce(lambda a, b: a or b, map(lambda item: item[1] == _hash, listSearched))
            print('                           > ' if hit else '                    不重复 > ', end='')
            print(fl)


    print('In {} ----------------------'.format(zipNames[0]))
    showList(leftList, rightList)
    print('In {} ----------------------'.format(zipNames[1]))
    showList(rightList, leftList)

def windows_pywrapper(func, preventExit = False):
    import traceback
    def show_exception_and_exit(exc_type, exc_value, tb):
        traceback.print_exception(exc_type, exc_value, tb)
        input("Press any key to exit.")
        sys.exit(-1)
    import sys, os
    if os.name == 'nt':
        sys.excepthook = show_exception_and_exit
        os.system('color f0')

    func()
    if preventExit:
        input("Press any key to exit.")

windows_pywrapper(__main, True)
