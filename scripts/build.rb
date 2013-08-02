#!/usr/bin/env ruby
require 'csv'

def build(druid, name)
end
base = '/var/geomdtk/current/upload'
Dir.glob('#{base}/metadata/current/**/*-iso19139.xml') do |fn|
  puts "<#{fn}>"
  IO.popen("xsltproc extract.xsl #{fn}") do |i|
    puts "<#{i}>"
    i.each do |line|
      CSV.parse(line.to_s) do |row|
        druid = row[0].to_s.strip
        name = row[1].to_s.strip
        build druid, name unless druid.empty?
			end
    end
  end
end
