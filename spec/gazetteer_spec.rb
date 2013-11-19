# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

describe GeoHydra::Gazetteer do
  
  describe '#find_by_keyword' do
    %w{a b c}.each do |k|
      it k do
        v = GeoHydra::Gazetteer.find_by_keyword(k)
        v.should == nil
      end
    end
  end
  
  describe '#find_by_id' do
    %w{1 2 3}.each do |k|
      it k do
        v = GeoHydra::Gazetteer.find_by_id(k.to_i)
        v.should == nil
      end
    end
  end
  
  
end
