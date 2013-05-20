require 'rubygems'
require 'nokogiri'
require 'dor-services'
require "awesome_print"
require 'open-uri'

module GeoMDTK
  class Validate
    cattr_reader :SCHEMA_FN
    SCHEMA_FN = File.dirname(__FILE__) + '/schemas/iso19139/schema.xsd'
    
    def initialize
      @template = Dor::GeoMetadataDS.xml_template
    end
    
    def validate(fn)
      doc = Nokogiri::XML(open(fn))
      xsd = Nokogiri::XML::Schema(open(SCHEMA_FN))
      ap xsd
      
      # ap doc.class
      # ap doc.root.namespace_definitions
      # ap doc.path
      # ap doc.root.class
      # ap @template.root
      # ap @template.root.attributes
      # ap @template.root.attribute('xsi:schemaLocation')
      # ap @template.root['xsi:schemaLocation']
      # Dor::GeoMetadataDS::NS.each do |k,v|
      #   uri = "#{v}/#{k}.xsd"
      #   ap uri
      #   # ap xsd
      #   # xsd.validate(doc).each do |error|
      #   #   ap error.message
      #   # end
      # end
      # nil
    end
  end
end