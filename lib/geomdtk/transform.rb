require 'tempfile'

module GeoMDTK
  module Transform
    XSLT = {
      :mods => File.join(File.dirname(__FILE__), 'iso19139_to_mods.xsl')
    }
    
    def self.to_mods geoMetadata
      IO::popen(['xsltproc', XSLT[:mods], '-'].join(' '), 'w+') do |f|
        f << geoMetadata
        f.close_write
        return Nokogiri::XML(f.read)
      end
    end
  end
end