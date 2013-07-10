#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'

def do_system(cmd)
  cmd = cmd.join(' ') if cmd.is_a? Array
  puts "RUNNING: #{cmd}" if $DEBUG
  system(cmd.to_s)
end

def doit(client, uuid, obj, flags)
  # setup
  druid = DruidTools::Druid.new(obj.druid, flags[:workspacedir])
  raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
  [druid.path, druid.content_dir, druid.metadata_dir, druid.temp_dir].each do |d|
    unless File.directory? d
      $stderr.puts "Creating directory #{d}" if flags[:verbose]
      FileUtils.mkdir_p d
    end
  end

  # export MEF -- the .iso19139.xml file is preferred
  puts "Exporting MEF for #{uuid}" if flags[:verbose]
  client.export(uuid, flags[:tmpdir])
  do_system(['unzip', '-oq',
             "#{flags[:tmpdir]}/#{uuid}.mef",
             "-d", "#{flags[:tmpdir]}"])

  found_metadata = false
  %w{metadata.iso19139.xml metadata.xml}.each do |fn| # priority order
    unless found_metadata
      fn = File.join(flags[:tmpdir], uuid, 'metadata', fn)
      next unless File.exist? fn

      found_metadata = true

      # original ISO 19139
      ifn = File.join(druid.temp_dir, 'iso19139.xml')
      FileUtils.install fn, ifn, :verbose => flags[:verbose]
      File.delete fn

      # GeoMetadataDS
      gfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
      puts "Generating #{gfn}" if flags[:verbose]
      File.open(gfn, 'w') { |f| f << GeoMDTK::Transform.to_geoMetadataDS(ifn) }

      # MODS from GeoMetadataDS
      geoMetadata = Dor::GeoMetadataDS.from_xml File.read(gfn)
      ap({:geoMetadata => geoMetadata.ng_xml, :descMetadata => geoMetadata.to_mods}) if flags[:verbose]
      dfn = File.join(druid.metadata_dir, 'descMetadata.xml')
      puts "Generating #{dfn}" if flags[:verbose]
      File.open(dfn, 'w') { |f| f << geoMetadata.to_mods.to_xml }

      # Solr document from GeoMetadataDS
      sfn = File.join(druid.temp_dir, 'solr.xml')
      puts "Generating #{sfn}" if flags[:verbose]
      h = geoMetadata.to_solr_spatial
      ap({:to_solr_spatial => h}) if flags[:verbose]
      doc = Nokogiri::XML::Builder.new do |xml|
        xml.add {
          xml.doc_ {
            h.each do |k, v|
              v.each do |s|
                xml.field s, :name => k
              end unless v.nil?
            end unless h.nil?
          }
        }
      end
      File.open(sfn, 'w') { |f| f << doc.to_xml }

      # OGP Solr document from GeoMetadataDS
      sfn = File.join(druid.temp_dir, 'ogpSolr.xml')
      puts "Generating #{sfn}" if flags[:verbose]
      system("xsltproc #{File.dirname(__FILE__)}/../lib/geomdtk/mods2ogp.xsl #{dfn} > #{sfn} 2>/dev/null")

      # Solr document from GeoMetadataDS
      dcfn = File.join(druid.temp_dir, 'dc.xml')
      puts "Generating #{dcfn}" if flags[:verbose]
      File.open(dcfn, 'w') { |f| f << geoMetadata.to_dublin_core.to_xml }
    end
  end

  raise ArgumentError, "Cannot extract MEF metadata: #{uuid}: Missing metadata.xml" unless found_metadata

  # export any thumbnail images
  ['png', 'jpg'].each do |fmt|
    Dir.glob(File.join(flags[:tmpdir], uuid, '{private,public}', ('*.' + fmt))) do |fn|
      ext = '.' + fmt
      tfn = File.basename(fn, ext)
      tfn += 'mall' if tfn =~ %r{_s$} # convert _s to _small as per GeoNetwork convention
      FileUtils.install fn, File.join(druid.content_dir, tfn + ext), :verbose => flags[:verbose]
    end
  end

  # export content into zip files
  Dir.glob(File.join(flags[:stagedir], "#{druid.id}.zip")) do |fn|
    # extract shapefile name using filename pattern from
    # http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf
    k = %r{([a-zA-Z0-9_-]+)\.(shp|tif)$}i.match(`unzip -l #{fn}`)[1]
    ofn = "#{druid.content_dir}/#{k}.zip"
    FileUtils.install fn, ofn, :verbose => flags[:verbose]
  end
end

def main(flags)
  client = GeoMDTK::GeoNetwork.new
  client.each do |uuid|
    begin
      puts "Processing #{uuid}"
      obj = client.fetch(uuid)
      # unless obj.druid
      #   # raise ArgumentError, "uuid #{uuid} missing druid"
      #   $stderr.puts "WARNING: uuid #{uuid} is missing Druid"
      #   next
      # end
      doit client, uuid, obj, flags
    rescue Exception => e
      $stderr.puts e, e.backtrace
    end
  end
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :verbose => false,
    :stagedir => GeoMDTK::Config.geomdtk.stage || 'stage',
    :workspacedir => GeoMDTK::Config.geomdtk.workspace || 'workspace',
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options]
EOM
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:verbose] = true
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
