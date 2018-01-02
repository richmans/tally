--
--        Mark423 TALLY LED
--
config_file="config.lua"
channel = 0

function init()
  print("Mark423 Tally system starting...")
   if m423_running == true then
    print("M423 is already running, aborting. Reboot the node to run updated software")
    return
  end
  m423_running = true
  read_config()
  init_led()
  wifi_setup()
end

function init_led()
  ledstate = gpio.LOW
  gpio.mode(0, gpio.OUTPUT)
end

function wifi_setup()
  print("Starting wifi setup")
  enduser_setup.start(
    function()
      print("Connected to wifi as:" .. wifi.sta.getip())
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
      ledstate = gpio.HIGH
      print("LED on!")
    else
      ledstate = gpio.LOW
      print("LED off!")
    end
    gpio.write(0, ledstate)
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
