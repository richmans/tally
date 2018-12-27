import argparse
import socket
import struct
import traceback
import re
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
    brmessage = b"\x01"
    dbg("Broadcasting command 1, tries 4")
    self.sock.sendto(brmessage, ("<broadcast>", NODE_PORT))
    dbg("Waiting for responses")
    self.sock.settimeout(1)
    nodes = []
    tries = 3
    while True:
      try:
        message, address= self.sock.recvfrom(1024)
      except socket.timeout as e:
        if tries > 0:
          tries -= 1
          #dbg("Broadcasting command 1, tries {}".format(tries))
          self.sock.sendto(brmessage, ("<broadcast>", NODE_PORT))
          continue
        else:
          break

      if message[0] != 4:
        print("Malformed response {}".format(message[0]))
        continue
      node_id, channel = message[1:].decode().split(",")
      node_id = hex(int(node_id))[2:].upper()
      channel = int(channel)

      if (node_id, address[0]) in nodes:
        continue
      if channel == 255:
        dbg("Found node " + node_id + " SENSOR at " + address[0])
      else:
        dbg("Found node " + node_id + " on channel " + str(channel) + " at " + address[0])
      nodes.append((node_id, address[0]))

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

  def set_channel(self, node, channel):
    message = "\x03{},{}".format(node, channel)
    dbg("Broadcasting command 3")
    self.sock.sendto(message.encode(), ("<broadcast>", NODE_PORT))

  def set_duty(self, node, duties_str):
    duties = duties_str.split(",")
    if len(duties) != 3:
        print("Please provide duty cycles in the following format: 255,255,255")
        return
    duties = [int(c) for c in duties]
    duties = bytes(duties)
    message = "\x04{}".format(node).encode() +  duties
    dbg("Broadcasting command 4")
    self.sock.sendto(message, ("<broadcast>", NODE_PORT))

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
      elif command == 3:
        node_id, channel = message[1:].decode().split(",")
        dbg("PROGRAM for {} to channel {}".format(node_id, channel))

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Commands for the m423 tally system')
  subparsers = parser.add_subparsers(dest='command')
  find_parser = subparsers.add_parser("find")
  activation_parser = subparsers.add_parser("activate")
  listen_parser = subparsers.add_parser("listen")
  activation_parser.add_argument('-c', type=int, required=True)
  channel_parser = subparsers.add_parser("channel")
  channel_parser.add_argument('-c', type=int, required=True)
  channel_parser.add_argument('-n', type=str, required=True)
  duty_parser = subparsers.add_parser("duty")
  duty_parser.add_argument('-n', type=str, required=True)
  duty_parser.add_argument('-d', type=str, required=True)
  args = parser.parse_args()
  t = Tally()
  if args.command == "find":
    nodes = t.find_nodes()
  elif args.command == "activate":
    t.send_activation(args.c)
  elif args.command == "listen":
    t.listen()
  elif args.command == "channel":
    t.set_channel(args.n, args.c)
  elif args.command == "duty":
    t.set_duty(args.n, args.d)
  else:
    parser.print_usage()
