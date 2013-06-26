#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

Dor::DigitalStacksService # force Net::SSH load

h = Dor::Config.stacks.host
u = Dor::Config.stacks.user
a = 'gssapi-with-mic'
puts "Connecting to #{u}@#{h} via #{a}"
Net::SSH.start(h, u, :auth_methods => [a]) do |ssh|
  puts ssh.exec!("/bin/echo test completed ok")
end
