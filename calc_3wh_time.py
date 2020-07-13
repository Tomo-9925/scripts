#!/usr/bin/env python3

'''
# このスクリプトについて
実行方法: `python3 [このファイル] [pcapファイルのパス] [ターゲットのIPアドレス]`
指定したIPアドレスから始まった3ウェイハンドシェイクのかかった時間（ms）を計算し出力します．
最後に出力した時間をもとに平均を計算します．
'''

import os
import sys
from ipaddress import ip_address
from scapy.all import *
from pprint import pprint  # デバッグ用

args = sys.argv
pcap_file = args[1]
target_ip = args[2]

# 引数の内容を確認
if not os.path.isfile(pcap_file):
  sys.stderr.write('error: File not found')
  sys.exit(1)
try:
  ip_address(target_ip)
except:
  sys.stderr.write('error: Invalid IP address')
  sys.exit(1)

# パケットから検知した3ウェイハンドシェイクの情報を格納する配列
connections = []
'''
# なんとなくわかる connectionsに格納される情報
connections = [
  {
    SYN: {
      Time: Decimal（Unix時間）,
      Seq: Integer,
      Ack: Integer
    },
    SYN/ACK: SYNと同様（あれば）,
    ACK: SYNと同様（あれば）
  },
  ︙
]
'''

# 再送されたパケットかどうかを真偽値で返す
def retransmission(flag, seq):
  for connection in connections:
    if flag in connection:
      if seq == connection[flag]['Seq']:
        return True
  return False

# コネクションを検索し，該当するコネクションの配列番号を返す
def search_connection(flag, ack):
  seq = ack - 1
  if flag == 'SYN/ACK':
    for i in reversed(range(len(connections))):
      if connections[i]['SYN']['Seq'] == seq:
        return i
  elif flag == 'ACK':
    for i in reversed(range(len(connections))):
      if 'SYN/ACK' in connections[i]:
        if connections[i]['SYN/ACK']['Seq'] == seq:
          return i
  return None

# パケットから必要な情報を連想配列として取得して返す
def get_info(packet):
  data = {}
  data['Time'] = packet.time  # SYN/ACKのTimeは今回は使用しない
  data['Seq'] = packet['TCP'].seq
  data['Ack'] = packet['TCP'].ack
  return data

# # pcapファイルをメモリ内に展開（メモリの大量消費）
# packets = rdpcap(pcap_file)

# パケットの情報を取得（メイン処理）
with PcapReader(pcap_file) as packets:
  for packet in packets:
    # パケットにTCPが含まれている場合
    if 'TCP' in packet:
      # パケットの送信元がTargetのとき
      if packet['IP'].src == target_ip:
        # パケットがSYNパケットのとき
        if packet['TCP'].flags == 'S' or packet['TCP'].flags == 'SEC':
          # 再送されたSYNパケットのときは無視する
          if retransmission('SYN', packet['TCP'].seq):
            continue  # Pythonはnextじゃない（戒め）
          connections.append({'SYN': get_info(packet)})  # パケットの情報を保存する
        # パケットがACKパケットのとき
        elif packet['TCP'].flags == 'A':
          # 再送されたACKパケットのときは上書きする
          index = search_connection('ACK', packet['TCP'].ack)
          # SYNパケットの記録が無かったとき
          if index is None:
            continue
          connections[index]['ACK'] = get_info(packet)
      # パケットの送信先がTargetのとき
      elif packet['IP'].dst == target_ip:
        # パケットがSYN/ACKパケットのとき
        if packet['TCP'].flags == 'SA' or packet['TCP'].flags == 'SAE':
          if retransmission('SYN/ACK', packet['TCP'].seq):
            continue
          index = search_connection('SYN/ACK', packet['TCP'].ack)
          if index is None:
            continue
          connections[index]['SYN/ACK'] = get_info(packet)

# 3ウェイハンドシェイクにかかった時間を格納する配列
result = []

# 3ウェイハンドシェイクが完了するまでの時間を出力
for connection in connections:
  if 'SYN' in connection and 'ACK' in connection:
    time = (connection['ACK']['Time'] - connection['SYN']['Time']) * 1000
    print(time)
    result.append(time)

# 3ウェイハンドシェイクが1度も成功していなかった場合
if not result:
  sys.stderr.write('error: 3way handshake not found')
  sys.exit(1)

# 平均の出力
print('avg: ' + str(sum(result)/len(result)))

# pprint(connections)  # デバッグ用