#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'nokogiri'
require 'optparse'

def main(flags)
  isoXml = Nokogiri::XML(File.read(flags[:iso19139]))
  if isoXml.nil? or isoXml.root.nil?
    raise ArgumentError, "Empty ISO 19139" 
  end
  if flags[:iso19110].nil?
    fcXml = nil
  else
    fcXml = Nokogiri::XML(File.read(flags[:iso19110]))
  end

  ap({:isoXml => isoXml, :fcXml => fcXml, :flags => flags}) if flags[:debug]

  # GeoMetadataDS
  puts "Generating #{flags[:geoMetadata]}" if flags[:verbose]
  xml = GeoHydra::Transform.to_geoMetadataDS(isoXml, fcXml, { 'purl' => flags[:purl] }) 
  File.open(flags[:geoMetadata], 'wb') {|f| f << xml.to_xml(:indent => 2) }  
end

# __MAIN__
begin
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
    %w{19110 19139}.each do |n|
      opts.on("--iso#{n} FILE", "Input file with ISO #{n} XML") do |v|
        flags["iso#{n}".to_sym] = v
      end
    end
    opts.on('--geoMetadata FILE', "Output file with ISO 19139/19110 XML") do |v|
      flags[:geoMetadata] = v
    end
  end.parse!
  
  %w{purl iso19139 geoMetadata}.each do |k|
    raise ArgumentError, "Missing required --#{k} flag" if flags[k.to_sym].nil?
  end
  
  ap({:flags => flags}) if flags[:debug]
  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
