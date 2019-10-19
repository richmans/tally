from tally import Tally
from time import sleep

"""
Script to quickly check if all lights are working correctly
Also, for situations where michael needs kit2000
"""
t = Tally()
up = True
i = 0
while True:
    if up:
        i = i+1
        if i > 2:
            up = False
    else:
        i = i-1
        if i < 1:
            up = True
    t.send_activation(i)
    sleep(0.8)
