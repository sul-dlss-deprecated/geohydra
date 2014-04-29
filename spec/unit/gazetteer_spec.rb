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
  'Chandīgarh (India : Union Territory)' => 1274744,                        # with UTF8
  'Maharashtra (India)' => 1264418,               # without UTF8
  'Chandni Chowk (Delhi, India)' => 6619404,      # same as placename
  'Jāt (India)' => 1269155,                       # no LC with UTF8
  'Bhīlwāra (India : District)' => 1275961,       # with UTF8 and qualifier
  'Anand (India : District)' => 7627221,   # UTF8 in qualifier
  'Ratnāgiri (India : District)' => 1258340, # with qualifier and UTF8 in LCNAF
  'Monterey Harbor (Calif.)' => 5374395 # no LC
}

K2PLACENAME = {
  'United States' => 'United States',
  'Chandīgarh (India : Union Territory)' => 'Chandīgarh',
  'Maharashtra (India)' => 'Mahārāshtra',
  'Chandni Chowk (Delhi, India)' => 'Chandni Chowk',
  'Jāt (India)' => 'Jāt',
  'Bhīlwāra (India : District)' => 'Bhīlwāra',
  'Anand (India : District)' => 'Anand',
  'Ratnāgiri (India : District)' => 'Ratnagiri District',
  'Monterey Harbor (Calif.)' => 'Monterey Harbor'
}

K2LCSH = {
  'Earth' => 'Earth (Planet)',
  'United States' => 'United States',
  'Chandīgarh (India : Union Territory)' => 'Chandīgarh (India : Union Territory)',
  'Maharashtra (India)' => 'Maharashtra (India)',
  'Chandni Chowk (Delhi, India)' => 'Chandni Chowk (Delhi, India)',
  'Jāt (India)' => nil,
  'Bhīlwāra (India : District)' => 'Bhīlwāra (India : District)',
  'Anand (India : District)' => 'Anand (India : District)',
  'Ratnāgiri (India : District)' => 'Ratnāgiri (India : District)',
  'Monterey Harbor (Calif.)' => nil
}

K2LCURI = {
  'Earth' => 'http://id.loc.gov/authorities/subjects/sh85040427',
  'United States' => 'http://id.loc.gov/authorities/names/n78095330',
  'Chandīgarh (India : Union Territory)' => 'http://id.loc.gov/authorities/names/n81109268',
  'Maharashtra (India)' => 'http://id.loc.gov/authorities/names/n50000932',
  'Chandni Chowk (Delhi, India)' => 'http://id.loc.gov/authorities/names/no2004006256',
  'Bhīlwāra (India : District)' => 'http://id.loc.gov/authorities/names/n89284170',
  'Jāt (India)' => nil,
  'Anand (India : District)' => 'http://id.loc.gov/authorities/names/n2008050108',
  'Ratnāgiri (India : District)' => 'http://id.loc.gov/authorities/names/n83150618',
  'Monterey Harbor (Calif.)' => nil
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
