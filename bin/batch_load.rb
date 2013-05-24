#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# RGeoServer Batch load layers (batch_demo.rb)
# Usage: #{File.basename(__FILE__)} [input.yml]

require 'rubygems'
require 'yaml'
require 'rgeoserver'
require 'awesome_print'
require 'optparse'

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
WORKSPACE_NAME = 'rgeoserver'
NAMESPACE = 'urn:rgeoserver'

# GeoWebCache configuration
SEED = true
SEED_OPTIONS = {
  :srs => {
    :number => 4326 
  },
  :zoomStart => 1,
  :zoomStop => 8,
  :format => 'image/png',
  :threadCount => 1
}

def main layers, flags = {}
  return unless layers
  datadir = flags[:datadir]
  # Connect to the GeoServer catalog
  cat = RGeoServer::Catalog.new

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new cat, :name => WORKSPACE_NAME
  ws.delete :recurse => true if flags[:delete] and not ws.new?
  ws.save if ws.new?

  # Iterate over all records in YAML file and create stores in the catalog
  layers.each do |k, v|
    ['layername', 'format', 'filename', 'title'].each do |id|
      raise ArgumentError, "Layer is missing #{id}" unless v.include?(id)
    end
    ap v

    layername = v['layername'].strip
    format = v['format'].strip

    ap "Layer: #{layername} #{format}"
    if format == 'GeoTIFF'
      # Create of a coverage store
      cs = RGeoServer::CoverageStore.new cat, :workspace => ws, :name => layername
      cs.url = File.join(datadir, v['filename'])
      cs.description = v['description'] 
      cs.enabled = 'true'
      cs.data_type = format
      cs.save

      # Now create the actual coverage
      cv = RGeoServer::Coverage.new cat, :workspace => ws, :coverage_store => cs, :name => layername 
      cv.title = v['title'] 
      cv.keywords = v['keywords']
      cv.metadata_links = v['metadata_links']
      cv.save

    elsif format == 'Shapefile'
      # Create data stores for shapefiles
      ds = RGeoServer::DataStore.new cat, :workspace => ws, :name => layername
      ds.description = v['description']
      ds.connection_parameters = {
        "url" => File.join(datadir, v['filename']),
        "namespace" => NAMESPACE
      }
      ds.enabled = 'true'
      ds.save

      ft = RGeoServer::FeatureType.new cat, :workspace => ws, :data_store => ds, :name => layername 
      ft.title = v['title'] 
      ft.abstract = v['description']
      ft.keywords = v['keywords']
      ft.metadata_links = v['metadata_links']
      ft.save
    end

    # Check if a layer has been created, extract some metadata
    lyr = RGeoServer::Layer.new cat, :name => layername
    if not lyr.new? and SEED
      lyr.seed :issue, SEED_OPTIONS
    else
      raise NotImplementedError, "Unsupported format #{format}"
    end
  end
end

begin
  flags = {
    :delete => true,
    :verbose => false,
    :datadir => 'file:///data'
  }
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename(__FILE__)} [-v] [--delete] [input.yml ...]"
    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      flags[:verbose] = v
    end
    opts.on(nil, "--[no-]delete", "Delete workspaces recursively") do |v|
      flags[:delete] = v
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: file:///data)") do |v|
      flags[:datadir] = v
    end
  end.parse!
  ap flags

  if ARGV.size > 0
    ARGV.each do |fn|
      main(YAML::load_file(fn), flags)
    end
  else
    main(YAML::load($stdin), flags)
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
