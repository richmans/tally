--
--        Mark423 TALLY LED
--
config_file="config.lua"
channel = 0
LED_RED=0
LED_GREEN=1
LED_BLUE=2
LED_OFF = -1
leds = { LED_RED, LED_GREEN, LED_BLUE }
function init()
  print("Mark423 Tally system starting...")
   if m423_running == true then
    print("M423 is already running, aborting. Reboot the node to run updated software")
    return
  end
  m423_running = true
  read_config()
  init_leds()
  wifi_setup()
end

function init_leds()
  for led in leds do
    gpio.mode(led, gpio.OUTPUT)
  end
  set_led_state(LED_BLUE)
end

function blink(temp_ledstate)
  old_ledstate = ledstate
  set_led_state(temp_ledstate)
  tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
    if ledstate == old_ledstate then
      set_led_state(old_ledstate)
    end
  end
end

function set_led_state(new_led_state)
  ledstate = new_led_state
  for led in leds do
    if led == ledstate then
      gpio.write(led, gpio.HIGH)
    else
      gpio.write(led, gpio.LOW)
    end
  end
end

function wifi_setup()
  print("Starting wifi setup")
  enduser_setup.start(
    function()
      --print("Connected to wifi as:" .. wifi.sta.getip())
      local sta_config = wifi.sta.getconfig(true)
      sta_config.save = true
      sta_config.got_ip_cb=udp_listen
      wifi.sta.config(sta_config)
    end,
    function(err, str)
      print("enduser_setup: Err #" .. err .. ": " .. str)
    end,
    print -- Lua print function can serve as the debug callback
  );
end

function udp_listen()
  udpSocket = net.createUDPSocket()
  udpSocket:listen(5004, wifi.sta.getip())
  udpSocket:on("receive", parse_packet)
  port, ip = udpSocket:getaddr()
  print(string.format("local UDP socket address / port: %s:%d", ip, port))
  set_led_state(LED_GREEN)
end

function parse_packet(s, data, port, ip)
  command = string.byte(data)
  if command == 1 then
    message = string.format(string.char(4) .. "%s,%d", node.chipid(), channel)
    s:send(port, ip, message)
  elseif command == 2 then
    input = string.byte(data, 2)
    mask = bit.bit(channel)
    if bit.band(mask, input) > 0 then
      set_led_state(LED_RED)
      --print("LED on!")
    else
      set_led_state(LED_GREEN)
      --print("LED off!")
    end
  elseif command == 3 then
    if node.chipid() == string.sub(message,2,7)
      channel = tonumber(string.sub(message, -1))
      blink(LED_BLUE)
    end
  end
end

function read_config()
  dofile(config_file)
end

function write_config()
  file.open(config_file, "w")
  file.write(string.format("channel=%d", channel))
  file.close()
end
init()
