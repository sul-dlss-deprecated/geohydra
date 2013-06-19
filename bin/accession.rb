#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'fastimage'
require 'druid-tools'
require 'assembly-objectfile'
require 'geomdtk'

VERSION = '0.1'
FILE_ATTRIBUTES = Assembly::FILE_ATTRIBUTES.merge(
  'image/png' => Assembly::FILE_ATTRIBUTES['image/jp2'], # preview image
  'application/zip' => Assembly::FILE_ATTRIBUTES['default'] # data file
)

# @see [Assembly::ContentMetadata]
# @return [Nokogiri::XML::Document]
#
# Example:
# <contentMetadata objectId="druid:zz943vx1492" type="file">
#   <resource id="druid:zz943vx1492_1" sequence="1" type="application">
#     <label>Data</label>
#     <file preserve="yes" shelve="no" publish="no" id="BASINS.zip" mimetype="application/zip" size="490949">
#       <checksum type="sha1">11b1e1f7461aa628a4df01a54e5667b385ad27cf</checksum>
#       <checksum type="md5">b9f1179bf4182f2b8c7aed87b23777f9</checksum>
#     </file>
#   </resource>
#   <resource id="druid:zz943vx1492_2" sequence="2" type="image">
#     <label>Preview Image</label>
#     <file preserve="no" shelve="yes" publish="yes" id="BASINS.png" mimetype="image/png" size="14623">
#       <checksum type="sha1">3c0b832ab6bd3c824e02bef6e24fed1cc0cb8888</checksum>
#       <checksum type="md5">5c056296472c081e80742fc2240369ef</checksum>
#       <imageData width="800" height="532"/>
#     </file>
#   </resource>
#   <resource id="druid:zz943vx1492_3" sequence="3" type="image">
#     <label>Preview Image</label>
#     <file preserve="no" shelve="yes" publish="yes" id="BASINS_small.png" mimetype="image/png" size="7631">
#       <checksum type="sha1">29752a2fb811d0eb7a07643b46c5734b734ed1cb</checksum>
#       <checksum type="md5">a456e246b988c7571f9b1cf3947460bd</checksum>
#       <imageData width="180" height="119"/>
#     </file>
#   </resource>
# </contentMetadata>
def create_content_metadata druid, objects, content_type = :image
  Nokogiri::XML::Builder.new do |xml|
    xml.contentMetadata(:objectId => "#{druid}",:type => content_type) do
      seq = 1
      objects.each do |o|
        ap({
          :ext => o.ext,
          :image => o.image?,
          :size => o.filesize,
          :md5 => o.md5,
          :sha1 => o.sha1,
          :jp2able => o.jp2able?,
          :mime => o.mimetype,
          :otype => o.object_type,
          :exist => o.file_exists?,
          :exif => o.exif,
          :label => o.label,
          :file_attributes => o.file_attributes,
          :path => o.path,
          :imagesize => FastImage.size(o.path),
          :imagetype => FastImage.type(o.path)
        })
        xml.resource(
          :id => "#{druid}_#{seq}",
          :sequence => seq,
          :type => o.object_type == :application ? :object : o.object_type
        ) do
          o.file_attributes ||= FILE_ATTRIBUTES[o.mimetype] || FILE_ATTRIBUTES['default']
          xml.label o.label
          xml.file  o.file_attributes.merge(
                    :id => o.filename,
                    :mimetype => o.mimetype, 
                    :size => o.filesize) do
            xml.checksum(o.sha1, :type => 'sha1')
            xml.checksum(o.md5, :type => 'md5')
            if o.image?
              img = FastImage.size(o.path)
              xml.imageData :width => img[0], :height => img[1]
            end
          end
        end
        seq += 1
      end
    end
  end.doc
end

def do_upload fn, label, flags
  if (File.size(fn).to_f/2**20) < flags[:upload_max]
    $stderr.puts "Uploading content #{fn}" if flags[:verbose]
    Assembly::ObjectFile.new(fn, :label => label)        
  else
    $stderr.puts "Skipping content #{fn}" if flags[:verbose]
    nil
  end
end

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
  
  begin
    # Load item
    item = Dor::Item.find(druid.druid)
  rescue ActiveFedora::ObjectNotFoundError => e
    # Register item
    begin
      $stderr.puts "Registering #{opts[:pid]}" if flags[:verbose]
      item = Dor::RegistrationService.register_object opts
    rescue Dor::DuplicateIdError => e
      $stderr.puts "ABORT: #{druid.druid} is corrupt (registered but Dor::Item cannot locate)"
      $stderr.puts "#{e.class}: #{e}"
      return nil
    end
  end
  
  # verify that we found the item
  return nil if item.nil? 
  
  # now item is registered, so generate mods
  $stderr.puts "Assigning GeoMetadata for #{item.id}" if flags[:verbose]
  item.datastreams['geoMetadata'].content = geoMetadata.ng_xml.to_xml
  item.datastreams['descMetadata'].content = item.generate_mods.to_xml

  # upload data files to contentMetadata if required
  if flags[:upload]
    objects = []
    
    # Locate data files
    Dir.glob("#{druid.content_dir}/*.zip").each do |fn|
      objects << do_upload(fn, 'Data', flags)
    end
    
    # Locate preview images
    Dir.glob("#{druid.content_dir}/*.{png,jpg,gif}").each do |fn|
      objects << do_upload(fn, 'Preview Image', flags)
    end

    # Locate other files
    Dir.glob("#{druid.content_dir}/*.{xml,txt}").each do |fn|
      objects << do_upload(fn, 'Metadata', flags)
    end

    # Cleanup
    objects = objects.select {|x| not x.nil?}
    
    xml = create_content_metadata opts[:pid], objects
    item.datastreams['contentMetadata'].content = xml.to_xml
  end
  
  # save changes
  $stderr.puts "Saving #{item.id}" if flags[:verbose]
  item.save
  item 
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:cb854wz7157',
    :rights => 'stanford',
    :tags => [],
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp',
    :verbose => false,
    :configtest => false,
    :purge => false,
    :upload => false,
    :upload_max => 10, # in Megabytes
    :workspacedir => GeoMDTK::Config.geomdtk.workspace || 'workspace'
  }
  
  OptionParser.new do |opts|
    opts.version = VERSION
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [druid [druid...]]
EOM
    opts.on("--apo DRUID", "APO for collection to accession (default: #{flags[:admin_policy]})") do |druid|
      flags[:admin_policy] = DruidTools::Druid.new(druid).druid
    end
    opts.on("--collection DRUID", "Collection for accession (default: #{flags[:collection]})") do |druid|
      flags[:collection] = DruidTools::Druid.new(druid).druid
    end
    opts.on("--purge", "--no-purge", "Purge items before accessioning (default: #{flags[:purge]})") do |b|
      flags[:purge] = b
    end
    opts.on("-q", "--quiet", "Run quietly (default: #{not flags[:verbose]})") do
      flags[:verbose] = false
    end
    opts.on("--rights KEYWORD", "Rights keyword (default: #{flags[:rights]})") do |keyword|
      flags[:rights] = keyword
    end
    opts.on("--tag TAG", "Tag for each object - multiple tags allowed") do |tag|
      flags[:tags] << tag
    end
    opts.on("--test", "Verify configuration then exit (default: #{flags[:configtest]})") do 
      flags[:configtest] = true
    end
    opts.on("--tmpdir DIR", "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |d|
      flags[:tmpdir] = d
    end
    opts.on("--upload [MB]", "Upload content files less than maximum MB (default: #{flags[:upload]}; #{flags[:upload_max]} MB max)") do |mb|
      flags[:upload] = true
      flags[:upload_max] = mb.to_f unless mb.nil?
    end
    opts.on("-v", "--verbose", "Run verbosely (default: #{flags[:verbose]})") do 
      flags[:verbose] = true
    end
    opts.on("--workspace DIR", "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |d|
      flags[:workspacedir] = d
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
