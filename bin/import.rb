#!/usr/bin/env ruby
require 'geomdtk'

ARGV.each do |fn|
  ofn = File.join('tmp', File.basename(fn).gsub(%r{\.shp\.xml$}, '_geoMetadata.xml'))
  ofn_fc = File.join('tmp', File.basename(fn).gsub(%r{\.shp\.xml$}, '_FeatureCatalog.xml'))
  GeoMDTK::Transform.from_arcgis fn, ofn, ofn_fc
end

