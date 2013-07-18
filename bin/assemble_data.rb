#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'

def doit(client, uuid, obj, flags)
  # # setup
  # druid = DruidTools::Druid.new(obj.druid, flags[:workspacedir])
  # raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
  # [druid.path, druid.content_dir, druid.metadata_dir, druid.temp_dir].each do |d|
  #   unless File.directory? d
  #     $stderr.puts "Creating directory #{d}" if flags[:verbose]
  #     FileUtils.mkdir_p d
  #   end
  # end
  # 
  # # export MEF -- the .iso19139.xml file is preferred
  # puts "Exporting MEF for #{uuid}" if flags[:verbose]
  # client.export(uuid, flags[:tmpdir])
  # system(['unzip', '-oq',
  #         "'#{flags[:tmpdir]}/#{uuid}.mef'",
  #         '-d', "'#{flags[:tmpdir]}'"].join(' '))
  # 
  # found_metadata = false
  # %w{metadata.iso19139.xml metadata.xml}.each do |fn| # priority order
  #   unless found_metadata
  #     fn = File.join(flags[:tmpdir], uuid, 'metadata', fn)
  #     next unless File.exist? fn
  # 
  #     found_metadata = true
  # 
  #     # original ISO 19139
  #     ifn = File.join(druid.temp_dir, 'iso19139.xml')
  #     FileUtils.install fn, ifn, :verbose => flags[:verbose]
  # 
  #     # GeoMetadataDS
  #     gfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
  #     puts "Generating #{gfn}" if flags[:verbose]
  #     File.open(gfn, 'w') { |f| f << GeoMDTK::Transform.to_geoMetadataDS(ifn) }
  # 
  #     # MODS from GeoMetadataDS
  #     geoMetadata = Dor::GeoMetadataDS.from_xml File.read(gfn)
  #     ap({:geoMetadata => geoMetadata.ng_xml, :descMetadata => geoMetadata.to_mods}) if flags[:debug]
  #     dfn = File.join(druid.metadata_dir, 'descMetadata.xml')
  #     puts "Generating #{dfn}" if flags[:verbose]
  #     File.open(dfn, 'w') { |f| f << geoMetadata.to_mods.to_xml }
  # 
  #     # Solr document from GeoMetadataDS
  #     sfn = File.join(druid.temp_dir, 'solr.xml')
  #     puts "Generating #{sfn}" if flags[:verbose]
  #     h = geoMetadata.to_solr_spatial
  #     ap({:to_solr_spatial => h}) if flags[:debug]
  #     doc = Nokogiri::XML::Builder.new do |xml|
  #       xml.add {
  #         xml.doc_ {
  #           h.each do |k, v|
  #             v.each do |s|
  #               xml.field s, :name => k
  #             end unless v.nil?
  #           end unless h.nil?
  #         }
  #       }
  #     end
  #     File.open(sfn, 'w') { |f| f << doc.to_xml }
  # 
  #     # OGP Solr document from GeoMetadataDS
  #     sfn = File.join(druid.temp_dir, 'ogpSolr.xml')
  #     puts "Generating #{sfn}" if flags[:verbose]
  #     system(['xsltproc', 
  #             "'#{File.dirname(__FILE__)}/../lib/geomdtk/mods2ogp.xsl'",
  #             "'#{dfn}'",
  #             "> '#{sfn}'",
  #             '2> /dev/null'].join(' '))
  # 
  #     # Solr document from GeoMetadataDS
  #     dcfn = File.join(druid.temp_dir, 'dc.xml')
  #     puts "Generating #{dcfn}" if flags[:verbose]
  #     File.open(dcfn, 'w') { |f| f << geoMetadata.to_dublin_core.to_xml }
  #   end
  # end
  # 
  # raise ArgumentError, "Cannot extract MEF metadata: #{uuid}: Missing metadata.xml" unless found_metadata
  # 
  # # export any thumbnail images
  # ['png', 'jpg'].each do |fmt|
  #   Dir.glob("#{flags[:tmpdir]}/#{uuid}/{private,public}/*.#{fmt}") do |fn|
  #     ext = '.' + fmt
  #     tfn = File.basename(fn, ext)
  #     # convert _s to _small as per GeoNetwork convention
  #     tfn = tfn.gsub(/_s$/, '_small')
  #     FileUtils.install fn, File.join(druid.content_dir, tfn + ext), 
  #                       :verbose => flags[:debug]
  #   end
  # end
  # 
  # # export content into zip files
  # Dir.glob(File.join(flags[:stagedir], "#{druid.id}.zip")) do |fn|
  #   # extract shapefile name using filename pattern from
  #   # http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf
  #   k = %r{([a-zA-Z0-9_-]+)\.(shp|tif)$}i.match(`unzip -l #{fn}`)[1]
  #   ofn = "#{druid.content_dir}/#{k}.zip"
  #   FileUtils.install fn, ofn, :verbose => flags[:verbose]
  # end
end

def main(flags)
  ap({:flags => flags}) if flags[:debug]
  File.umask(002)
  Dir.glob("#{flags[:srcdir]}/**/*.shp") do |shp|
    basefn = File.basename(shp, '.shp')
    puts "Processing <#{basefn}>" if flags[:verbose]
    zipfn = "#{flags[:tmpdir]}/#{basefn}.zip"
    system "zip -jv #{zipfn} #{File.dirname(shp)}/#{basefn}.*"
  end
  # client = GeoMDTK::GeoNetwork.new
  # client.each do |uuid|
  #   begin
  #     puts "Processing #{uuid}"
  #     obj = client.fetch(uuid)
  #     doit client, uuid, obj, flags
  #   rescue Exception => e
  #     $stderr.puts e
  #     $stderr.puts e.backtrace if flags[:debug]
  #   end
  # end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :stagedir => GeoMDTK::Config.geomdtk.stage || 'stage',
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] srcdir
EOM
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on("--stagedir DIR", "Staging directory with ZIP files (default: #{flags[:stagedir]})") do |v|
      flags[:stagedir] = v
    end
    opts.on("--tmpdir DIR", "Temporary directory (default: #{flags[:tmpdir]})") do |v|
      flags[:tmpdir] = v
    end
    opts.on("--srcdir DIR", "Input directory") do |v|
      flags[:srcdir] = v
    end
  end.parse!

  [:stagedir].each do |k|
    raise ArgumentError, "Missing directory #{flags[k]}" unless File.directory? flags[k]
  end
  
  flags[:srcdir] = ARGV.pop if flags[:srcdir].nil?
  raise ArgumentError, "Missing directory #{flags[:srcdir]}" unless File.directory? flags[:srcdir]

  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
