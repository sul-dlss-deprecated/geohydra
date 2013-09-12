require 'fastimage'
require 'mime/types'
require 'nokogiri'

require 'dor-services'
require 'assembly-objectfile'

module GeoHydra
  class Accession
    FILE_ATTRIBUTES = Assembly::FILE_ATTRIBUTES.merge(
      'image/png' => Assembly::FILE_ATTRIBUTES['image/jp2'], # preview image
      'application/zip' => Assembly::FILE_ATTRIBUTES['default'] # data file
    )
  
    attr_reader :druid
    def initialize(druid)
      if druid.is_a? String
        druid = DruidTools::Druid.new(druid)
      end
      unless druid.is_a? DruidTools::Druid
        raise ArgumentError, "Invalid druid: #{druid}" 
      end
      @druid = druid
    end

    # @param [Array<Assembly::ObjectFile>] objects
    # @param [Nokogiri::XML::DocumentFragment] geoData
    # @param [Hash] flags
    # @return [Nokogiri::XML::Document]
    # @see [Assembly::ContentMetadata]
    # @see https://consul.stanford.edu/display/chimera/Content+metadata+--+the+contentMetadata+datastream
    #
    # Example:
    #
    #    <contentMetadata objectId="druid:ks297fy1411" type="file">
    #      <resource id="druid:ks297fy1411_1" sequence="1" type="main">
    #        <label>Data</label>
    #        <file preserve="yes" shelve="yes" publish="yes" id="OFFSH_BLOCKS.zip" mimetype="application/zip" size="2191447" role="master">
    #          <geoData srsName="EPSG:4269">
    #            <gml:Envelope xmlns:gml="http://www.opengis.net/gml/3.2" srsName="EPSG:4269">
    #              <gml:lowerCorner>-97.238989 23.780775</gml:lowerCorner>
    #              <gml:upperCorner>-81.170106 30.289096</gml:upperCorner>
    #            </gml:Envelope>
    #          </geoData>
    #          <checksum type="sha1">9a08212a815902ebcd14c83bc258bfd830e86b58</checksum>
    #          <checksum type="md5">a89191324c24ead1f1bc0fced4e0f75d</checksum>
    #        </file>
    #        <file preserve="no" shelve="yes" publish="yes" id="OFFSH_BLOCKS_EPSG_4326.zip" mimetype="application/zip" size="2003420" role="derivative">
    #          <geoData srsName="EPSG:4326"/>
    #          <checksum type="sha1">a860e8aa831e0f0011d2cd3ca8f75186b956f19d</checksum>
    #          <checksum type="md5">a6055a001f4f98cc6b8eb41e617417b3</checksum>
    #        </file>
    #      </resource>
    #      <resource id="druid:ks297fy1411_2" sequence="2" type="preview">
    #        <label>Preview</label>
    #        <file preserve="yes" shelve="yes" publish="yes" id="OFFSH_BLOCKS.png" mimetype="image/png" size="22927" role="master">
    #          <checksum type="sha1">9f16b1036a08dc722ff14cce16e04e75e6b4b7de</checksum>
    #          <checksum type="md5">e43fd14433cb37acbdd30cef3f4e150c</checksum>
    #          <imageData width="800" height="532"/>
    #        </file>
    #        <file preserve="no" shelve="yes" publish="yes" id="OFFSH_BLOCKS_small.png" mimetype="image/png" size="10906" role="derivative">
    #          <checksum type="sha1">1a62a926a46c16f11f43ec4c250b38b46980673b</checksum>
    #          <checksum type="md5">f17b9de6b290f56ac6e06f95a3686f7f</checksum>
    #          <imageData width="180" height="119"/>
    #        </file>
    #      </resource>
    #    </contentMetadata>
    def create_content_metadata(objects, geoData, flags)
      Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.contentMetadata(:objectId => "#{druid.druid}", :type => flags[:content_type] || 'file') do
          seq = 1
          objects.each do |k, v|
            next if v.nil? or v.empty?
            resource_type = case k 
              when :Data 
                :object
              when :Preview
                :preview
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

                  if resource_type == :object
                    if roletype == 'master' and not geoData.nil?
                      xml.geoData do
                        xml.parent.add_child geoData
                      end
                      geoData = nil # only once                  
                    else
                      if o.filename =~ %r{_EPSG_(\d+)\.zip}i
                        xml.geoData :srsName => "EPSG:#{$1}"
                      end
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
      end.doc.canonicalize
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

    def self.run(druid, flags = {})
      self.new(druid).accession(flags)
    end
    
    def accession(flags)
      ap({:flags => flags}) if flags[:debug]

      # validate parameters
      unless ['world','stanford','none', 'dark'].include? flags[:rights]
        raise ArgumentError, "Invalid rights: #{flags[:rights]}" 
      end

      # setup input metadata
      xml = File.read(@druid.find_metadata('geoMetadata.xml'))
      geoMetadata = Dor::GeoMetadataDS.from_xml(xml)
      ap({:geoMetadata => geoMetadata}) if flags[:debug]

      descMetadataXML = File.read(@druid.find_metadata('descMetadata.xml'))
      ap({:descMetadata => descMetadataXML}) if flags[:debug]

      # required parameters
      opts = {
          :object_type  => 'item',
          :label        => geoMetadata.title.first.to_s
      }

      # optional parameters
      opts.merge!({
        :pid              => @druid.druid, # druid:xx111xx1111
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
          item = Dor::Item.find(@druid.druid)
          $stderr.puts "Purging #{item.id}" if flags[:verbose]
          item.delete
          item = nil
        rescue ActiveFedora::ObjectNotFoundError => e
          # no object to delete
        end
      end

      begin
        # Load item
        item = Dor::Item.find(@druid.druid)
        # add collection when we don't use registration service
        unless opts[:collection].nil?
          item.add_collection(opts[:collection]) 
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        # Register item
        begin
          $stderr.puts "Registering #{opts[:pid]}" if flags[:verbose]
          item = Dor::RegistrationService.register_object opts
        rescue Dor::DuplicateIdError => e
          $stderr.puts "ABORT: #{@druid.druid} is corrupt (registered but Dor::Item cannot locate)"
          $stderr.puts "#{e.class}: #{e}"
          return nil
        end
      end

      # verify that we found the item
      raise ArgumentError, "#{@druid.druid} not found" if item.nil? 

      # now item is registered, so generate mods
      $stderr.puts "Assigning GeoMetadata for #{item.id}" if flags[:verbose]
      item.datastreams['geoMetadata'].content = geoMetadata.ng_xml.to_xml
      item.datastreams['descMetadata'].content = descMetadataXML
      ap({:descMetadata => item.datastreams['descMetadata']}) if flags[:debug]

      # upload data files to contentMetadata if required
      if flags[:contentMetadata]
        objects = {
          :Data => [],
          :Preview => [],
          :Metadata => []
        }

        # Process files
        objects.keys.each do |k|
          Dir.glob(@druid.content_dir + '/' + PATTERNS[k]).each do |fn|
            ap({:content_fn => fn}) if flags[:debug]
            objects[k] << Assembly::ObjectFile.new(fn, :label => k.to_s)
          end
        end
        ap({:content_metadata_objects => objects}) if flags[:debug]

        # extract the MODS extension cleanly
        doc = item.datastreams['descMetadata'].ng_xml
        ns = {}
        doc.collect_namespaces.each do |k, v|
          if k =~ %r{^xmlns:(.*)}i
            ns[$1] = v 
          else
            ns['mods'] = v
          end
        end
        geoData = item.datastreams['descMetadata'].ng_xml.xpath('//mods:extension[@rdf:type="geo"]/rdf:RDF/rdf:Description[@rdf:type="geo#boundingBox"]/*', ns).first
        ap({:geoData => geoData, :geoDataClass => geoData.class}) if flags[:debug]

        # Create the contentMetadata
        $stderr.puts "Creating content..." if flags[:verbose]
        xml = create_content_metadata objects, geoData, flags
        item.datastreams['contentMetadata'].content = xml
        ap({:contentMetadataDS => item.datastreams['contentMetadata'].ng_xml}) if flags[:debug]

        if flags[:shelve]
          $stderr.puts "Shelving to stacks content..." if flags[:verbose]
          files = []
          item.datastreams['contentMetadata'].public_xml.xpath('//file').each do |f|
            files << f['id'].to_s
          end
          ap({ :id => @druid.druid, :files => files }) if flags[:debug]
        
          Dor::DigitalStacksService.shelve_to_stacks @druid.druid, files
        end
      end

      # save changes
      $stderr.puts "Saving #{item.id}" if flags[:verbose]
      item.save

      ap({ :files => item.list_files}) if flags[:debug]
    end
  
  end
end