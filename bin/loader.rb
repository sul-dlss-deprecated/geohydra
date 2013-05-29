#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# RGeoServer Batch load layers (batch_demo.rb)
# Usage: #{File.basename(__FILE__)} [input.yml]
ENV['RGEOSERVER_CONFIG'] ||= 'config/environments/development_rgeoserver.yml'
require 'rubygems'
require 'yaml'
require 'rgeoserver'
require 'awesome_print'
require 'optparse'
require 'mods'
require 'druid-tools'

#=  Input data. *See DATA section at end of file*
# The input file is in YAML syntax with each record is a Hash with keys:
# - layername
# - filename
# - format
# - title
# and optionally
# - description
# - keywords
# - metadata_links

#= Configuration constants
WORKSPACE_NAME = 'druid'
NAMESPACE = 'http://purl.stanford.edu'

# GeoWebCache configuration
SEED = true
SEED_OPTIONS = {
  :srs => {
    :number => 4326 
  },
  :zoomStart => 1,
  :zoomStop => 10,
  :format => 'image/png',
  :threadCount => 1
}

def main layers, flags = {}
  return unless layers
  # Connect to the GeoServer catalog
  cat = RGeoServer::Catalog.new

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new cat, :name => WORKSPACE_NAME
  puts "Workspace: #{ws.name} new?=#{ws.new?}" if flags[:verbose]
  ws.delete :recurse => true if flags[:delete] and not ws.new?
  ws.enabled = 'true'
  ws.save
  

  # Iterate over all records in YAML file and create stores in the catalog
  layers.each do |k, v|
    ['layername', 'format', 'filename', 'title'].each do |i|
      raise ArgumentError, "Layer is missing #{i}" unless v.include?(i)
    end

    layername = v['layername'].strip
    format = v['format'].strip
    
    if format == 'GeoTIFF'
      # Create of a coverage store
      puts "CoverageStore: #{ws.name}/#{layername} (#{format})" if flags[:verbose]
      cs = RGeoServer::CoverageStore.new cat, :workspace => ws, :name => layername
      cs.url = "file://" + File.join(flags[:datadir], v['filename'])
      cs.description = v['description'] 
      cs.enabled = 'true'
      cs.data_type = format
      cs.save

      # Now create the actual coverage
      puts "Coverage: #{ws.name}/#{cs.name}/#{layername}" if flags[:verbose]
      cv = RGeoServer::Coverage.new cat, :workspace => ws, :coverage_store => cs, :name => layername 
      cv.enabled = 'true'
      cv.title = v['title'] 
      cv.keywords = v['keywords']
      cv.metadata_links = v['metadata_links']
      cv.save

    elsif format == 'Shapefile'
      # Create data stores for shapefiles
      puts "DataStore: #{ws.name}/#{layername} (#{format})" if flags[:verbose]
      ds = RGeoServer::DataStore.new cat, :workspace => ws, :name => layername
      ds.description = v['description']
      ds.connection_parameters = {
        "url" => "file://" + File.join(flags[:datadir], v['filename']),
        "namespace" => NAMESPACE
      }
      ds.enabled = 'true'
      ds.data_type = format
      ds.save

      puts "FeatureType: #{ws.name}/#{ds.name}/#{layername}" if flags[:verbose]
      ft = RGeoServer::FeatureType.new cat, :workspace => ws, :data_store => ds, :name => layername 
      ft.enabled = 'true'
      ft.title = v['title'] 
      ft.description = v['description']
      ft.keywords = v['keywords']
      ft.metadata_links = v['metadata_links']
      ft.save
    else
      raise NotImplementedError, "Unsupported format #{format}"    
    end

    # If the layer has been create, start the seeding process
    puts "Layer: #{layername}" if flags[:verbose]
    lyr = RGeoServer::Layer.new cat, :name => layername
    if not lyr.new? and SEED
      puts "Layer: seeding with #{SEED_OPTIONS}" if flags[:verbose]
      lyr.seed :issue, SEED_OPTIONS
    end
  end
end

# example_vector2:
#   layername: urban2050_ca
#   druid: cc111cc1111
#   format: Shapefile
#   title: "Projected Urban Growth scenarios for 2050"
#   description: "By 2020, most forecasters agree, California will be home to between 43 and 46 million residents-up from 35 million today. Beyond 2020 the size of Californias population is less certain."
#   keywords: ["vector", "urban", "landis", { 
#     keyword: "California", language: en, vocabulary: "ISOTC211/19115:place"}]
#   metadata_links: [{
#     metadataType: TC211, 
#     content: "http://purl.stanford.edu/cc111cc1111.iso19139.xml"}] 
#   metadata:
#     druid: cc111cc1111
#     publisher: Landis

# <identifier type="local" displayLabel="filename">OIL_GAS_FIELDS.shp</identifier>

def from_mods mods, flags
  ap s
  s = mods.xpath('//mods:identifier[@type="local" and @displayLabel="druid"]/text()',
                 'mods' => Mods::MODS_NS).first.to_s
  druid = DruidTools::Druid.new(s, flags[:datadir])
  ap druid
  puts "Extracting load parameters from #{druid.id}"
end

# __MAIN__
begin
  flags = {
    :delete => false,
    :verbose => true,
    :datadir => '/var/geomdtk/current/workspace',
    :format => 'YAML'
  }
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename(__FILE__)} [-v] [--delete] [input.yml ...]"
    opts.on("-v", "--[no-]verbose", "Run verbosely (default: #{flags[:verbose]})") do |v|
      flags[:verbose] = v
    end
    opts.on(nil, "--[no-]delete", "Delete workspaces recursively (default: #{flags[:delete]})") do |v|
      flags[:delete] = v
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]}") do |v|
      flags[:datadir] = v
    end
    opts.on("-f FORMAT", "--format=FORMAT", "Input file format of YAML or MODS (default: #{flags[:format]})") do |v|
      raise ArgumentError, "Invalid format #{v}" unless ['YAML', 'MODS'].include?(v.upcase)
      flags[:format] = v.upcase
    end
  end.parse!

  if ARGV.size > 0
    ARGV.each do |fn|
      case flags[:format]
      when 'YAML' then
        main(YAML::load_file(fn), flags)
      when 'MODS' then
        main(from_mods(Mods::Record.new.from_url(fn), flags), flags)
      end
    end
  else
    case flags[:format]
    when 'YAML' then
      main(YAML::load($stdin), flags)
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
