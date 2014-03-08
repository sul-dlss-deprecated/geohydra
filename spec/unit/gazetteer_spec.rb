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
  'United States' => 6252001,                     # simple
  'Chandīgarh' => 1274744,                        # with UTF8
  'Maharashtra (India)' => 1264418,               # without UTF8
  'Chandni Chowk' => 6619404,                     # same as placename
  'Jāt' => 1269155,                               # same as placename with UTF8
  'Adamour, Haryana (India)' => 7646705,          # with qualifier
  'Bhīlwāra (India : District)' => 1275961,       # with UTF8 and qualifier
  'Anand District, Gujarāt (India)' => 7627221,   # UTF8 in qualifier
  'Ratnagiri District, Maharashtra (India)' => 1258340 # with qualifier and UTF8 in LCNAF
}

K2PLACENAME = {
  'United States' => 'United States',
  'Chandīgarh' => 'Chandīgarh',
  'Maharashtra (India)' => 'Mahārāshtra',
  'Chandni Chowk' => 'Chandni Chowk',
  'Jāt' => 'Jāt',
  'Adamour, Haryana (India)' => 'Adampur',
  'Bhīlwāra (India : District)' => 'Bhīlwāra',
  'Anand District, Gujarāt (India)' => 'Anand',
  'Ratnagiri District, Maharashtra (India)' => 'Ratnagiri District'
}

K2LCSH = {
  'Earth' => 'Earth (Planet)',
  'United States' => 'United States',
  'Chandīgarh' => 'Chandīgarh (India : Union Territory)',
  'Maharashtra (India)' => 'Maharashtra (India)',
  'Chandni Chowk' => 'Chandni Chowk (Delhi, India)',
  'Jāt' => nil,
  'Bhīlwāra (India : District)' => 'Bhīlwāra (India : District)',
  'Anand District, Gujarāt (India)' => 'Anand (India : District)',
  'Ratnagiri District, Maharashtra (India)' => 'Ratnāgiri (India : District)'
}

K2LCURI = {
  'Earth' => 'http://id.loc.gov/authorities/subjects/sh85040427',
  'United States' => 'http://id.loc.gov/authorities/names/n78095330',
  'Chandīgarh' => 'http://id.loc.gov/authorities/names/n81109268',
  'Maharashtra (India)' => 'http://id.loc.gov/authorities/names/n50000932',
  'Chandni Chowk' => 'http://id.loc.gov/authorities/names/no2004006256',
  'Bhīlwāra (India : District)' => 'http://id.loc.gov/authorities/names/n89284170',
  'Jāt' => nil,
  'Anand District, Gujarāt (India)' => 'http://id.loc.gov/authorities/names/n2008050108',
  'Ratnagiri District, Maharashtra (India)' => 'http://id.loc.gov/authorities/names/n83150618'
}


describe GeoHydra::Gazetteer do
  
  describe '#find_id' do
    it "nil case" do
      g.find_id(nil).should == nil      
      g.find_id('adsfadsfasdf').should == nil      
    end
    K2GEONAMESID.each do |k,geonamesid|
      it k do
        g.find_id(k).should == geonamesid
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
        g.find_loc_keyword(k).should == lcsh
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
        g.find_loc_uri(k).should == lcuri
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
        r = g.find_loc_authority(k)
        if lcuri.nil?
          r.should == nil
        else
          if lcuri.start_with?('http://id.loc.gov/authorities/subjects/sh')
            r.should == 'lcsh'
          elsif lcuri.start_with?('http://id.loc.gov/authorities/names/n')
            r.should == 'lcnaf'
          else
            r.should == nil
          end
        end
      end
    end
  end
  
  describe '#find_placename' do
    it "nil case" do
      g.find_placename(nil).should == nil      
      g.find_placename('asdfasdfasdf').should == nil      
    end
    K2PLACENAME.each do |k,placename|
      it k do
        g.find_placename(k).should == placename
      end
    end
  end

  describe '#find_placename_uri' do
    it "nil case" do
      g.find_placename_uri(nil).should == nil      
      g.find_placename_uri('asdfasdfasdf').should == nil      
    end
    K2GEONAMESID.each do |k,geonamesid|
      it k do
        g.find_placename_uri(k).should == "http://sws.geonames.org/#{geonamesid}/"
      end
    end
  end
  
  describe '#find_keyword_by_id' do
    it "nil case" do
      g.find_keyword_by_id(nil).should == nil      
      g.find_keyword_by_id(-1).should == nil      
    end
    K2GEONAMESID.each do |k,geonamesid|
      it geonamesid do
        g.find_keyword_by_id(geonamesid).should == k
      end
    end
  end
  
  
end
