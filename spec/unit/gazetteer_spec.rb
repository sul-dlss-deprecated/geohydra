# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

g = GeoHydra::Gazetteer.new
# ap({:g => g})

K2GEONAMESID = {
  'United States' => 6252001,
  'Chandīgarh' => 1274744,
  'Maharashtra (India)' => 1264418,
  'Chandni Chowk' => 6619404,
  'Adamour, Haryana (India)' => 7646705
}

K2LCSH = {
  'Earth' => 'Earth (Planet)',
  'United States' => 'United States',
  'Chandīgarh' => 'Chandīgarh (India : Union Territory)',
  'Maharashtra (India)' => 'Maharashtra (India)',
  'Chandni Chowk' => 'Chandni Chowk (Delhi, India)'
}

K2LCURI = {
  'Earth' => 'http://id.loc.gov/authorities/subjects/sh85040427',
  'United States' => 'http://id.loc.gov/authorities/names/n78095330',
  'Chandīgarh' => 'http://id.loc.gov/authorities/names/n81109268',
  'Maharashtra (India)' => 'http://id.loc.gov/authorities/names/n50000932',
  'Chandni Chowk' => 'http://id.loc.gov/authorities/names/no2004006256'
}


describe GeoHydra::Gazetteer do
  
  describe '#find_id' do
    it "nil case" do
      g.find_id(nil).should == nil      
      g.find_id('adsfadsfasdf').should == nil      
    end
    K2GEONAMESID.each do |k,id|
      it k do
        r = g.find_id(k)
        # ap({:k => k, :id => id, :r => r})
        r.should == id
      end
    end
  end
  
  describe '#find_loc_keyword' do
    it "nil case" do
      g.find_loc_keyword(nil).should == nil      
      g.find_loc_keyword('asdfasdfasdf').should == nil      
    end
    K2LCSH.each do |k,lcsh|
      it k do
        r = g.find_loc_keyword(k)
        r.should == lcsh
      end
    end
  end

  describe '#find_loc_uri' do
    it "nil case" do
      g.find_loc_uri(nil).should == nil      
      g.find_loc_uri('asdfasdfasdf').should == nil      
    end
    K2LCURI.each do |k,lcuri|
      it k do
        r = g.find_loc_uri(k)
        r.should == lcuri
      end
    end
  end
  
  
  describe '#find_loc_authority' do
    it "nil case" do
      g.find_loc_authority(nil).should == nil      
      g.find_loc_authority('asdfasdfasdf').should == nil      
    end
    K2LCURI.each do |k,lcuri|
      it k do
        uri = g.find_loc_uri(k)
        r = g.find_loc_authority(k)
        if uri.start_with?('http://id.loc.gov/authorities/subjects/sh')
          r.should == 'lcsh'
        else
          r.should == 'lcnaf'
        end
      end
    end
  end
  

  describe '#find_placename_uri' do
    it "nil case" do
      g.find_placename_uri(nil).should == nil      
      g.find_placename_uri('asdfasdfasdf').should == nil      
    end
    K2GEONAMESID.each do |k,id|
      it k do
        r = g.find_placename_uri(k)
        r.should == "http://sws.geonames.org/#{id}/"
      end
    end
  end
  
  describe '#find_keyword_by_id' do
    it "nil case" do
      g.find_keyword_by_id(nil).should == nil      
      g.find_keyword_by_id(-1).should == nil      
    end
    K2GEONAMESID.each do |k,id|
      it id do
        r = g.find_keyword_by_id(id)
        r.should == k
      end
    end
  end
  
  
end
