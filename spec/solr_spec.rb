require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geomdtk'

describe GeoMDTK::Solr do
  
  DIGITS2_comma = %r{^\s*[+-]*(\d)+(\.)*(\d)*\s*,\s*[+-]*(\d)+(\.)*(\d)*\s*$}
  DIGITS4 = %r{^\s*[+-]*(\d)+(\.)*(\d)*\s+[+-]*(\d)+(\.)*(\d)*\s+[+-]*(\d)+(\.)*(\d)*\s+[+-]*(\d)+(\.)*(\d)*\s*$}
  
  before(:each) do
    @solr = GeoMDTK::Solr.new 'http://localhost:8080/solr/dlss-dev-drh-geo-jun6'
    @xml = {}
    @docs = {}
    Dir.glob('spec/fixtures/*_geoMetadata.xml') do |fn|
      @xml[fn] = Nokogiri::XML(File.read(fn)).to_xml
      @docs[fn] = Dor::GeoMetadataDS.from_xml(@xml[fn])
    end
  end
  
  describe "#to_solr" do
    it "#convert" do
      @docs.each do |k,geoMetadata|
        doc = geoMetadata.to_solr
        ap doc
        doc["format_s"].should == ["Shapefile"]
        doc["language_s"].should == ["eng"]
        DIGITS2_comma.match(doc["geo_point"].first).nil?.should == false
        DIGITS2_comma.match(doc["geo_location"].first).nil?.should == false
        DIGITS4.match(doc["geo_bbox"].first).nil?.should == false
      end
    end
  end
  
  describe "#solr.add" do
    it "upload" do
      @docs.each do |k,geoMetadata|
        @solr.add geoMetadata
      end
      @solr.upload
    end
  end
end
