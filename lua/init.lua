config_file="config.lua"

function init()
  print("Mark423 Tally system starting...")
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

function toggle_led() 
  if ledstate == gpio.LOW then
    ledstate = gpio.HIGH
  else
    ledstate = gpio.LOW
  end
  gpio.write(0, ledstate)
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
    message = node.chipid()
    s:send(port, ip, message)
  elseif command == 2 then
    toggle_led()
  end
end

init()
