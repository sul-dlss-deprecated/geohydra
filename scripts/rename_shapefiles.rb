#!/usr/bin/env ruby
#
Dir.glob('**/* *').each do |fn|
  puts "mv \"#{fn}\" \"#{fn.sub(' ', '_')}\""
end
