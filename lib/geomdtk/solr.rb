require 'dor-services'
require 'rsolr'

module GeoMDTK
  class Solr
    
    # @param [String] url to solr server
    def initialize url
      @solr = RSolr.connect :url => url
      ap @solr
      @geoMetadata = []
    end
    
    def add xml
      if xml.is_a? Dor::GeoMetadataDS
        @geoMetadata << xml
      else
        @geoMetadata << Dor::GeoMetadataDS.from_xml(xml)
      end
    end
    
    def upload optimize = false
      @geoMetadata.each do |ds|
        puts "Uploading #{ds.title}"
        @solr.add ds.to_solr
      end
      commit
      @solr.optimize if optimize
    end
    
    def reset
      @geoMetadata = []
    end
    
    def commit
      @solr.commit
    end
    
    def delete_all
      @solr.delete_by_query '*:*'
      commit
    end
  end
end
