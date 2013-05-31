#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'

def do_system cmd
  if cmd.is_a? Array
    cmd = cmd.join(' ')
  end
  puts "RUNNING: #{cmd}"
  system(cmd.to_s)
end

def main flags
  client = GeoMDTK::GeoNetwork.new
  client.each do |uuid|
    puts "Processing #{uuid}"
    obj = client.fetch(uuid)
    unless obj.druid
      # raise ArgumentError, "uuid #{uuid} missing druid"
      $stderr.puts "WARNING: uuid #{uuid} is missing Druid"
      next
    end
    
    # setup
    druid = DruidTools::Druid.new(obj.druid, flags[:workspacedir])
    raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
    [druid.path, druid.content_dir, druid.metadata_dir].each do |d|
      unless File.directory? d
        ap "Creating directory #{d}"
        FileUtils.mkdir_p d 
      end
    end

    # export MEF -- the .iso19139.xml file is preferred
    puts "Exporting MEF for #{uuid}"
    client.export(uuid, flags[:tmpdir])
    do_system(['unzip', '-jo', 
               "#{flags[:tmpdir]}/#{uuid}.mef", 
               "#{uuid}/metadata/metadata*.xml",
                "-d", flags[:tmpdir]])
    found_metadata = false
    %w{metadata.iso19139.xml metadata.xml}.each do |fn|
      fn = File.join(flags[:tmpdir], fn)
      next unless File.exist? fn
      
      found_metadata = true
      xfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
      puts "Copying #{fn} => #{xfn}"
      FileUtils.install fn, xfn
      File.delete fn

      yfn = File.join(druid.metadata_dir, 'descMetadata.xml')
      xslt = File.expand_path(File.dirname(__FILE__) + '/../lib/geomdtk/iso19139_to_mods.xsl')
      puts "Transforming[#{xslt}] #{xfn} => #{yfn}"
      do_system(['xsltproc', '--output', yfn, xslt, xfn])
      break
    end
    raise ArgumentError, "Cannot export MEF metadata: #{uuid}: Missing #{flags[:tmpdir]}/metadata.xml" unless found_metadata
    
    # export content into zip files
    Dir.glob(File.join(flags[:stagedir], "#{druid.id}.zip")) do |fn|
      # extract shapefile name using filename pattern from
      # http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf
      k = %r{([a-zA-Z0-9_-]+)\.shp$}.match(`unzip -l #{fn}`)[1] 
      ofn = "#{druid.content_dir}/#{k}.zip"
      puts "Copying GIS data: #{fn} -> #{ofn}"
      FileUtils.install fn, ofn
    end    
  end
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :verbose => true,
    :stagedir => GeoMDTK::CONFIG.geomdtk.stage || 'stage',
    :workspacedir => GeoMDTK::CONFIG.geomdtk.workspace || 'workspace',
    :tmpdir => GeoMDTK::CONFIG.geomdtk.tmpdir || 'tmp'
  }
  
  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [-v] [--stage DIR]
EOM
    opts.on("-v", "--[no-]verbose", "Run verbosely (default: #{flags[:verbose]})") do |v|
      flags[:verbose] = v
    end
    opts.on("--stagedir DIR", "Staging directory with ZIP files (default: #{flags[:stagedir]})") do |v|
      flags[:stagedir] = v
    end
    opts.on("--workspace DIR", "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
      flags[:workspacedir] = v
    end
    opts.on("--tmpdir DIR", "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |v|
      flags[:tmpdir] = v
    end
  end.parse!
  
  [flags[:tmpdir], flags[:stagedir], flags[:workspacedir]].each do |d|
    raise ArgumentError, "Missing directory #{d}" unless File.directory? d
  end

  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
