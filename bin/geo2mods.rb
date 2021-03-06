#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'json'

class Geo2MODS < GeoHydra::Process
  def main(flags)
    defaultGeometryType = 'Polygon'
    defaultZipName = 'data.zip'
    purl, ifn, optfn, ofn = flags[:purl], flags[:geoMetadata], flags[:geoOptions], flags[:descMetadata]
  
    puts "Processing #{purl} #{ifn}" if flags[:verbose]

    puts "Loading extra out-of-band options #{optfn}" if flags[:debug]
    if not optfn.nil? and File.exist?(optfn)
      h = JSON.parse(File.read(optfn))
      flags = flags.merge(h).symbolize_keys
      ap({:optfn => optfn, :h => h, :flags => flags}) if flags[:debug]
    else
      puts "WARNING: missing options .json parameters: #{optfn}"
      flags[:geometryType] ||= defaultGeometryType # XXX: placeholder
    end

    # Load datastream
    geoMetadataDS = Dor::GeoMetadataDS.from_xml File.read(ifn)
    geoMetadataDS.geometryType = flags[:geometryType] || defaultGeometryType
    geoMetadataDS.zipName = defaultZipName
    geoMetadataDS.purl = purl
    ap({:geoMetadataDS => geoMetadataDS}) if flags[:debug]

    # MODS from GeoMetadataDS
    puts "Generating #{flags[:descMetadata]}" if flags[:verbose]
    File.open(flags[:descMetadata], 'wb') do |f| 
      f << geoMetadataDS.to_mods.to_xml(:index => 2) 
    end
  end

  # __MAIN__
  def run(args)
    flags = {
      :debug => false,
      :verbose => false
    }

    OptionParser.new do |opts|
      opts.banner = <<EOM
  Usage: #{File.basename(__FILE__)} [options]
EOM
      opts.on('-v', '--verbose', 'Run verbosely') do |v|
        flags[:debug] = true if flags[:verbose]
        flags[:verbose] = true
      end
      opts.on('--purl URI', "PURL with druid") do |v|
        flags[:purl] = v
      end
      opts.on('--geoMetadata FILE', "Input file with ISO 19139/19110 XML") do |v|
        flags[:geoMetadata] = v
      end
      opts.on('--geoOptions FILE', "Input file with JSON flags") do |v|
        flags[:geoOptions] = v
      end
      opts.on('--descMetadata FILE', "Output file with MODS XML") do |v|
        flags[:descMetadata] = v
      end
    end.parse!(args)

    %w{purl geoMetadata descMetadata}.each do |k|
      raise ArgumentError, "Missing required --#{k} flag" if flags[k.to_sym].nil?
    end

    ap({:flags => flags}) if flags[:debug]
    main flags
  end
end

# __MAIN__
Geo2MODS.new.run(ARGV)
