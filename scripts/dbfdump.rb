#!/usr/bin/env ruby
require 'dbf'
require 'awesome_print'

ARGV.each do |fn|
  f = DBF::Table.new(fn)
  f.each do |r|
    puts r.class
    r.keys.each do |k|
      ap k
    end
  end
end
