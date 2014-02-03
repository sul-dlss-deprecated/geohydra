# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

describe GeoHydra::Utils do
  
  describe '#shapefile? successes' do
    %w{ foo.shp 
        with_underscore.shp 
        with-hyphen.shp 
        ThisHasCaps.Shp 
        ALLCAPS.SHP
        withNu9b3rs.shp 
        thisisaverylonglonglonglonglonglonglonglonglonglonglonglonglonglonglongname.shp
      }.each do |fn|
      it fn do
        GeoHydra::Utils.shapefile?(fn).should == true
      end
    end

  end
  
  describe "#shapefile? failures" do
    %w{ foo.shx 
        foo.shp.xml 
        with#punct.shp 
        with\ space.shp
      }.each do |fn|
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