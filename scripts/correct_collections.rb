#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'druid-tools'

def doit(druid, flags)
  puts "Processing #{druid.id}"
  
  begin
    item = Dor::Item.find(druid.druid)
    ap({:item => item, :collections => item.collections}) if flags[:debug]
    raise ArgumentError, "Item not editable: #{druid.id}" unless item.allows_modification?
    
    # remove all collections
    item.collections.dup.each {|c| item.remove_collection(c)}
    
    # add the new ones
    flags[:collections].each do |k, collection|
      item.add_collection(collection)
    end
    
    ap({:item => item, :collections => item.collections}) if flags[:debug]
    # item.save
  rescue ActiveFedora::ObjectNotFoundError => e
    puts "ERROR: #{e.message}"
  end
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :tmpdir => GeoHydra::Config.geohydra.tmpdir || 'tmp',
    :verbose => false,
    :debug => false,
    :collections => {},
    :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [druid [druid...] | < druids]
EOM
    opts.on('--collection DRUID', 'Collection for accession') do |druid|
      flags[:collections][DruidTools::Druid.new(druid).id] = nil
    end
    opts.on('--tmpdir DIR', "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |d|
      flags[:tmpdir] = d
    end
    opts.on('-v', '--verbose', 'Run verbosely, use multiple times for debug level output') do
      flags[:debug] = true if flags[:verbose]  # -vv
      flags[:verbose] = true
    end
    opts.on('--workspace DIR', "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |d|
      flags[:workspacedir] = d
    end
  end.parse!

  [flags[:tmpdir], flags[:workspacedir]].each do |d|
    raise ArgumentError, "Missing directory #{d}" unless File.directory? d
  end

  ap({:flags => flags}) if flags[:debug]
  
  # Validate collection druids
  flags[:collections].each do |druid,v|
    begin
      flags[:collections][druid] = Dor::Collection.find(druid)
    rescue ActiveFedora::ObjectNotFoundError => e
      puts "ERROR: Invalid collection #{druid}: #{e.message}"
      exit(-1)
    end
  end

  (ARGV.empty?? STDIN : ARGV).each do |pid|
    druid = DruidTools::Druid.new(pid.strip, flags[:workspacedir])
    ap({:druid => druid}) if flags[:debug]
    begin
      doit(druid, flags)
    rescue Exception => e
      ap({:error => e})
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
