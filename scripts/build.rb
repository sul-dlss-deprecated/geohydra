#!/usr/bin/env ruby

require 'csv'
require 'fileutils'

BASE = '/var/geomdtk/current/upload'
DST = File.join(BASE, 'druid')

def build(druid, name)
  dp = File.join(DST, druid)
  %w{metadata content temp}.each do |d| 
    subd = File.join(dp, d)
    FileUtils.mkdir_p(subd, :verbose => true) unless File.directory?(subd)
  end
  p = File.join(BASE, 'data', 'ready')
  Dir.glob("#{p}/**/#{name}.*") do |fn|
    FileUtils.ln_s([File.expand_path(fn)], File.join(dp, 'temp'), :verbose => true)
  end
  p = File.join(BASE, 'data', 'ready')
  Dir.glob("#{p}/**/#{name}-iso19139*.xml") do |fn|
    FileUtils.ln_s([File.expand_path(fn)], File.join(dp, 'temp'), :verbose => true)
  end
  system("zip -9jv #{dp}/content/#{name}.zip #{dp}/temp/#{name}*")
end

Dir.glob("#{BASE}/data/ready/**/*-iso19139.xml") do |fn|
  puts "<#{fn}>" if $DEBUG
  IO.popen("xsltproc #{File.dirname(__FILE__)}/extract.xsl #{fn}") do |i|
    puts "<#{i}>" if $DEBUG
    i.each do |line|
      CSV.parse(line.to_s) do |row|
        druid = row[0].to_s.strip
        name = row[1].to_s.strip
        build druid, name unless druid.empty?
      end
    end
  end
end
