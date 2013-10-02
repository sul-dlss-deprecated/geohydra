#!/usr/bin/env ruby

require 'json'

mods = {}
Dir.glob('/Volumes/Geo3TB/document_cache/??/???/??/????/mods') do |fn|
  puts fn
  if fn =~ %r{(../\d\d\d/../\d\d\d\d)/mods$}
    druid = $1.gsub(/\//, '')
  else 
    raise ArgumentError, fn
  end
  mods[druid] = File.read(fn)
end
JSON.dump(mods, File.open('mods.json', 'w'))
puts 'Wrote output to mods.json'
# mods = nil
# mods = JSON.parse(File.read('mods.json'))
# puts "Loaded #{mods.size}"