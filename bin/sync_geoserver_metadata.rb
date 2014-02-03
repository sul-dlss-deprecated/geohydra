#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'uri'
require 'yaml'

require 'druid-tools'
require 'mods'

ENV['RGEOSERVER_CONFIG'] ||= ENV_FILE + '_rgeoserver.yml'
require 'rgeoserver'

class SyncGeoserverMetadata < GeoHydra::Process
  def do_raster(c, ws, layername, layer, flags)
    ap({:catalog => c, :workspace => ws, :name => layername, :layer => layer}) if flags[:debug]
  
    cs = RGeoServer::CoverageStore.new c, :workspace => ws, :name => layername
    ap({:coveragestore => cs}) if flags[:debug]
    raise ArgumentError, "Missing CoverageStore #{layername}: #{cs}" if cs.new?
  
    cv = RGeoServer::Coverage.new c, :workspace => ws, :coverage_store => cs, :name => layername
    raise ArgumentError, "Missing Coverage #{layername}: #{cv}" if cv.new?
  
    %w{title abstract keywords metadata_links}.each do |i|
      raise ArgumentError, "Layer is missing #{i}" unless layer.include?(i) and not layer[i].empty?
    end
    cv.enabled = true
    cv.title = layer['title']
    cv.abstract = layer['abstract']  
    cv.keywords = [cv.keywords, layer['keywords']].flatten.compact.uniq
    cv.metadata_links = layer['metadata_links']
    puts "Saving #{cv}" if flags[:verbose]
    cv.save
  end

  def do_vector(c, ws, ds, layername, layer, flags)
    ap({:catalog => c, :workspace => ws, :data_store => ds, :name => layername, :layer => layer}) if flags[:debug]
  
    %w{title abstract keywords metadata_links}.each do |i|
      raise ArgumentError, "Layer is missing #{i}" unless layer.include?(i) and not layer[i].empty?
    end

    ft = RGeoServer::FeatureType.new c, :workspace => ws, :data_store => ds, :name => layername
    raise ArgumentError, "Missing FeatureType #{layername}: #{ft}" if ft.new?

    ft.enabled = true
    ft.title = layer['title']
    ft.abstract = layer['abstract']  
    ft.keywords = [ft.keywords, layer['keywords']].flatten.compact.uniq
    ft.metadata_links = layer['metadata_links']
    puts "Saving #{ft}" if flags[:verbose]
    ft.save
  end

  def main catalog, ws, layers, flags = {}
    raise ArgumentError, "Layer is malformed" unless not layers.nil? and layers.is_a? Hash and not layers.empty?

    if flags[:raster]
      # Iterate over all records and load Coverage info in the catalog
      layers.each do |k, layer|
        format = layer['format'].downcase.to_sym
        case format
        when :geotiff
          do_raster catalog, ws, layer['druid'], layer, flags
        else
          raise NotImplementedError, "Unsupported format #{format}"    
        end
      end
    else
      ap({:ws => ws, :ds => flags[:datastore]}) if flags[:debug]
      ds = RGeoServer::DataStore.new catalog, :workspace => ws, :name => flags[:datastore]
      puts "DataStore: #{ws.name}/#{ds.name}" if flags[:debug]
      ap({:profile => ds.profile}) if flags[:debug]
      raise ArgumentError, "Datastore #{ds.name} not found" if ds.new?

      # Iterate over all records and load FeatureType info in the catalog
      layers.each do |k, layer|
        format = layer['format'].downcase.to_sym
        case format
        when :shapefile
          do_vector catalog, ws, ds, layer['druid'], layer, flags
        else
          raise NotImplementedError, "Unsupported format #{format}"    
        end
      end
    end
  end

  # @return [Hash] selectively parsed MODS record to match RGeoServer requirements
  def from_druid druid, flags  
    druid = DruidTools::Druid.new(druid, flags[:workspacedir])
    puts "Processing #{druid.id}" if flags[:verbose]

    mods_fn = File.join(druid.metadata_dir, 'descMetadata.xml')
    mods = Mods::Record.new
    mods.from_str(File.read(mods_fn))
  
    h = { 
      (flags[:raster] ? 'raster' : 'vector') => {
        'druid' => druid.id,
        'format' => (flags[:raster] ? 'GeoTIFF' : 'Shapefile'),
        'title' => mods.full_titles.first,
        'abstract' => mods.term_values(:abstract).compact.join("\n"),
        'keywords' => [mods.term_values([:subject, 'topic']),
                       mods.term_values([:subject, 'geographic'])].flatten.compact.collect {|k| k.strip},
        'metadata_links' => [{
          'metadataType' => 'TC211',
          'content' => "http://purl.stanford.edu/#{druid.id}.geoMetadata"
        }]
      }
    }
    ap({:h => h}) if flags[:debug]
    h
  end

  # __MAIN__
  def run(args)
    flags = {
      :debug => false,
      :verbose => false,
      :raster => false,
      :workspacedir => GeoHydra::Config.geohydra.workspace || '/var/geomdtk/current/workspace',
      :datastore => GeoHydra::Config.geoserver.datastore || 'geoserver',
      :workspace => GeoHydra::Config.geoserver.workspace || 'druid',
      :namespace => GeoHydra::Config.geoserver.namespace || 'http://purl.stanford.edu'
    }
  
    OptionParser.new do |opts|
      opts.banner = "
  Usage: #{File.basename(__FILE__)} [options] [druid ... | < druids]
  "
      opts.on("-v", "--verbose", "Run verbosely") do
        flags[:debug] = true if flags[:verbose]
        flags[:verbose] = true
      end
      opts.on("--raster", "Use rasters for given druids") do
        flags[:raster] = true
      end
      opts.on("-d DIR", "Workspace directory (default: #{flags[:workspacedir]})") do |v|
        raise ArgumentError, "Invalid directory #{v}" unless File.directory?(v)
        flags[:workspacedir] = v
      end
      opts.on("--workspace NAME", "Workspace on GeoServer (default: #{flags[:workspace]})") do |v|
        flags[:workspace] = v.to_s
      end
      opts.on("--datastore NAME", "Datastore on GeoServer (default: #{flags[:datastore]})") do |v|
        flags[:datastore] = v.to_s
      end
    end.parse!(args)
  
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

    (args.size > 0 ? args : $stdin).each do |v|
      main(catalog, ws, from_druid(v.strip, flags), flags)          
    end
  end
end

# __MAIN__
SyncGeoserverMetadata.new.run(ARGV)
