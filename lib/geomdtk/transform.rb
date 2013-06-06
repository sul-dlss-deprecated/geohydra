module GeoMDTK
  # Facilitates XSLT stylesheet transformations for ISO 19139 import/export
  module Transform
    # XSLT file locations
    XSLT = {
      :mods => File.join(File.dirname(__FILE__), 'iso19139_to_mods.xsl'),
      :arcgis => '/var/lib/tomcat6/webapps/geonetwork/xsl/conversion/import/ArcGIS2ISO19139.xsl', # pre-installed ~1MB
      :arcgis_fc => File.join(File.dirname(__FILE__), 'arcgis_to_iso19139_fc.xsl')
    }
    
    # XSLT processor
    XSLTPROC = 'xsltproc --novalid --xinclude'
    # XML cleaner
    XMLLINT = 'xmllint --format --xinclude --nsclean'
    
    # Converts a ISO 19139 into MODS v3
    # @param [String] geoMetadata Input data as ISO 19139 XML.
    # @param [Boolean] validate - if true, uses Nokogiri::XML to parse the geoMetadata before transforming
    # @return [Nokogiri::XML::Document] the MODS v3 metadata
    def self.to_mods geoMetadata, validate = false
      IO::popen("#{XSLTPROC} #{XSLT[:mods]} - | #{XMLLINT} -", 'w+') do |f|
        f << validate ? geoMetadata : Nokogiri::XML(geoMetadata).to_xml
        f.close_write
        return Nokogiri::XML(f.read)
      end
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
    
  end
end