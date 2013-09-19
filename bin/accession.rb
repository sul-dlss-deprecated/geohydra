#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'druid-tools'

VERSION = '0.3'

# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:gz830zp4734',
    :rights => 'stanford',
    :tags => [
      "Registered By : #{%x{whoami}.strip} (GeoHydra)"
    ],
    :tmpdir => GeoHydra::Config.geohydra.tmpdir || 'tmp',
    :verbose => false,
    :configtest => false,
    :purge => false,
    :accessionWF => false,
    :contentMetadata => true,
    :debug => false,
    :shelve => false,
    :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace'
  }

  OptionParser.new do |opts|
    opts.version = VERSION
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [druid [druid...]]
       #{File.basename(__FILE__)} [options] < druids
EOM
    opts.on('--apo DRUID', 'APO for collection to accession' + (flags[:admin_policy] ? " (default: #{flags[:admin_policy]})" : '')) do |druid|
      flags[:admin_policy] = DruidTools::Druid.new(druid).druid
    end
    opts.on('--collection DRUID', 'Collection for accession' + (flags[:collection] ? " (default: #{flags[:collection]})" : '')) do |druid|
      flags[:collection] = DruidTools::Druid.new(druid).druid
    end
    opts.on('--purge', 'Purge items before accessioning') do |b|
      flags[:purge] = true
    end
    opts.on('--accessionWF', 'Kick off the accessionWF workflow') do |b|
      flags[:accessionWF] = true
    end
    opts.on('--rights KEYWORD', "Rights keyword (default: #{flags[:rights]})") do |keyword|
      flags[:rights] = keyword
    end
    opts.on('--tag TAG', 'Tag for each object - multiple tags allowed') do |tag|
      flags[:tags] << tag
    end
    opts.on('--test', 'Verify configuration then exit') do
      flags[:configtest] = true
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

  # Verify configuation
  if flags[:configtest]
    errs = 0
    %w{workflow.url fedora.safeurl solrizer.url ssl.cert_file ssl.key_pass dor.service_root}.each do |k|
      begin
        k = "Dor::Config.#{k}"
        if eval(k).nil?
          $stderr.puts "ERROR: Configuration requires #{k}" 
          errs += 1
        end
      rescue Exception => e
        $stderr.puts e, e.backtrace
      end
    end
    puts "Configuration OK" if errs == 0
    exit errs
  end

  if ARGV.empty?
    STDIN.each do |line|
      pid = line.strip
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      GeoHydra::Accession.run(druid, flags)
    end
  else
    ARGV.each do |pid|
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      GeoHydra::Accession.run(druid, flags)
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
