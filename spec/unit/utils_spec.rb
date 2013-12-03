# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

describe GeoHydra::Utils do
  
  describe '#shapefile?' do
    %w{foo.shp this-is-a-very-long-long-long-name.shp}.each do |fn|
      it fn do
        GeoHydra::Utils.shapefile?(fn).should == true
      end
    end

    %w{foo.shx this-is-a-very-long-long-long-name.shx foo.shp.xml}.each do |fn|
      it fn do
        GeoHydra::Utils.shapefile?(fn).should == false
      end
    end
  end
  
  describe '#find_druid_folders' do
    it 'count druid folders' do
      GeoHydra::Utils.find_druid_folders('spec').size.should == 112
    end
  end
end