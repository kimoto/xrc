#!/bin/env ruby
# encoding: utf-8
require 'socket'

loop do
  @server = TCPServer.open(9999)
  sock = @server.accept
  while line = sock.gets
    line.chomp!
    puts "received from irc client: #{sock}"
    sock.puts(":hipchat 1 Welcome!")

    line = sock.gets.chomp
    sock.puts(":hipchat 1 :Welcome!")
    sock.puts(":hipchat 376 :End of MOTD!")

    line = sock.gets.chomp
    p line
    line = sock.gets.chomp
    p line

    sock.puts(":kimoto!kimoto@lingr.com JOIN #1")
    p sock.gets
    sleep(30)
  end
  #c = Client.new(@server.accept, @backlog_count, @logger, @api_key)
  #Thread.new do
  #end
end
