require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

describe GeoHydra::Solr do
  
  POINT = /^POINT\([-\s\d\.]+\)/i # no commas
  POLYGON = /^POLYGON\(\([-\s\d\.,]+\)\)/i
  
  before(:each) do
    @solr = GeoHydra::Solr.new 'http://localhost:8983/solr'
    @xml = {}
    @docs = {}
    Dir.glob('spec/fixtures/*_geoMetadata.xml') do |fn|
      @xml[fn] = Nokogiri::XML(File.read(fn)).to_xml
      @docs[fn] = Dor::GeoMetadataDS.from_xml(@xml[fn])
    end
  end
  
  describe "#to_solr" do
    it "#convert" do
      @docs.each do |k, geoMetadata|
        # ap({:k => k, :geoMetadata => geoMetadata, :to_solr => geoMetadata.to_solr_spatial})
        doc = geoMetadata.to_solr_spatial
        doc["format_s"].should == ["Shapefile"]
        doc["format_s"].should == ["Shapefile"]
        doc["dc_language_s"].should == ["eng"]
        %w{geo_pt geo_sw_pt geo_ne_pt}.each do |pt|
          doc[pt].each do |s|
            ap({:match => POINT.match(s), :s => s, :re => POINT})
            POINT.match(s).nil?.should == false
          end
        end
        POLYGON.match(doc["geo_bbox"].first).nil?.should == false
      end
    end
  end
  
  describe "#solr.add" do
    it "upload" do
      @docs.each do |k, geoMetadata|
        @solr.add geoMetadata
      end
      @solr.upload
    end
  end
end
