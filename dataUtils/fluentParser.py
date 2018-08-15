import pandas as pd
from pathlib import Path
import re

filename = Path('dataUtils/courantnumber_max-rfile.out')

def get_headers(file, headerline, regexstring, exclude):
    # Get string of selected headerline
    # with file.open() as f:
    f = file.open()
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

        
headernames = get_headers(filename, 3, r'(?:" ")|["\)\(]', ['\n'])

test = pd.read_table(filename, sep=' ', skiprows=3, names=headernames)
