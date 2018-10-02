--
--        Mark423 TALLY LED
--
config_file="config.lua"
channel = 0
LED_RED=3 -- d3
LED_GREEN=2 -- d2
LED_BLUE=1 -- d1
LED_OFF = -1
green_duty=40
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
  for i,led in ipairs(leds) do
    if led == LED_GREEN then
        pwm.setup(LED_GREEN, 100, green_duty)
    else
        gpio.mode(led, gpio.OUTPUT)
    end
  end
  set_led_state(LED_BLUE)
end

function blink(temp_ledstate)
  old_ledstate = ledstate
  set_led_state(temp_ledstate)
  tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
    print(string.format("Resetting ledstate to %d", old_ledstate))
    if ledstate ~= old_ledstate then
      set_led_state(old_ledstate)
    end
  end)
end

function set_led_state(new_led_state)
  ledstate = new_led_state
  for i,led in ipairs(leds) do
    if led == ledstate then
      if led == LED_GREEN then
        pwm.start(LED_GREEN)
      else 
        gpio.write(led, gpio.HIGH)
      end
    else
      if led == LED_GREEN then
        pwm.stop(LED_GREEN)
      else 
        gpio.write(led, gpio.LOW)
      end
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
  print("Parsing packet")
  command = string.byte(data)
  if command == 1 then
    print("Command 1")
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
    print("Command 3")
    print(node.chipid())
    print(tonumber(string.sub(data,2,7),16))
    if node.chipid() == tonumber(string.sub(data,2,7),16) then
      print("Setting channelid")
      channel = tonumber(string.sub(data, -1))
      write_config()
      blink(LED_BLUE)
    end
  end
end

function read_config()
  local conf, err = loadfile(config_file)
  if conf then
    conf()
    print("Loaded config")
  else
    print("No config present")
  end
end

function write_config()
  file.open(config_file, "w")
  file.write(string.format("channel=%d", channel))
  file.close()
end
init()
