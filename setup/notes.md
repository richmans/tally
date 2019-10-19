# setup ESP nodes

You need:
* ESPlorer : https://esp8266.ru/esplorer/
* esptool.py : https://github.com/espressif/esptool

First, load the firmware into the esp:
`esptool.py --port /dev/cu.wchusbserial1410 write_flash --flash_mode qio 0 nodemcu_integer_master_20180930-1340.bin`

* open esplorer
* open the init.lua file (sensor or led)
* click 'Open'
* click 'Heap' a bunch of times. you should see this:
```
> =node.heap()
33960
```
* You can now load the code into the esp by clicking 'Save to esp' (lower left
  corner)

After a reboot, it will spin up a wireless network. The network name will
either begin with M423 or SetupGadget. Connect to it, then browse to
192.168.4.1 . You will see a web page where you can enter the wifi credentials
for your network. If all goes well, it will connect and the LED will turn
green!

# Configuring with the controller

See which nodes are active:

```
$ python3 tally.py find
Broadcasting command 1, tries 4
Waiting for responses
Found node 1B6796 on channel 2 at 172.16.1.203
Found node 1B57FE on channel 1 at 172.16.1.29
Found node 810578 on channel 0 at 172.16.1.201
Found node 155349 on channel 2 at 172.16.1.202
Found node C31B7 SENSOR at 172.16.1.28
```

Set node 155349 to channel 2

```
$ python3 tally.py channel -n 155349 -c 2
Broadcasting command 3
```

Simulate camera 3 (channel 2) live:
```
$ python3 tally.py activate -c 2
```
Note that if you send this command while the sensor node is also on,
it will override your signal in about 0.5 seconds.
