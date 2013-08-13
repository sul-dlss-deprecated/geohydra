require 'base64'
require 'rgeo'
require 'rgeo/shapefile'

module GeoMDTK
  # Facilitates XSLT stylesheet transformations for ISO 19139 import/export
  class Transform
    # XXX hardcoded paths
    def self.search_for_xsl(filename)
      path = %w{
        lib
        lib/geomdtk
        /usr/share/tomcat6/webapps/geonetwork/xsl/conversion/import
        /var/geonetwork/2.8.0/lib
        /opt/staging/s_gis_services
        }
      path.unshift(File.dirname(__FILE__))
      path.each do |d|
        fn = File.join(d, filename)
        if File.exist?(fn)
          return fn
        end
      end
      nil
    end
    
    # XSLT file locations
    XSLT = {
      :rdf        => self.search_for_xsl('rdf_bundle.xsl'),
      :arcgis     => self.search_for_xsl('ArcGIS2ISO19139.xsl'),
      :arcgis_fc  => self.search_for_xsl('arcgis_to_iso19139_fc.xsl')
    }
    
    # XSLT processor
    XSLTPROC = 'xsltproc --novalid --xinclude'
    # XML cleaner
    XMLLINT = 'xmllint --format --xinclude --nsclean'
    
    # Converts a ISO 19139 into MODS v3
    # @param [String] fn with data as ISO 19139 XML.
    # @return [Nokogiri::XML::Document] the MODS v3 metadata
    # @deprecated
    def self.to_mods fn
      doc = Dor::GeoMetadataDS.from_xml File.read(fn)
      doc.to_mods
    end
    
    # Converts an ESRI ArcCatalog metadata.xml into ISO 19139
    # @param [String] fn Input file
    # @param [String] ofn Output file
    # @param [String] ofn_fc Output file for the Feature Catalog (optional)
    def self.from_arcgis fn, ofn, ofn_fc = nil
      system("#{XSLTPROC} #{XSLT[:arcgis]} '#{fn}' | #{XMLLINT} -o '#{ofn}' -")
      unless ofn_fc.nil?
        system("#{XSLTPROC} #{XSLT[:arcgis_fc]} '#{fn}' | #{XMLLINT} -o '#{ofn_fc}' -")
      end
    end
    
    # @return [Hash]
    # @deprecated
    def self.to_solr fn
      doc = Dor::GeoMetadataDS.from_xml File.read(fn)
      doc.to_solr
    end
    
    # Extracts an inline thumbnail from the ESRI ArcCatalog metadata format
    # @param [String] fn the metadata
    # @param [String] thumbnail_fn the file into which to write JPEG image
    # @param [String] property_type is the EsriPropertyType to select
    # @raise [ArgumentError] if cannot find a thumbnail
    def self.extract_thumbnail fn, thumbnail_fn, property_type = 'PictureX'
      doc = Nokogiri::XML(File.read(fn))
      doc.xpath('/metadata/Binary/Thumbnail/Data').each do |node|
        if node['EsriPropertyType'] == property_type
          image = Base64.decode64(node.text)
          File.open(thumbnail_fn, 'wb') {|f| f << image }
          return
        end
      end
      raise ArgumentError, "No thumbnail embedded within #{fn}"
    end
    
    # Converts a ISO 19139 into RDF-bundled document geoMetadataDS
    # @param [String] fn Input data as ISO 19139 XML.
    # @return [Nokogiri::XML::Document] the geoMetadataDS with RDF
    def self.to_geoMetadataDS fn, flags
      do_xslt XSLT[:rdf], fn, flags
    end
    
    # @param zipfn [String] ZIP file
    def self.reproject druid, zipfn, flags
      k = File.basename(zipfn, '.zip')
      shpfn = k + '.shp'

      puts "Extracting #{druid.id} data from #{zipfn}" if flags[:verbose]
      tmp = "#{flags[:tmpdir]}/#{druid.id}"
      FileUtils.rm_rf tmp if File.directory? tmp
      FileUtils.mkdir_p tmp
      system("unzip -q -j '#{zipfn}' -d '#{tmp}'")

      [4326].each do |srid|
        ifn = File.join(tmp, shpfn)
        raise ArgumentError, "#{ifn} is missing" unless File.exist? ifn
        
        odr = File.join(flags[:tmpdir], 'EPSG_' + srid.to_s)
        ofn = File.join(odr, shpfn)
        puts "Projecting #{ifn} -> #{odr}/#{ofn}" if flags[:verbose]

        # reproject
        FileUtils.mkdir_p odr unless File.directory? odr
        system("ogr2ogr -progress -t_srs '#{flags[:wkt][srid.to_s]}' '#{ofn}' '#{ifn}'") 

        # normalize prj file
        if flags[:overwrite_prj] and not flags[:wkt][srid.to_s].nil?
          prj_fn = ofn.gsub(%r{\.shp}, '.prj')
          puts "Overwriting #{prj_fn}" if flags[:verbose]
          File.open(prj_fn, 'w') {|f| f.write(flags[:wkt][srid.to_s])}
        end

        # package up reprojection
         ozip = File.join(druid.content_dir, k + "_EPSG_#{srid}.zip")
        puts "Repacking #{ozip}" if flags[:verbose]
        system("zip -q -Dj '#{ozip}' #{odr}/#{File.basename(k, '.shp')}.*")

        # cleanup
        FileUtils.rm_rf odr
      end

      # cleanup
      FileUtils.rm_rf tmp
    end
    
    # @return RGeo::Feature::Point, 
    #         RGeo::Feature::Polygon, 
    #         RGeo::Feature::LineString as appropriate
    def self.geometry_type(shp_filename)
      RGeo::Shapefile::Reader.open(shp_filename) do |shp|
        shp.each do |record|
          return record.geometry.envelope.geometry_type
        end
      end
    end
    
    private
    def self.do_xslt xslt, fn, params = {}
      cmd = XSLTPROC
      params.each do |k,v|
        cmd += " --stringparam '#{k}' '#{v}'"
      end
      # ap({:cmd => cmd, :xslt => xslt})
      IO::popen("#{cmd} #{xslt} #{fn} | #{XMLLINT} -", 'r') do |f|
        return Nokogiri::XML(f.read)
      end      
    end
  end
end