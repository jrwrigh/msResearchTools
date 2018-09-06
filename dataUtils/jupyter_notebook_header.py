import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path
import re

filename = Path('courantnumber_max-rfile.out')

def get_headers(file, headerline, regexstring, exclude):
    # Get string of selected headerline
    with file.open() as f:
        for i, line in enumerate(f):
            if i == headerline-1:
                headerstring = line
            elif i > headerline-1:
                break

    # Parse headerstring
    reglist = re.split(regexstring, headerstring)

    # Filter entries in reglist
        #filter out blank strs
    filteredlist = list(filter(None, reglist)) 

        #filter out items in exclude list
    headerslist = []
    if exclude:
        for entry in filteredlist:
            if not entry in exclude:
                headerslist.append(entry)
    return headerslist

def movingstats(series, interval):
    movingaverage = []
    movingstd = []
    for i in range(1,len(series)-interval):
        movingaverage.append(series[i:i+interval].mean())
        movingstd.append(series[i:i+interval].std())
    return (movingaverage, movingstd)

def extendingstats(series, startindex):
    extendaverage, extendstd = [], []
    for n in range(startindex+1, len(series)+1):
        extendaverage.append(series[startindex:n].mean())
        extendstd.append(series[startindex:n].std())
    return (extendaverage, extendstd)

headernames = get_headers(filename, 3, r'(?:" ")|["\)\(]', ['\n'])

data = pd.read_table(filename, sep=' ', skiprows=3, names=headernames)
data.head()