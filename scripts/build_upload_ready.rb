#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'druid-tools'

flags = {
  :base => '/var/geomdtk/current/upload',
  :include_iso19139 => true,
  :debug => true
}

def build(shp, druid, geometryType, flags)
  destdir = File.join(flags[:base], 'druid', druid.id)
  tempdir = File.join(destdir, 'temp')
  readydir = File.join(flags[:base], 'data', 'ready')
  basename = File.join(File.dirname(shp), File.basename(shp, '.shp'))
  
  %w{metadata content temp}.each do |d| 
    p = File.join(destdir, d)
    FileUtils.mkdir_p(p, :verbose => true) unless File.directory?(p)
  end
  Dir.glob("#{readydir}/**/#{basename}.*") do |fn|
    FileUtils.ln([File.expand_path(fn)], tempdir, :verbose => true)
  end
  File.open("#{tempdir}/options.json", "w") do |f|
    f.puts "{ \"druid\" : \"#{druid.id}\", \"geometryType\" : \"#{geometryType}\" }"
  end
end

CSV.foreach('Batch20130806.csv') do |row|
  shp = row[0].to_s.strip
  next if shp.empty? or shp == 'shapefile'
  druid = DruidTools::Druid.new(row[1].to_s.strip)
  geometryType = row[2].to_s.strip
  build shp, druid, geometryType, flags
end
