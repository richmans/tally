import argparse
import socket
import struct
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
        node_id, channel = message.decode().split(",")
        node_id = hex(int(node_id))[2:].upper()
        dbg("Found node " + node_id + " on channel " + channel + " at " + address[0])
        nodes.append((node_id.decode(), address[0]))
    except Exception as e:
      pass
    return nodes

  def send_activation(self, channel):
    act = struct.pack("b", 1 << channel)
    message = b"\x02" + act
    dbg("Broadcasting command 2")
    self.sock.sendto(message, ("<broadcast>", NODE_PORT))

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Commands for the m423 tally system')
  subparsers = parser.add_subparsers(dest='command')
  find_parser = subparsers.add_parser("find")
  activation_parser = subparsers.add_parser("activate")
  activation_parser.add_argument('-c', type=int, required=True)
  args = parser.parse_args()
  t = Tally()
  if args.command == "find":
    nodes = t.find_nodes()
  elif args.command == "activate":
    t.send_activation(args.c)
  else:
    parser.print_usage()
