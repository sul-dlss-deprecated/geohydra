#!/usr/bin/env ruby

require 'geohydra'
require 'json'

def doit(shp)
  r = {}
  r['druid'] = File.basename(File.dirname(File.dirname(shp)))
  raise ArgumentError unless GeoHydra::Utils.shapefile?(shp)
  r['geometryType'] = GeoHydra::Transform.geometry_type(shp)
  r['filename'] = File.basename(shp)
  File.open(File.join(File.dirname(shp), 'geoOptions.json'), 'w') do |f|
    f.puts r.to_json.to_s
  end
  
end

if ARGV.empty?
  Dir.glob('/var/geomdtk/current/stage/**/temp/*.shp') do |shp|
    doit(shp)
  end
else
  ARGV.each do |shp|
    doit(shp)
  end
  
end
