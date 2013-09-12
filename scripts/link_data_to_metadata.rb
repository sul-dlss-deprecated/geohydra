#!/usr/bin/env ruby
require 'fileutils'
Dir.glob('/var/geomdtk/current/upload/data/ready/**/*.shp.xml') do |origfn|
  shpxml = File.basename(origfn)
	Dir.glob('/var/geomdtk/current/upload/metadata/current/**/' + shpxml) do |linkfn|
    puts [origfn, '->', linkfn].join(' ')
    FileUtils.ln_sf linkfn, origfn, :verbose => true
  end
end
