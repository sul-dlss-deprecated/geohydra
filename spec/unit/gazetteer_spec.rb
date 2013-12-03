# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

g = GeoHydra::Gazetteer.new
# ap({:g => g})

K2ID = {
  'United States' => 6252001,
  'Union Territory of Chandīgarh' => 1274744,
  'State of Mahārāshtra' => 1264418
}

K2LC = {
  'Earth' => 'Earth (Planet)',
  'United States' => 'United States',
  'Union Territory of Chandīgarh' => nil,
  'State of Mahārāshtra' => 'Maharashtra (India)'
}

K2LCURI = {
  'Earth' => 'http://id.loc.gov/authorities/subjects/sh85040427'
}

describe GeoHydra::Gazetteer do
  
  describe '#find_id_by_keyword' do
    it "nil case" do
      g.find_id_by_keyword(nil).should == nil      
      g.find_id_by_keyword('adsfadsfasdf').should == nil      
    end
    K2ID.each do |k,id|
      it k do
        r = g.find_id_by_keyword(k)
        r.should == id
      end
    end
  end
  
  describe '#find_lc_by_keyword' do
    it "nil case" do
      g.find_lc_by_keyword(nil).should == nil      
      g.find_lc_by_keyword('asdfasdfasdf').should == nil      
    end
    K2LC.each do |k,lcsh|
      it k do
        r = g.find_lc_by_keyword(k)
        r.should == lcsh
      end
    end
  end

  describe '#find_lcuri_by_keyword' do
    it "nil case" do
      g.find_lcuri_by_keyword(nil).should == nil      
      g.find_lcuri_by_keyword('asdfasdfasdf').should == nil      
    end
    K2LCURI.each do |k,lcuri|
      it k do
        r = g.find_lcuri_by_keyword(k)
        r.should == lcuri
      end
    end
  end
  

  describe '#find_uri_by_keyword' do
    it "nil case" do
      g.find_uri_by_keyword(nil).should == nil      
      g.find_uri_by_keyword('asdfasdfasdf').should == nil      
    end
    K2ID.each do |k,id|
      it k do
        r = g.find_uri_by_keyword(k)
        r.should == "http://sws.geonames.org/#{id}/"
      end
    end
  end
  
  describe '#find_keyword_by_id' do
    it "nil case" do
      g.find_keyword_by_id(nil).should == nil      
      g.find_keyword_by_id(-1).should == nil      
    end
    K2ID.each do |k,id|
      it id do
        r = g.find_keyword_by_id(id)
        r.should == k
      end
    end
  end
  
  
end
