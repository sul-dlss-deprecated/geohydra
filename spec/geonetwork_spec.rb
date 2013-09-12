$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'

require 'geohydra'

describe GeoHydra::GeoNetwork do
  
  before(:each) do
    @client = GeoHydra::GeoNetwork.new
    @uuid_example = "FA6ED959-7DED-4722-B1FB-A85FB79725BA"
  end

  describe "#fetch" do
    it "verify identificationInfo" do
      %w{FA6ED959-7DED-4722-B1FB-A85FB79725BA}.each do |uuid|
        begin
          doc = @client.fetch(uuid).content
          fileId = doc.xpath('/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString/text()')
          fileId.to_s.should == uuid
          title = doc.xpath("/gmd:MD_Metadata/" + 
                    "gmd:identificationInfo/gmd:MD_DataIdentification/" + 
                    "gmd:citation/gmd:CI_Citation/" + 
                    "gmd:title/gco:CharacterString").text
          title.should == "Carbon Dioxide (CO2) Pipelines in the United States, 2011"
        rescue RestClient::Forbidden => e
          ap e
        end
        
      end
    end
    
    it "info" do
      ['site', 'users', 'groups', 'sources', 'operations'].each do |k|
        r = @client.info([k])
        r.keys.size.should == 1
        doc = Nokogiri::XML(r[k].to_s)
        doc.xpath("/info/#{k}").size.should > 0
      end
    end
    
    it "info groups" do
      @client.info(['groups']).each do |k, v|
        v.xpath('/info/groups/group').size.should > 0
        v.xpath('/info/groups/group/name/text()="all"').should == true
        g = v.xpath('/info/groups/group[./name/text()="all"]').first
        g['id'].to_i.should == 1
      end
    end
    
    it "info bad parameter" do
      expect { @client.info(%w{nonsense}) }.to raise_error(ArgumentError)
      expect { @client.info(%w{site groups nonsense}) }.to raise_error(ArgumentError)
    end
    
    it "search #each" do
      @client.each do |uuid|
        uuid.size.should == @uuid_example.size
        %r{^[-\da-fA-F]+$}.match(uuid.upcase).should_not == nil
      end
    end
  end
end
