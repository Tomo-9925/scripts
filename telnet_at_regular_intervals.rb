#!/usr/bin/env ruby

=begin
# このスクリプトについて
実行方法: `ruby [このファイル]`
下記の設定を元にtelnetのセッションを作成し，指定したテキストを送信します
=end

require 'net/telnet'

# 設定（先頭文字を大文字化（定数化）するとエラー）
dst_ip = '192.168.190.2'  # 送信先のIPアドレス
dst_port = 80  # 送信先のポート
exp_num = 20  # 送信回数
timeout = 60  # タイムアウトの時間（s）
sleep_time = 5  # 送信間隔（s）
text = "GET / HTTP/1.1\nHost: #{dst_ip}\n\n"  # Telnetで送信するテキスト

threads = []
exp_num.times do |i|
  threads << Thread.start(i) do |j|  # スレッド作成
    idx = format('%02d', j+1)
    puts("#{idx}. Opening Telnet session")
    begin
      telnet = Net::Telnet.new('Host' => dst_ip, 'Port' => dst_port, 'Timeout' => timeout)
      puts("#{idx}. Established")
      telnet.cmd(text)
      puts("#{idx}. Sent text")
      telnet.close
      puts("#{idx}. Closing Telnet session")
    rescue => error  # 途中でエラーが出た場合，エラー内容を表示
      puts("#{idx}. #{error}")
    end
  end
  sleep sleep_time
end

threads.each do |thread|
  thread.join
end
