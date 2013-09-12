#!/usr/bin/env ruby
require 'uri'

h = 'kurma-podt1.stanford.edu'
ARGV.each do |druid|
  x = '20037508'
  url = URI("http://#{h}/geoserver/gwc/service/wms")
  url.query = URI.encode_www_form(
    'LAYERS' => "druid:#{druid}", 
    'FORMAT' => 'image/jpeg',
    'SERVICE' => 'WMS',
    'VERSION' => '1.1.1',
    'REQUEST' => 'GetMap',
    'STYLES' => '',
    'SRS' => 'EPSG:900913',
    'BBOX' => "-#{x},-#{x},#{x},#{x}",
    'WIDTH' => '256',
    'HEIGHT' => '256'
  )
  
  puts "curl -o '/tmp/#{druid}.jpg' '#{url}'"
end