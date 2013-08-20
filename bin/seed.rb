#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'mods'
require 'druid-tools'

ENV['RGEOSERVER_CONFIG'] ||= ENV_FILE + '_rgeoserver.yml'
require 'rgeoserver'

#= Configuration constants

def do_layer catalog, layername, seed_opts, flags = {}
  # If the layer has been create, start the seeding process
  puts "Layer: #{layername}" if flags[:verbose]
  lyr = RGeoServer::Layer.new catalog, :name => layername
  if lyr.new?
    puts "WARNING: Layer does not exist: #{layername}"
  else
    puts "Layer: seeding #{layername}" if flags[:verbose]
    seed_opts.each do |c|
      puts "Layer: seeding #{layername} with #{c}" if flags[:debug]
      lyr.seed :issue, c
    end
  end
end

# __MAIN__
begin
  flags = {
    :verbose => false
  }
  
  OptionParser.new do |opts|
    opts.banner = "
Usage: #{File.basename(__FILE__)} [-v] all
       #{File.basename(__FILE__)} [-v] layer1 [layer2 .. layerN]
       
    "
    opts.on("-v", "--verbose", "Run verbosely") do 
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
  end.parse!
  
  raise ArgumentError, "Missing layernames" unless ARGV.size > 0
  
  seed_opts = []
  GeoMDTK::Config.geowebcache.seed.each do |k,v|
    ap({:k => k, :v => v}) if flags[:debug]
    raise ArgumentError, "Seed #{k} is missing parameters: #{v.keys}" unless [:gridSetId, :zoom]
    seed_opts << {
      :gridSetId => v.gridSetId.to_s,
      :zoomStart => v.zoom.gsub(%r{:\d$}, '').to_i,
      :zoomStop => v.zoom.gsub(%r{^\d:}, '').to_i,
      :tileFormat => v.tileFormat || 'image/png',
      :threadCount => (v.threadCount || '1').to_i
    }
  end
  ap({:seed_opts => seed_opts}) if flags[:verbose]
  
  # init
  # Connect to the GeoServer catalog
  catalog = RGeoServer::catalog

  if ARGV.first.upcase == 'ALL'
    catalog.each_layer {|l| do_layer(catalog, l, seed_opts, flags)}
  else
    ARGV.each {|l| do_layer(catalog, l, seed_opts, flags)}
  end

rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
