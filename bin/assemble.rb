#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'json'

def setup_druid(obj, flags)
  druid = DruidTools::Druid.new(obj.druid, flags[:workspacedir])
  raise ArgumentError unless DruidTools::Druid.valid?(druid.druid)
  %w{path content_dir metadata_dir temp_dir}.each do |k|
    d = druid.send(k.to_sym)
    unless File.directory? d
      $stderr.puts "Creating directory #{d}" if flags[:verbose]
      FileUtils.mkdir_p d
    end
  end
  druid
end

def find_mef(druid, uuid, flags)
  # export MEF -- the .iso19139.xml file is preferred
  puts "Exporting MEF for #{uuid}" if flags[:verbose]
  client.export(uuid, flags[:tmpdir])
  system(['unzip', 
          '-oq',
          "'#{flags[:tmpdir]}/#{uuid}.mef'",
          '-d', 
          "'#{flags[:tmpdir]}'"].join(' '))
  found_metadata = false
  %w{metadata.iso19139.xml metadata.xml}.each do |fn| # priority order as per MEF
    unless found_metadata
      fn = File.join(flags[:tmpdir], uuid, 'metadata', fn)
      next unless File.exist? fn

      found_metadata = true
      # original ISO 19139
      ifn = File.join(druid.temp_dir, 'iso19139.xml')
      FileUtils.install fn, ifn, :verbose => flags[:verbose]
    end
  end
  ifn
end

def find_local(druid, xml, flags)
  ifn = File.join(druid.temp_dir, 'iso19139.xml')
  unless File.exist?(ifn)
    File.open(ifn, "w") {|f| f << xml.to_s}
  end
  ifn
end

def convert_iso2geo(druid, ifn, isoXml, fcXml, flags)
  isoXml = Nokogiri::XML(isoXml)
  if isoXml.nil? or isoXml.root.nil?
    raise ArgumentError, "Empty ISO 19139" 
  end
  fcXml = Nokogiri::XML(fcXml)
  ap({:ifn => ifn, :isoXml => isoXml, :fcXml => fcXml, :flags => flags}) if flags[:debug]
  # GeoMetadataDS
  gfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
  puts "Generating #{gfn}" if flags[:verbose]
  xml = GeoHydra::Transform.to_geoMetadataDS(isoXml, fcXml, { 'purl' => "#{flags[:purl]}/#{druid.id}"}) 
  File.open(gfn, 'w') {|f| f << xml.to_xml(:indent => 2) }
  gfn
end

def convert_geo2mods(druid, geoMetadata, flags)
  # MODS from GeoMetadataDS
  ap({:geoMetadata => geoMetadata.ng_xml}) if flags[:debug]
  dfn = File.join(druid.metadata_dir, 'descMetadata.xml')
  puts "Generating #{dfn}" if flags[:verbose]
  File.open(dfn, 'w') { |f| f << geoMetadata.to_mods.to_xml(:index => 2) }
  dfn
end

def convert_geo2solrspatial(druid, geoMetadata, flags)
  # Solr document from GeoMetadataDS
  sfn = File.join(druid.temp_dir, 'spatialSolr.xml')
  puts "Generating #{sfn}" if flags[:verbose]
  h = geoMetadata.to_solr_spatial
  ap({:to_solr_spatial => h}) if flags[:debug]
  
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
  File.open(sfn, 'w') { |f| f << doc.to_xml(:indent => 2) }
  sfn
end

def convert_mods2ogpsolr(druid, dfn, flags)
  raise ArgumentError, 'Missing required :geoserver flag' if flags[:geoserver].nil?
  raise ArgumentError, 'Missing required :purl flag' if flags[:purl].nil?

  geoserver = flags[:geoserver]
  purl = "#{flags[:purl]}/#{druid.id}"

  # OGP Solr document from GeoMetadataDS
  sfn = File.join(druid.temp_dir, 'ogpSolr.xml')
  FileUtils.rm_f(sfn) if File.exist?(sfn)
  cmd = ['xsltproc',
          "--stringparam geoserver_root '#{geoserver}'",
          "--stringparam purl '#{purl}'",
          "--output '#{sfn}'",
          "'#{File.expand_path(File.dirname(__FILE__) + '/../lib/geohydra/mods2ogp.xsl')}'",
          "'#{dfn}'"
          ].join(' ')
  puts "Generating #{sfn} using #{cmd}" if flags[:verbose]
  ap({:cmd => cmd}) if flags[:debug]
  system(cmd)

  sfn
end

def convert_geo2dc(geoMetadata, flags)
  # Solr document from GeoMetadataDS
  dcfn = File.join(druid.temp_dir, 'dc.xml')
  puts "Generating #{dcfn}" if flags[:verbose]
  File.open(dcfn, 'w') { |f| f << geoMetadata.to_dublin_core.to_xml(:indent => 2) }
  dcfn
end

def export_images(druid, uuid, flags)
  # export any thumbnail images
  %w{png jpg}.each do |fmt|
    Dir.glob("#{flags[:tmpdir]}/#{uuid}/{private,public}/*.#{fmt}") do |fn|
      ext = '.' + fmt
      tfn = File.basename(fn, ext)
      # convert _s to _small as per GeoNetwork convention
      tfn = tfn.gsub(/_s$/, '_small')
      imagefn = File.join(druid.content_dir, tfn + ext)
      FileUtils.install fn, imagefn, :verbose => flags[:debug]
      yield imagefn if block_given?
    end
  end
end

def export_local_images(druid, tempdir, flags)
  # export any thumbnail images
  %w{png jpg}.each do |fmt|
    Dir.glob("#{flags[:stagedir]}/#{druid.id}/content/*.#{fmt}") do |fn|
      imagefn = File.join(druid.content_dir, 'preview' + '.' + fmt)
      FileUtils.install fn, imagefn, :verbose => flags[:debug]
      yield imagefn if block_given?
    end
  end
end

def export_zip(druid, flags)
  # export content into zip files
  Dir.glob(File.join(flags[:stagedir], "#{druid.id}/content/data.zip")) do |fn|
    # extract shapefile name using filename pattern from
    # http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf
    ofn = "#{druid.content_dir}/data.zip"
    FileUtils.install fn, ofn, :verbose => flags[:verbose]
    yield ofn if block_given?
    
    if flags[:extract_basename]
      k = %r{([a-zA-Z0-9_-]+)\.(shp|tif)$}i.match(`unzip -l #{fn}`)[1]
      flags[:basename] = k
    end
  end
end

def doit(client, uuid, obj, flags)
  puts "Processing #{uuid}"
  druid = setup_druid(obj, flags)

  if flags[:geonetwork]
    puts "Processing #{uuid} from geonetwork" if flags[:debug]
    ifn = find_mef(druid, uuid, flags)
  else
    raise ArgumentError, druid if obj.content.empty?
    ifn = find_local(druid, obj.content.to_s, flags)
  end
  
  puts "Processing #{ifn}" if flags[:verbose]

  optfn = File.expand_path("#{flags[:stagedir]}/#{obj.druid}/temp/geoOptions.json")
  puts "Loading extra out-of-band options #{optfn}" if flags[:debug]
  if File.exist?(optfn)
    h = JSON.parse(File.read(optfn))
    flags = flags.merge(h).symbolize_keys
    ap({:optfn => optfn, :h => h, :flags => flags}) if flags[:debug]
  else
    puts "WARNING: #{obj.druid} is missing options .json parameters: #{optfn}"
    flags[:geometryType] ||= 'Polygon' # XXX: placeholder
  end

  gfn = convert_iso2geo(druid, ifn, obj.content, obj.fc, flags)
  geoMetadata = Dor::GeoMetadataDS.from_xml File.read(gfn)
  geoMetadata.geometryType = flags[:geometryType] || 'Polygon'
  geoMetadata.zipName = 'data.zip'
  geoMetadata.purl = File.join(flags[:purl], druid.id)

  dfn = convert_geo2mods(druid, geoMetadata, flags)
  sfn = convert_geo2solrspatial(druid, geoMetadata, flags)
  
  ofn = convert_mods2ogpsolr(druid, dfn, flags)
  
  if flags[:geonetwork]
    export_images(druid, uuid, flags)
  else
    export_local_images(druid, File.expand_path(File.dirname(obj.zipfn) + '/../temp'), flags)
  end
  
  export_zip(druid, flags)
end

def main(flags)
  File.umask(002)
  if flags[:geonetwork]
    client = GeoHydra::GeoNetwork.new
    client.each do |uuid|
      begin
        puts "Processing #{uuid}"
        obj = client.fetch(uuid)
        doit client, uuid, obj, flags
      rescue Exception => e
        $stderr.puts e
        $stderr.puts e.backtrace if flags[:debug]
      end
    end
  else
    puts "Searching for staged content..." if flags[:verbose]
    puts flags[:stagedir] + '/' + DruidTools::Druid.glob + '/content/data.zip'
    Dir.glob(flags[:stagedir] + '/' + DruidTools::Druid.glob + '/content/data.zip') do |zipfn|
      Dir.glob(File.join(File.dirname(zipfn), '..', 'temp', '*iso19139.xml')) do |xmlfn|
        druid = File.basename(File.dirname(File.dirname(zipfn)))
        obj = Struct.new(:content, :status, :druid, :zipfn, :fc).new(File.read(xmlfn), nil, druid, zipfn, File.read(xmlfn.gsub('.xml', '-fc.xml')))
        ap({:zipfn => zipfn, :obj => obj}) if flags[:debug]
        doit client, nil, obj, flags
      end
    end
  end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :geonetwork => false,
    :geoserver => GeoHydra::Config.ogp.geoserver,
    :stacks => GeoHydra::Config.ogp.stacks,
    :solr => GeoHydra::Config.ogp.solr,
    :purl => GeoHydra::Config.ogp.purl,
    :stagedir => GeoHydra::Config.geohydra.stage || 'stage',
    :xinclude => false,
    :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace',
    :tmpdir => GeoHydra::Config.geohydra.tmpdir || 'tmp'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options]
EOM
    opts.on('--geonetwork', 'Run against GeoNetwork server') do |v|
      flags[:geonetwork] = true
    end
    opts.on('-v', '--verbose', 'Run verbosely') do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on('--stagedir DIR', "Staging directory with ZIP files (default: #{flags[:stagedir]})") do |v|
      flags[:stagedir] = v
    end
    opts.on('--workspace DIR', "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
      flags[:workspacedir] = v
    end
    opts.on('--tmpdir DIR', "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |v|
      flags[:tmpdir] = v
    end
  end.parse!

  %w{tmpdir stagedir workspacedir}.each do |k|
    d = flags[k.to_sym]
    raise ArgumentError, "Missing directory #{d}" unless d.nil? or File.directory? d
  end

  ap({:flags => flags}) if flags[:debug]
  raise NotImplementError, 'geonetwork code is stale' if flags[:geonetwork]
  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
