import numpy
import torch

def words2vec(wordsList):
    # return python list with ints
    return [int(i) for i in wordsList if len(i) != 0]

def countdif(a, b):
    same, dif = 0, 0
    for ia, ib in zip(a[:2], b[:2]):
        if ia == ib:
            same += 1
        else:
            dif += 1
    for ia in a[2:]:
        found = False
        for ib in b[2:]:
            if ia == ib:
                found = True
                break
        if found:
            same += 1
        else:
            dif += 1
    return same, dif

class ProductData():
    def __init__(self, fname):
        self.dat = ProductData.load(fname)

    @staticmethod
    def load(fname):
        # every product is a python tuple: ([int()...], int(price), int(classID)).
        # return python list of products.
        # indexed by item ID.
        result = []
        with open(fname, 'r') as fd:
            lines = fd.read().split("\n")
        for line in lines:
            if line == '':
                continue
            ar = line.split("\t")
            if len(ar) != 6:
                raise ValueError('bad product data line:', line)
            fea = [int(ar[1]), int(ar[2])] + words2vec(ar[4].split(' '))
            result.append((fea, int(ar[5]), int(ar[3])))
        return result

    def __getitem__(self, key):
        return self.dat[key]
    
    def size(self):
        return len(self.dat)
    
    @staticmethod
    def distance(productA, productB):
        aid, apr, acls = productA
        bid, bpr, bcls = productB
        same, dif = countdif(aid, bid)
        if same == 0:
            same = 1e-3
        dist = dif / same

        if acls == bcls:
            dist *= 0.4
        else:
            dist *= 3
        
        dist *= (abs((apr - bpr) / ((apr + bpr) / 2)) + 1)
        return dist # usually about 0-10

class BehaviorData():
    def __init__(self, fname):
        self.dat = BehaviorData.load(fname) # sorted
    
    @staticmethod
    def load(fname):
        result = []
        with open(fname, 'r') as fd:
            lines = fd.read().split('\n')
        for line in lines:
            if line == '':
                continue
            ar = [int(i) for i in line.split("\t")]
            if len(ar) != 4:
                raise ValueError('bad bahave data:', line)
            result.append(ar)
        result.sort(key=lambda l: l[2]) # which day
        result.sort(key=lambda l: l[0])
        return result

    def getRawSequence(self):
        # Generator gives: [(behaveInfo4), ...]
        queue = []
        curruser = None
        for record in self.dat:
            if curruser != record[0]:
                if curruser != None:
                    yield queue
                curruser = record[0]
                queue = [record]
            else:
                queue.append(record)
        if len(queue) > 0:
            yield queue

    def getSequence(self):
        # add 'a day passed' as a new behavior, with behave_id(behave_info[3]) = 5.
        # new behavior data is like: [(user_id, product_id, day, behavior_type), ...]
        # time stamp is never useful but still contained.
        for rawseq in self.getRawSequence():
            hold = None
            newseq = []
            for item in rawseq:
                if item[2] != hold:
                    # day changed.
                    if hold == None:
                        hold = item[2]
                    else:
                        newseq.append[(item[0], -2, item[2], 5)]
                newseq.append(item)
            yield newseq
