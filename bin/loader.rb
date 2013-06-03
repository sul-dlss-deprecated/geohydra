#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# RGeoServer Batch load layers (batch_demo.rb)
# Usage: #{File.basename(__FILE__)} [input.yml]
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'mods'
require 'yaml'
require 'druid-tools'

ENV['RGEOSERVER_CONFIG'] ||= ENV_FILE + '_rgeoserver.yml'
require 'rgeoserver'

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
WORKSPACE_NAME = GeoMDTK::CONFIG.geoserver.workspace || 'druid'
NAMESPACE = GeoMDTK::CONFIG.geoserver.namespace || 'http://purl.stanford.edu'

# GeoWebCache configuration
SEED = GeoMDTK::CONFIG.geowebcache
SEED_OPTIONS = {
  :srs => {
    :number => GeoMDTK::CONFIG.geowebcache.srs.gsub(%r{^EPSG:}, '').to_i
  },
  :zoomStart => GeoMDTK::CONFIG.geowebcache.zoom.gsub(%r{:\d$}, '').to_i,
  :zoomStop => GeoMDTK::CONFIG.geowebcache.zoom.gsub(%r{^\d:}, '').to_i,
  :format => GeoMDTK::CONFIG.geowebcache.format || 'image/png',
  :threadCount => (GeoMDTK::CONFIG.geowebcache.threadCount || '1').to_i
}

def main catalog, ws, layers, flags = {}
  raise ArgumentError, "Layer is malformed" unless not layers.nil? and layers.is_a? Hash and not layers.empty?

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

    elsif format == 'Shapefile'
      # Create data stores for shapefiles
      puts "DataStore: #{ws.name}/#{layername} (#{format} #{v['remote']})" if flags[:verbose]
      ds = RGeoServer::DataStore.new catalog, :workspace => ws, :name => v['druid'].id
      ds.enabled = 'true'
      ds.data_type = :shapefile
      if v['remote']
        ds.upload_external v['filename']
      else
        ds.upload_file v['filename']
      end
      ds.connection_parameters = ds.connection_parameters.merge({
        "namespace" => NAMESPACE,
        "charset" => 'UTF-8',
        "create spatial index" => 'true',
        "cache and reuse memory maps" => 'true',
        "enable spatial index" => 'true',
        "filetype" => 'shapefile',
        "memory mapped buffer" => 'false'
      })
      ds.description = v['description']
      ds.save
      
      puts "FeatureType: #{ws.name}/#{ds.name}/#{layername}" if flags[:verbose]
      ft = RGeoServer::FeatureType.new catalog, :workspace => ws, :data_store => ds, :name => layername 
      raise Exception, "FeatureType doesn't already exists #{ft}" if ft.new?
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
    lyr = RGeoServer::Layer.new catalog, :name => layername
    if not lyr.new? and SEED
      puts "Layer: seeding with #{SEED_OPTIONS}" if flags[:verbose]
      lyr.seed :issue, SEED_OPTIONS
    end
  end
end

def from_druid druid, flags
  prj = flags[:projection] || "EPSG:4326"
  prj = prj.split(':').join('_')
  druid = DruidTools::Druid.new(druid, flags[:datadir])
  ap druid
  mods_fn = druid.path('metadata/descMetadata.xml')
  puts "Extracting load parameters from #{druid.id} #{mods_fn}"
  mods = Mods::Record.new
  mods.from_url(mods_fn)
  zipfn = nil
  layername = nil
  Dir.glob(druid.content_dir + "/*_#{prj}.zip") do |fn|
    puts "Found EPSG 4326 zip: #{fn}"
    zipfn = fn
    layername = File.basename(zipfn, '_#{prj}.zip')
  end
  if not zipfn
    puts "NOT found EPSG 4326 zip"
    Dir.glob(druid.content_dir + "/*.zip") do |fn|
      zipfn = fn
      layername = File.basename(zipfn, '.zip')
    end
  end
  raise ArgumentError, zipfn unless File.exist?(zipfn) and layername
  ap({:zipfn => zipfn, :layername => layername})
  r = { 
    'vector' => {
      'druid' => druid,
      'remote' => false,
      'format' => 'Shapefile',
      'layername' => layername,
      'filename' => zipfn,
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
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]})") do |v|
      flags[:datadir] = v
    end
    opts.on("-f FORMAT", "--format=FORMAT", "Input file format of MODS or YAML (default: #{flags[:format]})") do |v|
      raise ArgumentError, "Invalid format #{v}" unless ['YAML', 'MODS'].include?(v.upcase)
      flags[:format] = v.upcase
    end
  end.parse!
  
  # init
  # Connect to the GeoServer catalog
  catalog = RGeoServer::catalog

  # Obtain a handle to the workspace and clean it up. 
  ws = RGeoServer::Workspace.new catalog, :name => WORKSPACE_NAME
  puts "Workspace: #{ws.name} new?=#{ws.new?}" if flags[:verbose]
  ws.delete :recurse => true if flags[:delete] and not ws.new?
  ws.enabled = 'true'
  ws.save

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
  exit(-1)
end
