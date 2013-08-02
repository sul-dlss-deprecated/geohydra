#!/usr/bin/env ruby
require 'csv'
require 'fileutils'

BASE = '/var/geomdtk/current/upload'
DST = '/var/geomdtk/current/upload/druid'
def build(druid, name)
  %w{metadata content temp}.each { |d| d = File.join(DST, druid, d); FileUtils.mkdir_p(d) unless File.directory?(d)}
  Dir.glob("#{BASE}/data/ready/**/#{name}.*") do |fn|
    system("ln -f #{fn} #{DST}/#{druid}/temp/")
  end
  Dir.glob("#{BASE}/metadata/current/**/#{name}-iso19139*.xml") do |fn|
    system("ln -f #{fn} #{DST}/#{druid}/temp/")
  end
end

Dir.glob("#{BASE}/metadata/current/**/*-iso19139.xml") do |fn|
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
