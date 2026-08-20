#!/usr/bin/env python3

# rice-water (gram) for AROMA ARC-743-1NG, https://recolic.net/res/cloudpaper/2211-rice-cooker.pdf
data="""
130 252
154 278
206 334
86 213
86 215
85 213
87 218
50 180
84 210"""
with open("/tmp/.rice.dat", "w+") as f:
    f.write(data)

import sys
sys.path.append('/usr/mymsbin/_graph_utils/draw/')
import quickmap

x1,y1 = quickmap.DataFileToXYArray('/tmp/.rice.dat')
quickmap.GetMap(x1,y1,polyLine=True)

