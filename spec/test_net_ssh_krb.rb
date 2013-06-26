#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

Dor::DigitalStacksService # force Net::SSH load

def doit h, u, p = '', a = 'gssapi-with-mic'
  puts "Connecting to #{u}@#{h} via #{a}"
  Net::SSH.start(h, u, :auth_methods => [a]) do |ssh|
    puts ssh.exec!("/bin/ls -aC #{p}")
  end
end

doit  Dor::Config.stacks.host, 
      Dor::Config.stacks.user,
      Dor::Config.stacks.storage_root
doit  Dor::Config.stacks.document_cache_host, 
      Dor::Config.stacks.document_cache_user, 
      Dor::Config.stacks.document_cache_storage_root
doit  Dor::Config.content.content_server, 
      Dor::Config.content.content_user, 
      Dor::Config.content.content_base_dir
