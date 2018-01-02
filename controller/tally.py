import argparse
import socket
import struct
import traceback
NODE_PORT=5004
def dbg(msg):
  print(msg)
  
class TallyNode:
  def __init__(self, ip):
    pass

class Tally:
  def __init__(self):
    self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM) 
    self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST,1)
    
  def find_nodes(self):
    message = b"\x01" 
    dbg("Broadcasting command 1")
    self.sock.sendto(message, ("<broadcast>", NODE_PORT))
    dbg("Waiting for responses")
    self.sock.settimeout(1)
    nodes = []
    try:
      while True:
        message, address= self.sock.recvfrom(1024)
        
        if message[0] != 4: 
          print("Malformed response {}".format(message[0]))
          continue
        node_id, channel = message[1:].decode().split(",")
        node_id = hex(int(node_id))[2:].upper()
        channel = int(channel)
        if channel == 255: 
          dbg("Found node " + node_id + " SENSOR at " + address[0])
        else:
          dbg("Found node " + node_id + " on channel " + str(channel) + " at " + address[0])
        nodes.append((node_id, address[0]))
    except Exception as e:
      pass
    return nodes

  def send_activation(self, channel):
    act = struct.pack("b", 1 << channel)
    message = b"\x02" + act
    dbg("Broadcasting command 2")
    self.sock.sendto(message, ("<broadcast>", NODE_PORT))

  def get_chans(self, chanstate):
    chans = []
    for i in range(8):
      if (2**i) & chanstate > 0:
        chans.append(i)
    return chans
    
  def listen(self):
    self.sock.bind(("0.0.0.0", NODE_PORT))
    while True:
      message, address= self.sock.recvfrom(1024)
      command = message[0]
      if command == 1:
        dbg("PING from " + address[0])
      elif command == 4:
        node_id, channel = message[1:].decode().split(",")
        node_id = hex(int(node_id))[2:].upper()
        channel = int(channel)
        if channel == 255: channel = "SENSOR"
        dbg("PONG from {}, id {}, channel {}".format(address[0], node_id, channel))
      elif command == 2:
        chanstate = ord(message[1:2])
        chans = self.get_chans(chanstate)
        chans = ",".join(map(lambda x: str(x), chans))
        dbg("ACTIVATE from {} channels {}".format(address[0], chans))

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Commands for the m423 tally system')
  subparsers = parser.add_subparsers(dest='command')
  find_parser = subparsers.add_parser("find")
  activation_parser = subparsers.add_parser("activate")
  listen_parser = subparsers.add_parser("listen")
  activation_parser.add_argument('-c', type=int, required=True)
  args = parser.parse_args()
  t = Tally()
  if args.command == "find":
    nodes = t.find_nodes()
  elif args.command == "activate":
    t.send_activation(args.c)
  elif args.command == "listen":
    t.listen()
  else:
    parser.print_usage()
