#!/bin/env python3

import torch
import numpy

import torch.nn as nn
import torch.nn.functional as nnf
from torch.autograd import Variable
from fuckio import ProductData, BehaviorData

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--load-model', dest='fmodel_to_load', 
                    type=str, 
                    help='Model file name to load. I`ll load model from this file rather than initialize a random one. And train it.')
parser.add_argument('--save-model', dest='fmodel_to_save', 
                    type=str, 
                    help='Model file name to save trained model in.'
parser.add_argument('--lr', dest='LearnRate', 
                    type=float, required=True, 
                    help='learn rate. e-3 to e-5 is usually ok.')

args = parser.parse_args()

products = ProductData('data/GoodProduct.txt')
behaves = BehaviorData('data/GoodBehavior.txt')

# Thanks to http://pytorch.org/tutorials/intermediate/char_rnn_classification_tutorial.html
class mmodel(nn.modules):
    def __init__(self):
        super(mmodel, self).__init__()
        self.hidden_size = 12
        self.input_size = 4
        
        #self.hiddenLinLayerA = nn.Linear(hidden_size + input_size, hidden_size + input_size)
        self.ConvedCombToHiddenLayer = nn.Linear(hidden_size + input_size, hidden_size)
        self.HiddenToOutput = nn.Linear(hidden_size, 1)

    
    def forward(self, input, hidden):
        combined = torch.cat((input, hidden))
        #o = self.hiddenLinLayerA(nnf.tanh(combined))
        o_hidden = self.ConvedCombToHiddenLayer(nnf.tanh(combined))
        o_predict = self.HiddenToOutput(nnf.sigmoid(o_hidden))
        return o_predict, o_hidden

    def firstHidden(self):
        return Variable(torch.randn(self.hidden_size))

    def CUDA_firstHidden(self):
        r = torch.randn(self.hidden_size)
        v = torch.cuda.FloatTensor(self.hidden_size)
        for i in range(self.hidden_size):
            v[i] = r[i]
        return Variable(v)

#load model
if args.fmodel_to_load != None:
    with open(args.fmodel_to_load, 'rb') as fd:
        m = torch.load(fd)
else:
    m = mmodel()

optimizer = torch.optim.SGD(m.parameters(), lr=args.LearnRate, momentum=0, dampening=0, weight_decay=0, nesterov=False)
#optimizer = torch.optim.RMSprop(m.parameters(), lr=args.LearnRate, alpha=0.99, eps=1e-08, weight_decay=0, momentum=0.75, centered=False)

for seq in behaves.getSequence():
    


