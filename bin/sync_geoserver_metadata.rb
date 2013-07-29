#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# RGeoServer Batch load layers (batch_demo.rb)
# Usage: #{File.basename(__FILE__)} [input.yml]
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'uri'
require 'yaml'

require 'druid-tools'
require 'mods'

ENV['RGEOSERVER_CONFIG'] ||= ENV_FILE + '_rgeoserver.yml'
require 'rgeoserver'

def do_vector(catalog, layername, format, ws, ds, v, flags)
  # Create data stores for shapefiles
  ds = RGeoServer::DataStore.new catalog, :workspace => ws, :name => (ds.nil?? v['druid'].id : ds)
  puts "DataStore: #{ws.name}/#{ds.name} (#{v['remote']})" if flags[:verbose]
  ap({:profile => ds.profile}) if flags[:debug]
  raise ArgumentError, "Datastore #{ds.name} not found" if ds.new?
  
  ap({:catalog => catalog, :workspace => ws, :data_store => ds, :name => layername})
  ft = RGeoServer::FeatureType.new catalog, :workspace => ws, :data_store => ds, :name => layername 
  ap({:profile => ft.profile}) if flags[:debug]
  if ft.new?
    puts "WARNING: #{layername} not found, searching for #{v['druid'].id}"
    ft = RGeoServer::FeatureType.new catalog, :workspace => ws, :data_store => ds, :name => v['druid'].id 
  end
  raise "FeatureType is missing #{ft.name}" if ft.new?
  puts "FeatureType: #{ft.route}" if flags[:verbose]
  ft.enabled = 'true'
  ft.title = v['title'] 
  ft.description = v['description']
  ft.keywords = v['keywords']
  ft.metadata_links = v['metadata_links']
  ap({:profile => ft.profile}) if flags[:debug]
  ft.save
end

def do_raster(catalog, layername, format, ws, v, flags)
  raise NotImplemented
end

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

def main catalog, ws, layers, flags = {}
  raise ArgumentError, "Layer is malformed" unless not layers.nil? and layers.is_a? Hash and not layers.empty?

  # Iterate over all records in YAML file and create stores in the catalog
  layers.each do |k, v|
    ['layername', 'format', 'filename', 'title'].each do |i|
      raise ArgumentError, "Layer is missing #{i}" unless v.include?(i) and v[i] != nil
    end
    puts "Processing layer #{k}" if flags[:verbose]

    layername = v['layername'].strip
    format = v['format'].strip
    
    case format
    when 'GeoTIFF'
      do_raster catalog, layername, format, ws, v, flags
    when 'Shapefile'
      do_vector catalog, layername, format, ws, flags[:datastore], v, flags
    else
      raise NotImplementedError, "Unsupported format #{format}"    
    end
  end
end

def from_druid druid, flags
  prj = flags[:projection] || "EPSG:4326"
  prj = prj.split(':').join('_')
  druid = DruidTools::Druid.new(druid, flags[:datadir])
  mods_fn = druid.path('metadata/descMetadata.xml')
  puts "Loading #{mods_fn}" if flags[:verbose]
  mods = Mods::Record.new
  mods.from_url(mods_fn)
  zipfn = nil
  layername = nil
  Dir.glob(druid.content_dir + "/*_#{prj}.zip") do |fn|
    puts "Found EPSG 4326 zip: #{fn}" if flags[:verbose]
    zipfn = fn
    layername = File.basename(zipfn, "_#{prj}.zip")
    puts "Derived layername #{zipfn} -> #{layername}" if flags[:verbose]
  end
  if not zipfn
    Dir.glob(druid.content_dir + "/*.zip") do |fn|
      zipfn = fn
      layername = File.basename(zipfn, '.zip')
    end
  end
  raise ArgumentError, zipfn unless File.exist?(zipfn) and layername
  ap({:zipfn => zipfn, :layername => layername}) if flags[:verbose]
  r = { 
    'vector' => {
      'druid' => druid,
      'format' => 'Shapefile',
      'layername' => layername,
      'filename' => zipfn,
      'title' => mods.full_titles.first,
      'description' => mods.term_value(:abstract),
      'keywords' => [mods.term_value([:subject, 'topic']),
                     mods.term_value([:subject, 'geographic'])].flatten,
      'metadata_links' => [{
        'metadataType' => 'TC211',
        'content' => "http://purl.stanford.edu/#{druid.id}.geoMetadata"
      }]
    }
  }
  r
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => true,
    :datadir => '/var/geomdtk/current/workspace',
    :datastore => GeoMDTK::Config.geoserver.datastore || nil,
    :workspace => GeoMDTK::Config.geoserver.workspace || 'druid',
    :namespace => GeoMDTK::Config.geoserver.namespace || 'http://purl.stanford.edu'
  }
  
  OptionParser.new do |opts|
    opts.banner = "
Usage: #{File.basename(__FILE__)} [-v] [options] [druid ... | < druids]
           
    "
    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]})") do |v|
      raise ArgumentError, "Invalid directory #{v}" unless File.directory?(v)
      flags[:datadir] = v
    end
    opts.on("--workspace NAME", "Workspace on GeoServer (default: #{flags[:workspace]})") do |v|
      flags[:workspace] = v.to_s
    end
    opts.on("--datastore NAME", "Datastore on GeoServer in which data are loaded") do |v|
      flags[:datastore] = v.to_s
    end
  end.parse!
  
  ap({:flags => flags}) if flags[:debug]
  
  # init
  # Connect to the GeoServer catalog
  puts "Connecting to catalog..." if flags[:verbose]
  catalog = RGeoServer::catalog

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new catalog, :name => flags[:workspace]
  raise ArgumentError, "No such workspace #{flags[:workspace]}" if ws.new?
  puts "Workspace: #{ws.name} ready" if flags[:verbose]

  (ARGV.size > 0 ? ARGV : $stdin).each do |v|
    main(catalog, ws, from_druid(v, flags), flags)
  end
end
