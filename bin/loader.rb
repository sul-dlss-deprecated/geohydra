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
SEED = false
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
  ap layers
  raise ArgumentError, "Layer is malformed" unless layers and layers.is_a? Hash
  
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
      raise ArgumentError, "Layer is missing #{i}" unless v.include?(i) and v[i] != nil
    end

    layername = v['layername'].strip
    format = v['format'].strip
    
    if format == 'GeoTIFF'
      # Create of a coverage store
      puts "CoverageStore: #{ws.name}/#{layername} (#{format})" if flags[:verbose]
      cs = RGeoServer::CoverageStore.new cat, :workspace => ws, :name => layername
      if v['filename'] =~ %r{^/}
        cs.url = "file://" + v['filename']
      else
        cs.url = "file://" + File.join(flags[:datadir], v['filename'])
      end
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
      ds.enabled = 'true'
      ds.data_type = format
      if v['remote']
        ds.description = v['description']
        ds.connection_parameters = {
          "namespace" => NAMESPACE,
          "charset" => 'UTF-8',
          "create spatial index" => 'true',
          "cache and reuse memory maps" => 'true',
          "enable spatial index" => 'true',
          "filetype" => 'shapefile',
          "memory mapped buffer" => 'false'
        }
        if v['filename'] =~ %r{^/}
          ds.connection_parameters['url'] = 'file:' + v['filename']
        else
          ds.connection_parameters['url'] = 'file:' + File.join(flags[:datadir], v['filename'])
        end
        ap ds.connection_parameters
        ds.save
      else
        ds.upload_file v['filename'], :title => v['title'], :description => v['description']
      end

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

def from_druid druid, flags
  prj = flags[:projection] || "EPSG:4326"
  druid = DruidTools::Druid.new(druid, flags[:datadir])
  ap druid
  mods_fn = druid.path('metadata/descMetadata.xml')
  puts "Extracting load parameters from #{druid.id} #{mods_fn}"
  mods = Mods::Record.new
  mods.from_url(mods_fn)
  # fn = Dir.glob(druid.content_dir + '/' + prj.gsub(':', '/') + '/*.shp').first
  fn = Dir.glob(druid.content_dir + '/' + prj.gsub(':', '/') + '/*.zip').first
  ap fn
  r = { 
    'vector' => {
      'remote' => false,
      'format' => 'Shapefile',
      'layername' => druid.id,
      'filename' => fn,
      'title' => mods.full_titles.first,
      'description' => mods.term_value(:abstract),
      'keywords' => [mods.term_value([:subject, 'topic']),
                     mods.term_value([:subject, 'geographic'])].flatten,
      'metadata_links' => [{
        'metadataType' => 'TC221',
        'content' => "http://purl.stanford.edu/#{druid.id}.iso19139.xml"
      }]
    }
  }
  ap r
  r
end

# __MAIN__
begin
  flags = {
    :delete => true,
    :verbose => true,
    :datadir => '/var/geomdtk/current/workspace',
    :format => 'MODS'
  }
  
  OptionParser.new do |opts|
    opts.banner = "
    Usage: #{File.basename(__FILE__)} -f MODS [-v] [--delete] druid [druid...]
           #{File.basename(__FILE__)} -f YAML [-v] [--delete] [input.yaml ...]
           
    "
    opts.on("-v", "--[no-]verbose", "Run verbosely (default: #{flags[:verbose]})") do |v|
      flags[:verbose] = v
    end
    opts.on(nil, "--[no-]delete", "Delete workspaces recursively (default: #{flags[:delete]})") do |v|
      flags[:delete] = v
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]}") do |v|
      flags[:datadir] = v
    end
    opts.on("-f FORMAT", "--format=FORMAT", "Input file format of MODS or YAML (default: #{flags[:format]})") do |v|
      raise ArgumentError, "Invalid format #{v}" unless ['YAML', 'MODS'].include?(v.upcase)
      flags[:format] = v.upcase
    end
  end.parse!

  if ARGV.size > 0
    ARGV.each do |v|
      case flags[:format]
      when 'YAML' then
        main(YAML::load_file(v), flags)
      when 'MODS' then
        main(from_druid(v, flags), flags)
      end
    end
  else
    case flags[:format]
    when 'YAML' then
      main(YAML::load($stdin), flags)
    when 'MODS' then
      $stdin.readlines.each do |line|
        main(from_druid(line.strip, flags), flags)
      end
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
