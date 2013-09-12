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
  ap({:vector => v}) if flags[:debug]
  case v['remote']
  when 'serverfile'
    puts "DataStore: Loading server-side file #{v['filename']}" if flags[:verbose]
    ds.upload_external v['filename']
  when 'localfile'
    puts "DataStore: Uploading local file #{v['filename']}" if flags[:verbose]
    ds.upload_file v['filename']
  when 'postgis-db'
    puts "DataStore: Connecting to PostGIS database #{flags[:host]}:#{flags[:port]}/#{flags[:database]}" if flags[:verbose]
    ds.data_type = 'PostGIS'
    ds.connection_parameters = ds.connection_parameters.merge({
      "Connection timeout" => 20,
      "port" => flags[:port],
      "dbtype" => 'postgis',
      "host" => flags[:host],
      "validate connections" => true,
      "encode functions" => false,
      "max connections" => 16,
      "database" => flags[:database],
      "namespace" => flags[:namespace],
      "schema" => flags[:schema],
      "Loose bbox" => true,
      "Expose primary keys" => false,
      "fetch size" => 1000,
      "Max open prepared statements" => 50,
      "preparedStatements" => false,
      "Estimated extends" => true,
      "user" => flags[:user],
      "min connections" => 4
    })
    ap({:connection_parameters => ds.connection_parameters}) if flags[:debug]
  else
    raise NotImplemented, "Unknown remote type: #{v['remote']}"
  end
  
  if v['remote'] =~ /file$/
    ds.connection_parameters = ds.connection_parameters.merge({
      "namespace" => flags[:namespace],
      "charset" => 'UTF-8',
      "create spatial index" => 'true',
      "cache and reuse memory maps" => 'true',
      "enable spatial index" => 'true',
      "filetype" => 'shapefile',
      "memory mapped buffer" => 'false'
    })
    ap({:connection_parameters => ds.connection_parameters}) if flags[:debug]
  end

  # modify DataStore with rest of parameters
  ds.enabled = 'true'
  ds.description = v['description']
  ds.save# unless v['remote'] =~ /-db$/
  
  ft = RGeoServer::FeatureType.new catalog, 
    :workspace => ws, 
    :data_store => ds, 
    :name => layername 
  puts "WARNING: FeatureType doesn't already exists #{ft}" if ft.new?
  puts "FeatureType: #{ws.name}/#{ds.name}/#{ft.name}" if flags[:verbose]
  ft.enabled = 'true'
  ft.title = v['title'] 
  ft.description = v['description']
  ft.keywords = v['keywords']
  ft.metadata_links = v['metadata_links']
  puts(ft.message) if flags[:debug]
  ft.save
end

def do_raster(catalog, layername, format, ws, v, flags)
  # Create of a coverage store
  puts "CoverageStore: #{ws.name}/#{layername} (#{format})" if flags[:verbose]
  cs = RGeoServer::CoverageStore.new catalog, :workspace => ws, :name => layername
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
  cv = RGeoServer::Coverage.new catalog, :workspace => ws, :coverage_store => cs, :name => layername 
  cv.enabled = 'true'
  cv.title = v['title'] 
  cv.keywords = v['keywords']
  cv.metadata_links = v['metadata_links']
  cv.save
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
      'remote' => flags[:remote],
      'format' => 'Shapefile',
      'layername' => layername,
      'filename' => zipfn,
      'title' => mods.full_titles.first,
      'description' => mods.term_value(:abstract),
      'keywords' => [mods.term_values([:subject, 'topic']),
                     mods.term_values([:subject, 'geographic'])].flatten,
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
    :delete => false,
    :verbose => true,
    :datadir => '/var/geohydra/current/workspace',
    :format => 'MODS',
    :remote => 'localfile',
    :datastore => GeoHydra::Config.geoserver.datastore || nil,
    :workspace => GeoHydra::Config.geoserver.workspace || 'druid',
    :namespace => GeoHydra::Config.geoserver.namespace || 'http://purl.stanford.edu'
    # :host => 'localhost',
    # :port => 5432,
    # :user => 'geostaff',
    # :database => 'geoserver',
    # :schema => 'druid'
  }
  
  OptionParser.new do |opts|
    opts.banner = "
Usage: #{File.basename(__FILE__)} [-v] [--delete] [-f MODS] [druid ... | < druids]
       #{File.basename(__FILE__)} [-v] [--delete] -f YAML [input.yaml ... | <input.yml]
           
    "
    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on("--delete", "Delete workspaces recursively") do |v|
      flags[:delete] = true
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]})") do |v|
      raise ArgumentError, "Invalid directory #{v}" unless File.directory?(v)
      flags[:datadir] = v
    end
    opts.on("-f FORMAT", "--format=FORMAT", "Input file format of MODS or YAML (default: #{flags[:format]})") do |v|
      raise ArgumentError, "Invalid format #{v}" unless ['YAML', 'MODS'].include?(v.upcase)
      flags[:format] = v.upcase
    end
    opts.on("--workspace NAME", "Workspace on GeoServer (default: #{flags[:workspace]})") do |v|
      flags[:workspace] = v.to_s
    end
    opts.on("--namespace NAME", "Namespace on GeoServer (default: #{flags[:namespace]})") do |v|
      flags[:namespace] = v.to_s
    end
    opts.on("--datastore NAME", "Datastore on GeoServer in which data are loaded") do |v|
      flags[:datastore] = v.to_s
    end
    opts.on("--remote NAME", "Remote action (default: #{flags[:remote]})") do |v|
      flags[:remote] = v.to_s
    end
    opts.on("--dburl URL", "Database URL") do |v|
      url = URI(v)
      raise ArgumentError, "Invalid database URL (#{v}) -- postgresql://u@h:p/db#s" unless url.scheme == 'postgresql'
      flags[:host] = url.host
      flags[:port] = url.port || flags[:port]
      flags[:database] = url.path.gsub(%r{^/}, '') || flags[:database]
      flags[:user] = url.user || flags[:user]
      flags[:schema] = url.fragment || flags[:schema]
      flags[:remote] = 'postgis-db'
      flags[:datastore] = 'postgis'
    end
  end.parse!
  
  ap({:flags => flags}) if flags[:debug]
  
  # init
  # Connect to the GeoServer catalog
  puts "Connecting to catalog..." if flags[:verbose]
  catalog = RGeoServer::catalog

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new catalog, :name => flags[:workspace]
  puts "Workspace: #{ws.name} new?=#{ws.new?}" if flags[:verbose]
  ws.delete :recurse => true if flags[:delete] and not ws.new?
  ws.enabled = 'true'
  ws.save
  puts "Workspace: #{ws.name} ready" if flags[:verbose]

  if ARGV.size > 0
    ARGV.each do |v|
      case flags[:format]
      when 'YAML' then
        main(catalog, ws, YAML::load_file(v), flags)
      when 'MODS' then
        main(catalog, ws, from_druid(v, flags), flags)
      end
    end
  else
    case flags[:format]
    when 'YAML' then
      main(catalog, ws, YAML::load($stdin), flags)
    when 'MODS' then
      $stdin.readlines.each do |line|
        main(catalog, ws, from_druid(line.strip, flags), flags)
      end
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
