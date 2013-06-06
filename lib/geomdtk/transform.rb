require 'tempfile'

module GeoMDTK
  module Transform
    XSLT = {
      :mods => File.join(File.dirname(__FILE__), 'iso19139_to_mods.xsl'),
      :arcgis => '/var/lib/tomcat6/webapps/geonetwork/xsl/conversion/import/ArcGIS2ISO19139.xsl', # pre-installed ~1MB
      :arcgis_fc => File.join(File.dirname(__FILE__), 'arcgis_to_iso19139_fc.xsl')
    }
    
    def self.to_mods geoMetadata
      IO::popen(['xsltproc', XSLT[:mods], '-'].join(' '), 'w+') do |f|
        f << geoMetadata
        f.close_write
        return Nokogiri::XML(f.read)
      end
    end
    
    # Converts an ESRI ArcCatalog metadata.xml into ISO 19139
    def self.from_arcgis fn, ofn
      system("xsltproc --novalid --xinclude #{XSLT[:arcgis]} '#{fn}' | xmllint --xinclude --format -o '#{ofn}' -")
      ofn = File.join(File.dirname(ofn), File.basename(ofn, '.xml') + '_FC.xml')
      system("xsltproc --novalid --xinclude #{XSLT[:arcgis_fc]} '#{fn}' | xmllint --xinclude --format -o '#{ofn}' -")
    end

  end
end