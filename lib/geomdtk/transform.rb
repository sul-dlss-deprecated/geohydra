module GeoMDTK
  # Facilitates XSLT stylesheet transformations for ISO 19139 import/export
  module Transform
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
    # @param [String] file with data as ISO 19139 XML.
    # @return [Nokogiri::XML::Document] the MODS v3 metadata
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
    def self.to_solr fn
      doc = Dor::GeoMetadataDS.from_xml File.read(fn)
      doc.to_solr
    end
    
    
    # Converts a ISO 19139 into RDF geoMetadataDS
    # @param [String] geoMetadata Input data as ISO 19139 XML.
    # @param [Boolean] validate - if true, uses Nokogiri::XML to parse the geoMetadata before transforming
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