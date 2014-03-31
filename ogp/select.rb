#!/usr/bin/env ruby
#
# Usage: select.rb


require 'awesome_print'
require 'json'


# __MAIN__
selected = []
Dir.glob('transformed*.json') do |fn|
  JSON::parse(File.read(fn)).each do |i|
    if rand < 0.01
      selected << i
    end
  end
end
ap({:selected => selected})
File.open('selected.json', 'wb') {|f| f << JSON.pretty_generate(selected)}