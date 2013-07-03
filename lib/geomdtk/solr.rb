# encoding: UTF-8

require 'dor-services'
require 'rsolr'

module GeoMDTK
  # API for uploading Solr documents
  class Solr

    # @param [String] url to solr server
    def initialize(url)
      @solr = url.nil? ? nil : RSolr.connect(:url => url)
      ap @solr
      @geo_metadata = []
    end

    def add(xml)
      if xml.is_a? Dor::GeoMetadataDS
        @geo_metadata << xml
      else
        @geo_metadata << Dor::GeoMetadataDS.from_xml(xml)
      end
    end

    def upload(optimize = false)
      @geo_metadata.each do |ds|
        puts "Uploading #{ds.title}"
        @solr.add ds.to_solr
      end
      commit
      @solr.optimize if optimize
    end

    def reset
      @geo_metadata = []
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
