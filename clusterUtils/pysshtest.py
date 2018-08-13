#!/usr/bin/env python3
import sys
import os
import pexpect
import subprocess

print("I'm in Python")
print(sys.version)

jobid = '3958731.pbs02' 


os.execv('/usr/bin/env', ['env', 'ssh', '-t', 'node0738', 'cd /tmp && exec bash -i'])
# subprocess.call(['/usr/bin/env', 'ssh', '-tt', 'node0738', 'cd /tmp && exec bash -i'])
# shell = pexpect.spawn('ssh -t node0738').interact()

