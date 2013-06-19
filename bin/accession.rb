#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'

require 'druid-tools'
require 'geomdtk'

def do_accession druid, flags = {}
  # validate parameters
  unless druid.is_a? DruidTools::Druid
    raise ArgumentError, "Invalid druid: #{druid}" 
  end
  unless ['world','stanford','none', 'dark'].include? flags[:rights]
    raise ArgumentError, "Invalid rights: #{flags[:rights]}" 
  end

  # setup input metadata
  xml = File.read(druid.path('metadata/geoMetadata.xml'))
  geoMetadata = Dor::GeoMetadataDS.from_xml(xml)

  # required parameters
  opts = {
      :object_type  => 'item',
      :label        => geoMetadata.title.first.to_s
  }

  # optional parameters
  opts.merge!({
    :pid              => druid.druid, # druid:xx111xx1111
    :source_id        => { 'geomdtk' => geoMetadata.file_id.first.to_s },
    :tags             => [
      "Project : GIS", 
      "Registered By : #{%x{whoami}.strip} (GeoMDTK)"]
  })
  
  # copy other optional parameters from input flags
  [:admin_policy, :collection, :rights].each do |k|
    opts[k] = flags[k] unless flags[k].nil?
  end
  unless flags[:tags].nil?
    flags[:tags].each { |t| opts[:tags] << t } 
  end

  ap({:item_options => opts}) if flags[:verbose]
  
  # Purge item if needed
  item = nil
  if flags[:purge]
    begin
      item = Dor::Item.find(druid.druid)
      $stderr.puts "Purging #{item.id}" if flags[:verbose]
      item.delete
      item = nil
    rescue ActiveFedora::ObjectNotFoundError => e
      # no object to delete
    end
  end
  
  # Register item
  begin
    $stderr.puts "Registering #{opts[:pid]}" if flags[:verbose]
    item = Dor::RegistrationService.register_object opts
  rescue Dor::DuplicateIdError => e
    begin
      $stderr.puts "Fallback #{opts[:pid]} #{druid.id}" if flags[:verbose]
      item = Dor::Item.find(druid.id)
    rescue ActiveFedora::ObjectNotFoundError => e
      $stderr.puts "ABORT: Missing object claimed to be registered???? #{druid.druid}"
      return nil
    end
  end
  
  # now item is registered, so generate mods
  $stderr.puts "Assigning GeoMetadata for #{item.id}" if flags[:verbose]
  item.datastreams['geoMetadata'].content = geoMetadata.ng_xml.to_xml
  item.datastreams['descMetadata'].content = item.generate_mods.to_xml

  # save changes
  $stderr.puts "Saving #{item.id}" if flags[:verbose]
  item.save
  
  # upload data files to contentMetadata if required
  if flags[:upload]
    Dir.glob("#{druid.content_dir}/*.{png,jpg,gif,zip}").each do |fn|
      $stderr.puts "Uploading content #{fn}"
      objectfile = Assembly::ObjectFile.new(fn)
      # XXX tbd
    end
  end
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:cb854wz7157',
    :rights => 'stanford',
    :tags => [],
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp',
    :verbose => true,
    :configtest => false,
    :purge => false,
    :upload => false,
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
    opts.on("--[no]-purge", "Purge items before accessioning (default: #{flags[:purge]})") do |v|
      flags[:purge] = v
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
    Dir.glob("#{flags[:workspacedir]}/**/metadata/geoMetadata.xml") do |fn|
      if fn =~ %r{/([a-z0-9]+)/metadata/geoMetadata.xml}
        druid = DruidTools::Druid.new($1, flags[:workspacedir])
        do_accession druid, flags
      end
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
