#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'fastimage'
require 'mime/types'
require 'druid-tools'
require 'assembly-objectfile'
require 'geomdtk'

VERSION = '0.1'

class Accession
  FILE_ATTRIBUTES = Assembly::FILE_ATTRIBUTES.merge(
    'image/png' => Assembly::FILE_ATTRIBUTES['image/jp2'], # preview image
    'application/zip' => Assembly::FILE_ATTRIBUTES['default'] # data file
  )
  
  attr_reader :druid
  def initialize druid
    @druid = druid
  end


  # @param [String] druid
  # @param [Array<Assembly::ObjectFile>] objects
  # @param [Hash] flags
  # @return [Nokogiri::XML::Document]
  # @see [Assembly::ContentMetadata]
  # @see https://consul.stanford.edu/display/chimera/Content+metadata+--+the+contentMetadata+datastream
  #
  # Example:
  #
  #    <?xml version="1.0" encoding="UTF-8"?>
  #    <contentMetadata objectId="druid:zz943vx1492" type="dataset">
  #      <resource id="druid:zz943vx1492_1" sequence="1" type="main">
  #        <label>Data</label>
  #        <file preserve="yes" shelve="yes" publish="yes" id="BASINS.zip" mimetype="application/zip" size="490949" role="master">
  #          <geoData>
  #            <gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2" srsName="EPSG:4269">
  #              <gml:lowerCorner>-164.196401 16.709076</gml:lowerCorner>
  #              <gml:upperCorner>-44.096585 77.614132</gml:upperCorner>
  #            </gml:Envelope>
  #          </geoData>
  #          <checksum type="sha1">11b1e1f7461aa628a4df01a54e5667b385ad27cf</checksum>
  #          <checksum type="md5">b9f1179bf4182f2b8c7aed87b23777f9</checksum>
  #        </file>
  #      </resource>
  #      <resource id="druid:zz943vx1492_2" sequence="2" type="supplement">
  #        <label>Preview</label>
  #        <file preserve="yes" shelve="yes" publish="yes" id="BASINS.png" mimetype="image/png" size="14623" role="master">
  #          <checksum type="sha1">3c0b832ab6bd3c824e02bef6e24fed1cc0cb8888</checksum>
  #          <checksum type="md5">5c056296472c081e80742fc2240369ef</checksum>
  #          <imageData width="800" height="532"/>
  #        </file>
  #        <file preserve="no" shelve="yes" publish="yes" id="BASINS_small.png" mimetype="image/png" size="7631" role="derivative">
  #          <checksum type="sha1">29752a2fb811d0eb7a07643b46c5734b734ed1cb</checksum>
  #          <checksum type="md5">a456e246b988c7571f9b1cf3947460bd</checksum>
  #          <imageData width="180" height="119"/>
  #        </file>
  #      </resource>
  #    </contentMetadata>

  def create_content_metadata objects, geoData = nil, flags = {}
    Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.contentMetadata(:objectId => "#{druid.druid}", :type => flags[:content_type] || 'dataset') do
        seq = 1
        objects.each do |k, v|
          next if v.nil? or v.empty?
          resource_type = case k 
            when :Data 
              :main
            when :Preview
              :supplement 
            else 
              :attachment
            end
          xml.resource(
            :id => "#{druid.druid}_#{seq}",
            :sequence => seq,
            :type => resource_type
          ) do
            xml.label k.to_s
            v.each do |o|
              raise ArgumentError unless o.is_a? Assembly::ObjectFile

              ap({
                :k => k,
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
                :image_size => FastImage.size(o.path),
                :image_type => FastImage.type(o.path),
                :image_mimetype => MIME::Types.type_for("xxx.#{FastImage.type(o.path)}").first
              }) if flags[:debug]
              
              mimetype = o.image?? MIME::Types.type_for("xxx.#{FastImage.type(o.path)}").first.to_s : o.mimetype
              o.file_attributes ||= FILE_ATTRIBUTES[mimetype] || FILE_ATTRIBUTES['default']
              [:publish, :shelve].each {|t| o.file_attributes[t] = 'yes'}
              
              roletype = if mimetype == 'application/zip'
                           if o.path =~ %r{_(EPSG_\d+)}i # derivative
                             'derivative'
                           else
                             'master'
                           end
                         elsif o.image?
                             if o.path =~ %r{_small.png$}
                               'derivative'
                             else
                               'master'
                             end
                         end || nil
              
              case roletype
              when 'master'
                o.file_attributes[:preserve] = 'yes'
              else
                o.file_attributes[:preserve] = 'no'
              end
                            
              xml.file o.file_attributes.merge(
                         :id => o.filename,
                         :mimetype => mimetype, 
                         :size => o.filesize,
                         :role => roletype || 'master') do

                if resource_type == :main
                  if geoData and roletype == 'master'
                    xml.geoData :srsName => geoData['srsName'] do 
                      xml.__send__ :insert, geoData
                      geoData = nil # only once                  
                    end
                  else
                    xml.geoData :srsName => 'EPSG:4236'
                  end
                end
                xml.checksum(o.sha1, :type => 'sha1')
                xml.checksum(o.md5, :type => 'md5')
                if o.image?
                  wh = FastImage.size(o.path)
                  xml.imageData :width => wh[0], :height => wh[1]
                end
              end
            end
            seq += 1
          end
        end
      end
    end.doc
  end

  def each_upload fn, label, flags
    if (File.size(fn).to_f/2**20) < flags[:upload_max]
      $stderr.puts "Uploading content #{fn}" if flags[:verbose]
      yield Assembly::ObjectFile.new(fn, :label => label)        
    else
      $stderr.puts "Skipping content #{fn}" if flags[:verbose]
    end
  end

  PATTERNS = {
    :Data => '*.zip',
    :Preview => '*.{png,jpg,gif}',
    :Metadata => '*.{xml,txt}'
  }

  def run flags = {}
    # validate parameters
    unless druid.is_a? DruidTools::Druid
      raise ArgumentError, "Invalid druid: #{druid}" 
    end
    unless ['world','stanford','none', 'dark'].include? flags[:rights]
      raise ArgumentError, "Invalid rights: #{flags[:rights]}" 
    end

    # setup input metadata
    xml = File.read(druid.find_metadata('geoMetadata.xml'))
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
      :tags             => []
    })

    # copy other optional parameters from input flags
    [:admin_policy, :collection, :rights].each do |k|
      opts[k] = flags[k] unless flags[k].nil?
    end
    unless flags[:tags].nil?
      flags[:tags].each { |t| opts[:tags] << t } 
    end

    ap({:item_options => opts}) if flags[:debug]

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
      objects = {
        :Data => [],
        :Preview => [],
        :Metadata => []
      }

      # Process files
      objects.keys.each do |k|
        Dir.glob(druid.content_dir + '/' + PATTERNS[k]).each do |fn|
          each_upload(fn, k.to_s, flags) {|o| objects[k] << o }
        end
      end
      ap({:content_metadata_objects => objects}) if flags[:debug]

      geoData = item.datastreams['descMetadata'].ng_xml.xpath('//mods:extension/rdf:RDF/rdf:Description[starts-with(@rdf:about, "geo")]/*', 
        'xmlns:mods' => 'http://www.loc.gov/mods/v3',
        'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').first
      ap({:geoData => geoData}) if flags[:debug]

      $stderr.puts "Creating content..." if flags[:verbose]
      xml = create_content_metadata objects, geoData, flags
      item.datastreams['contentMetadata'].content = xml.to_xml
      ap({
        :content_metadata => xml, 
        :contentMetadataDS => item.datastreams['contentMetadata'],
        :contentMetadataDS_public_xml => item.datastreams['contentMetadata'].public_xml
      }) if flags[:debug]

      $stderr.puts "Shelving to stacks content..." if flags[:verbose]
      files = []
      item.datastreams['contentMetadata'].public_xml.xpath('//file').each do |f|
        files << f['id'].to_s
      end
      ap({ :id => druid.druid, :files => files }) if flags[:debug]
      Dor::DigitalStacksService.shelve_to_stacks druid.druid, files
    end

    # save changes
    $stderr.puts "Saving #{item.id}" if flags[:verbose]
    item.save

    ap({ :files => item.list_files}) if flags[:debug]
  end
  
end

# __MAIN__
begin
  File.umask(002)
  flags = {
    :admin_policy => 'druid:cb854wz7157',
    :rights => 'stanford',
    :tags => [
      "Registered With : GeoMDTK",
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
    opts.on("--apo DRUID", "APO for collection to accession" + (flags[:admin_policy] ? " (default: #{flags[:admin_policy]})" : '')) do |druid|
      flags[:admin_policy] = DruidTools::Druid.new(druid).druid
    end
    opts.on("--collection DRUID", "Collection for accession" + (flags[:collection] ? " (default: #{flags[:collection]})" : '')) do |druid|
      flags[:collection] = DruidTools::Druid.new(druid).druid
    end
    opts.on("--purge", "Purge items before accessioning") do |b|
      flags[:purge] = true
    end
    opts.on("-q", "--quiet", "Run quietly") do
      flags[:verbose] = false
    end
    opts.on("--rights KEYWORD", "Rights keyword (default: #{flags[:rights]})") do |keyword|
      flags[:rights] = keyword
    end
    opts.on("--tag TAG", "Tag for each object - multiple tags allowed") do |tag|
      flags[:tags] << tag
    end
    opts.on("--test", "Verify configuration then exit") do 
      flags[:configtest] = true
    end
    opts.on("--tmpdir DIR", "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |d|
      flags[:tmpdir] = d
    end
    opts.on("--upload[=MAX]", "Upload content files -- MAX restricts to files smaller than MAX MB") do |mb|
      flags[:upload] = true
      flags[:upload_max] = (mb.to_f < 0 ? Float::INFINITY : mb.to_f) unless mb.nil?
    end
    opts.on("-v", "--verbose", "Run verbosely, use multiple times for debug level output") do 
      flags[:debug] = true if flags[:verbose]  # -vv
      flags[:verbose] = true
    end
    opts.on("--workspace DIR", "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |d|
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
        Accession.new(druid).run flags
      end
    end
  else
    ARGV.each do |pid|
      druid = DruidTools::Druid.new(pid, flags[:workspacedir])
      Accession.new(druid).run flags
    end
  end
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  $stderr.puts e.backtrace
  exit(-1)
end
