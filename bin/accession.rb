#!/usr/bin/env ruby
# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'druid-tools'

VERSION = '0.2'

# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:cb854wz7157',
    :rights => 'stanford',
    :tags => [
      'Registered With : GeoMDTK',
      "Registered By : #{%x{whoami}.strip}"
    ],
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp',
    :verbose => false,
    :configtest => false,
    :purge => false,
    :upload => false,
    :upload_max => Float::INFINITY, # unrestricted
    :debug => false,
    :workspacedir => GeoMDTK::Config.geomdtk.workspace || 'workspace'
  }

  OptionParser.new do |opts|
    opts.version = VERSION
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [druid [druid...]]
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
    opts.on('--upload[=MAX]', 'Upload content files -- MAX restricts to files smaller than MAX MB') do |mb|
      flags[:upload] = true
      flags[:upload_max] = (mb.to_f < 0 ? Float::INFINITY : mb.to_f) unless mb.nil?
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
    %w{workflow.url fedora.safeurl solrizer.url ssl.cert_file ssl.key_pass dor.service_root}.each do |k|
      begin
        k = "Dor::Config.#{k}"
        $stderr.puts "ERROR: Configuration requires #{k}"
      rescue Exception => e
        $stderr.puts e, e.backtrace
      end
    end
    exit
  end

  if ARGV.empty?
    Dir.glob("#{flags[:workspacedir]}/**/metadata/geoMetadata.xml") do |fn|
      if fn =~ %r{/([a-z0-9]+)/metadata/geoMetadata.xml}
        druid = DruidTools::Druid.new($1, flags[:workspacedir])
        GeoMDTK::Accession.new(druid).run flags
      end
    end
  else
    ARGV.each do |pid|
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      GeoMDTK::Accession.new(druid).run flags
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
