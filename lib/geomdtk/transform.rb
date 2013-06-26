require 'base64'

module GeoMDTK
  # Facilitates XSLT stylesheet transformations for ISO 19139 import/export
  class Transform
    # XSLT file locations
    XSLT = {
      :rdf => File.join(File.dirname(__FILE__), 'rdf_bundle.xsl'),
      :arcgis => '/var/lib/tomcat6/webapps/geonetwork/xsl/conversion/import/ArcGIS2ISO19139.xsl', # pre-installed ~1MB
      :arcgis_fc => File.join(File.dirname(__FILE__), 'arcgis_to_iso19139_fc.xsl')
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
        system("#{XSLTPROC} #{XSLT[:arcgis]} '#{fn}' | #{XMLLINT} -o '#{ofn_fc}' -")
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
    def self.to_geoMetadataDS fn
      do_xslt XSLT[:rdf], fn
    end
    
    private
    def self.do_xslt xslt, fn
      IO::popen("#{XSLTPROC} #{xslt} #{fn} | #{XMLLINT} -", 'r') do |f|
        return Nokogiri::XML(f.read)
      end      
    end
    
    
  end
end