#! /usr/bin/env ruby
=begin
# このスクリプトについて
実行方法については，`ruby [このファイル] --help`で確認してください．
とある大学のコンピュータのある棟に対してsshが可能であるかどうかを確認を行います．
実行にはsshpassというツールを使用するため，あまり使用しないほうが良いです．
=end

require 'optparse'
require 'open3'
require "io/console"

AVAILABLE = [201, 202, 203, 205, 301, 302, 303, 304, 305]

class Room
  def initialize(name)
    @name = name
    @network = get_network_num(name)
    @host = get_host_num(name)
    @status = Array.new(51, 0)
    @use = Array.new(51, false)
  end

  def set_info(id, password)
    @@id = id
    @@password = password
  end

  def ip(num)
    if num == 50 and @name/100 == 2
      "192.168." + @network.to_s + "." + "201"
    else
      if @network.instance_of?(Array)
        ips = []
        @network.each do |network|
          ips << "192.168." + network.to_s + "." + (@host+num).to_s
        end
        ips
      else
        "192.168." + @network.to_s + "." + (@host+num).to_s
      end
    end
  end

  def check_pc
    threads = []
    51.times do |i|
      threads << Thread.start(i) do |t|
        ping(t)
      end
    end
    threads.each do |thread|
      thread.join
    end
  end

  def check_user
    if @name == 301
      return nil
    end
    threads = []
    51.times do |i|
      if @status[i] != 0
        threads << Thread.start(i) do |t|
          who(t)
        end
      end
    end
    threads.each do |thread|
      thread.join
    end
  end

  def name
    @name
  end

  def count_pc
    51 - @status.count(0)
  end

  def count_users
    @use.count(true)
  end

  def pc_name(num)
    "tc#{(@name/100)*1000+(@name%100)*100+(num+1)}"
  end

  def available?(num)
    if @status[num] != 0
      true
    else
      false
    end
  end

  def use?(num)
    if @use[num] == true
      true
    else
      false
    end
  end

  private

  def get_network_num(room)
    if room == 301
      158
    elsif room/100 == 2
      150 + (room%100)
    elsif room/100 == 3
      [176, 177, 178]
    else
      abort "get_network_numメソッドを見直してください．"
    end
  end

  def get_host_num(room)
    if room == 301 or room/100 == 2
      101
    elsif room == 305
      201
    elsif room/100 == 3
      10 + (room%100-2) * 60 + 1
    else
      abort "get_host_numメソッドを見直してください．"
    end
  end

  def ping(num)
    tmp = ip(num)
    if tmp.instance_of?(Array)
      tmp.each_with_index do |ip, i|
        o, s = Open3.capture2("ping -c 1 -W 1 #{ip}")

        if s.exitstatus == 0
          @status[num] = 1 if i == 0
          @status[num] = 2 if i == 1
          @status[num] = 3 if i == 2
          break
        end
      end
    else
      o, s = Open3.capture2("ping -c 1 -W 1 #{tmp}")
      @status[num] = 1 if s.exitstatus == 0
    end
  end

  def who(num)
    tmp = ip(num)
    if tmp.instance_of?(Array)
      if @status[num] != 1
        o, e, s = Open3.capture3("sshpass -p #{@@password} ssh -o \"StrictHostKeyChecking no\" #{@@id + "@" + tmp[@status[num]-1]} \"who\"")

        @use[num] = true if o.include?("console")
      end
    else
      o, e, s = Open3.capture3("sshpass -p #{@@password} ssh -o \"StrictHostKeyChecking no\" #{@@id + "@" + tmp} \"who\"")
      @use[num] = true if o.include?("console")

    end
  end
end

option = {}
OptionParser.new do |opt|
  opt.on('-a', "すべての教室の情報を出力します．") {|v| option[:a] = v}
  opt.on('-p', "教室のコンピュータの起動数を出力します．") {|v| option[:p] = v}
  opt.on('-u', "教室のコンピュータのユーザ数を出力します．") {|v| option[:u] = v}
  opt.parse!(ARGV)
end

if ARGV.empty?
  if !option.has_key?(:a)

    abort "教室の番号を引数に入力するか，aオプションを使用してすべての教室情報を調べるようにしてください．"
  else
    if option.has_key?(:u)
      AVAILABLE.each do |num|
        ARGV << num
      end
    else
      AVAILABLE.each do |num|
        ARGV << num
      end
    end
  end
else
  if option.has_key?(:a)
    abort "教室の番号を入力したとき，aオプションは使用できません．"
  else
    for i in 0..ARGV.length-1
      begin
        ARGV[i] = ARGV[i].to_i
      rescue
        abort "引数には教室の番号を半角数字で入力してください．"
      end
      if !AVAILABLE.include?(ARGV[i])
        abort "存在しないか機能を使用できない教室の番号が指定されています．"
      end
    end
  end
end

if option.has_key?(:u)
  o, e, s = Open3.capture3("which sshpass")
  if s.exitstatus == 1
    abort "uオプションを使用するためにはsshpassが必要です．"
  else
    print "ID: "
    id = STDIN.gets.chomp
    print "Password: "
    password = STDIN.noecho(&:gets).chomp
    puts nil
  end
end

rooms = []
ARGV.each do |room|
  rooms << Room.new(room)
end
rooms[0].set_info(id, password) if option.has_key?(:u)

threads = []
rooms.each do |room|

  threads << Thread.start do
    room.check_pc
    room.check_user if option.has_key?(:u)
  end
end
threads.each do |thread|
  thread.join
end

rooms.each do |room|
  puts "TC#{room.name.to_s}:"
  if option.has_key?(:p) or option.has_key?(:u)
    if option.has_key?(:p)
      puts "  起動数: #{room.count_pc}"
      puts "  教員用のコンピュータが起動しています．" if room.available?(51-1)
    end
    if option.has_key?(:u)
      if room.name != 301
        puts "  ユーザ数: #{room.count_users}"
        puts "  教員用のコンピュータが使用されています．" if room.use?(51-1)
        puts "  ※ Windows以外のユーザのみカウントしています．" if room.name/100 == 3
      else
        puts "  TC#{room.name.to_s}ではユーザ数をカウントできません．"
      end
    end
  else
    puts "左から順にWindows，macOS，CentOSのIPアドレスです．" if room.name/100 == 3
    51.times do |i|
      puts "  #{room.pc_name(i)}: #{room.ip(i)}" if room.available?(i)
    end
  end
end
