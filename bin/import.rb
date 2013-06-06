#!/usr/bin/env ruby
require 'geomdtk'

ARGV.each do |fn|
  ofn = File.join('tmp', File.basename(fn).gsub(%r{\.shp\.xml$}, '_geoMetadata.xml'))
  GeoMDTK::Transform.from_arcgis fn, ofn
end

