#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'geomdtk'


def do_accession druid, flags = {}
  raise ArgumentError unless druid.is_a? DruidTools::Druid
  xml = File.read(druid.path('metadata/geoMetadata.xml'))
  # ds = Dor::GeoMetadataDS.from_xml(xml)
  
  # required parameters
  opts = {
      :object_type  => 'item',
      :label        => 'hi' #ds.title.first
  }
  # optional parameters
  opts.merge! ({
    # :metadata_source  => 'GeoMDTK',
    :pid              => druid.druid, # druid:xx111xx1111
    :source_id        => { 'geomdtk' => 'foobar' },#ds.file_id.first.to_s },
    :tags             => ["Project : GIS", "Registered By : #{%x{whoami}.strip} (GeoMDTK)"]
    })

  [:admin_policy, :collection, :rights].each do |k|
    opts[k] = flags[k] unless flags[k].nil?
  end
    
  flags[:tags].each {|t| opts[:tags] << t } unless flags[:tags].nil?
    
  ap({:all => opts})
  item = Dor::RegistrationService.register_object opts
  ap item
  
  # item.datastreams['geoMetadata'] = ds
  # item.save
  
  ap item
end


# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:cb854wz7157',
    :tags => [],
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp',
    :verbose => true,
    :configtest => false,
    :workspacedir => GeoMDTK::Config.geomdtk.workspace || 'workspace'
  }
  
  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [druid [druid...]]
EOM
    opts.on("-v", "--[no-]verbose", "Run verbosely (default: #{flags[:verbose]})") do |v|
      flags[:verbose] = v
    end
    opts.on("--workspace DIR", "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
      flags[:workspacedir] = v
    end
    opts.on("--tmpdir DIR", "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |v|
      flags[:tmpdir] = v
    end
    opts.on("--apo DRUID", "APO for collection to accession (default: #{flags[:admin_policy]})") do |v|
      flags[:admin_policy] = DruidTools::Druid.new(v).druid
    end
    opts.on("--collection DRUID", "Collection for accession (default: #{flags[:collection]})") do |v|
      flags[:collection] = DruidTools::Druid.new(v).druid
    end
    opts.on("--rights KEYWORD", "Rights keyword (default: #{flags[:rights]})") do |v|
      flags[:rights] = v
    end
    opts.on("--tag TAG", "Tag for each object - multiple tags allowed") do |v|
      flags[:tags] << v
    end
    opts.on("--configtest", "Verify configuration then exit (default: #{flags[:configtest]})") do |v|
      flags[:configtest] = v
    end
  end.parse!
  
  [flags[:tmpdir], flags[:workspacedir]].each do |d|
    raise ArgumentError, "Missing directory #{d}" unless File.directory? d
  end
  
  # Verify configuation
  if flags[:configtest]
    %w{workflow.url fedora.safeurl solrizer.url ssl.cert_file ssl.key_pass dor.service_root}.each do |k|
      begin
        k = "Dor::Config.#{k}"
        $stderr.puts "ERROR: Configuration requires #{k}" if eval(k).nil?
      rescue Exception => e
        $stderr.puts e, e.backtrace
      end
    end
    exit
  end

  if ARGV.empty?
    Dir.glob("#{flags[:workspacedir]}/**/geoMetadata.xml") do |fn|
      puts fn
      pid = %r{/([a-z0-9]+)/metadata/geoMetadata.xml}.match(fn)[1]
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      do_accession druid, flags
    end
  else
    ARGV.each do |pid|
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      do_accession druid, flags
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
