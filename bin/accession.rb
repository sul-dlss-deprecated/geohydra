#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'geomdtk'


def doit druid
  xml = File.read(druid.path('metadata/geoMetadata.xml'))
  # ap xml
  ds = Dor::GeoMetadataDS.from_xml(xml)
  ap ds
  opts = {
      :object_type  => 'item',
      :admin_policy => 'druid:cb854wz7157',
      :source_id    => { 'geomdtk' => ds.file_id.first },
      :tags         => ["Project : GIS"],
      :pid          => druid.druid,
      :label        => ds.title.first
    }
    ap opts
end

def main flags
  Dir.glob("#{flags[:workspacedir]}/**/geoMetadata.xml") do |fn|
    puts fn
    pid = %r{/([a-z0-9]+)/metadata/geoMetadata.xml}.match(fn)[1]
    druid = DruidTools::Druid.new(pid, flags[:workspacedir])
    doit druid
  end
  return
  r = Dor::RegistrationService.register_object params
  
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
    %w{metadata.iso19139.xml metadata.xml}.each do |fn| # priority order
      unless found_metadata
        fn = File.join(flags[:tmpdir], fn)
        next unless File.exist? fn
      
        found_metadata = true
        
        # original ISO 19139
        ifn = File.join(druid.temp_dir, 'iso19139.xml')
        puts "Copying #{fn} => #{ifn}"
        FileUtils.install fn, ifn
        File.delete fn

        # GeoMetadataDS
        gfn = File.join(druid.metadata_dir, 'geoMetadata.xml')
        puts "Generating #{gfn}"      
        File.open(gfn, "w") do |f|
          f << GeoMDTK::Transform.to_geoMetadataDS(ifn)
        end
      
        # MODS from GeoMetadataDS
        dfn = File.join(druid.metadata_dir, 'descMetadata.xml')
        puts "Generating #{dfn}"      
        File.open(dfn, "w") do |f|
          f << GeoMDTK::Transform.to_mods(gfn)
        end
      
        # Solr document from GeoMetadataDS
        sfn = File.join(druid.temp_dir, 'solr.xml')
        puts "Generating #{sfn}"
        h = GeoMDTK::Transform.to_solr(gfn)
        doc = Nokogiri::XML::Builder.new do |xml|
          xml.add {
            xml.doc_ {
              h.keys.each do |k|
                h[k].each do |v|
                  xml.field v, :name => k
                end
              end
            }
          }
        end
        File.open(sfn, "w") { |f| f << doc.to_xml }
      end
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
