#!/usr/bin/env ruby

=begin
# このスクリプトについて
実行方法: `ruby [このファイル]`
指定されたCSVファイル内に記載されているコンピュータを選択して，そのコンピュータに対してWake-on-LANのマジックパケットを送信します．
事前にbroadcast変数とcsv_file変数にブロードキャストアドレスと，CSVファイルのパスを入力する必要があります．
CSVファイルは次のようにヘッダーを飛ばすため，2行目からコンピュータ名とMACアドレスを入力してください．　
=end

broadcast = '192.168.0.255'
csv_file = './tmp/mac_address.csv'

require 'csv'
MAC = CSV.read(csv_file)
if MAC[1].nil?
    puts "\nCSVファイルにコンピュータ名とMACアドレスを記入してください。\n"
    exit(1);
end

puts ""
puts "-----------------"
puts "   Wake-on-LAN   "
puts "-----------------"
puts ""
puts "電源をつけたい機器の番号を入力してください。"

for i in 1..MAC.length-1 do
    puts "\t#{i}. #{MAC[i][0]}"
end

puts ""

print "> "

num = gets

while num.to_i <= 0 || MAC.length <= num.to_i || !(num =~ /^[0-9]+$/)
    puts "\n指定された番号を入力してください。"
    num = gets
end

mac = MAC[num.to_i][1]

require 'socket'

sock = UDPSocket.open()
sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
magic = (0xff.chr) * 6 + (mac.split(/:/).pack("H*H*H*H*H*H*")) * 16
sock.send(magic, 0, broadcast, 9)

puts "\n#{MAC[num.to_i][0]} にマジックパケットを送信しました。\n"
