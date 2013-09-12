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

def do_vector(catalog, ws, ds, layername, format, v, flags)
  # Create data stores for shapefiles  
  name = v['druid'].id
  ft = RGeoServer::FeatureType.new catalog, :workspace => ws, :data_store => ds, :name => name
  ap({:catalog => catalog, :workspace => ws, :data_store => ds, :name => name, :layername => layername, :v => v})
  raise "FeatureType is missing #{ft.name}" if ft.new?
  puts "FeatureType: #{ft.route}" if flags[:verbose]
  ft.enabled = true
  ft.title = layername
  ft.abstract = '<h1>' + v['title'] + '</h1>' + "\n" + '<p>' + v['abstract'] + '</p>'
  ap({:abstract => ft.abstract})
  ft.keywords = [ft.keywords, v['keywords']].flatten.compact.uniq
  ft.metadata_links = v['metadata_links']
  ft.save
  ap({:profile => ft.profile}) if flags[:debug]
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
# - abstract
# - keywords
# - metadata_links

def main catalog, ws, layers, flags = {}
  raise ArgumentError, "Layer is malformed" unless not layers.nil? and layers.is_a? Hash and not layers.empty?
  ap({:ws => ws, :ds => flags[:datastore]}) if flags[:debug]

  ds = RGeoServer::DataStore.new catalog, :workspace => ws, :name => flags[:datastore]
  puts "DataStore: #{ws.name}/#{ds.name}" if flags[:verbose]
  ap({:profile => ds.profile}) if flags[:debug]
  raise ArgumentError, "Datastore #{ds.name} not found" if ds.new?

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
      do_vector catalog, ws, ds, layername, format, v, flags
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
  raise ArgumentError, "Cannot locate ZIP file: #{druid.content_dir} #{zipfn}" unless layername and not zipfn.nil? and File.exist?(zipfn)
  ap({:zipfn => zipfn, :layername => layername}) if flags[:verbose]
  r = { 
    'vector' => {
      'druid' => druid,
      'format' => 'Shapefile',
      'layername' => layername,
      'filename' => zipfn,
      'title' => mods.full_titles.first,
      'abstract' => mods.term_values(:abstract).compact.join("\n"),
      'keywords' => [mods.term_values([:subject, 'topic']),
                     mods.term_values([:subject, 'geographic'])].flatten.compact,
      'metadata_links' => [{
        'metadataType' => 'TC211',
        'content' => "http://purl.stanford.edu/#{druid.id}.geoMetadata"
      }]
    }
  }
  ap({:r => r}) if flags[:debug]
  r
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => true,
    :datadir => '/var/geohydra/current/workspace',
    :datastore => GeoHydra::Config.geoserver.datastore || 'postgis',
    :workspace => GeoHydra::Config.geoserver.workspace || 'druid',
    :namespace => GeoHydra::Config.geoserver.namespace || 'http://purl.stanford.edu'
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
  puts "Connected to #{catalog}" if flags[:verbose]

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new catalog, :name => flags[:workspace]
  raise ArgumentError, "No such workspace #{flags[:workspace]}" if ws.new?
  puts "Workspace: #{ws.name} ready" if flags[:verbose]

  (ARGV.size > 0 ? ARGV : $stdin).each do |v|
    main(catalog, ws, from_druid(v.downcase.strip, flags), flags)          
  end
end
