#!/usr/bin/env ruby
require 'fileutils'
Dir.glob('/var/geomdtk/current/stage/**/temp/*.shp.xml') do |shpxml_fn|
  puts "Processing #{shpxml_fn}..."
  k = File.basename(shpxml_fn, '.shp.xml')
  d = File.dirname(shpxml_fn)
  puts "Locating #{k} data..."
  Dir.glob('/var/geomdtk/current/upload/data/original/**/' + k + '.*') do |fn|
    if %w{shp shx dbf prj sbn sbx}.include? File.extname(fn).gsub(/^\./, '') # only copy core Shapefile files
      FileUtils.ln fn, d, :verbose => true
    end
  end
end
