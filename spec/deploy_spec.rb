$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'bundler/setup'
require 'rspec'
require 'rspec/autorun'
require 'rspec/mocks'

describe GeoMDTK::Deploy do

  describe "#push" do
    it "#push_shapefile" do
      Dir.glob("/Volumes/Geo3TB/data/druid/*.zip").each do |fn|
        GeoMDTK::Deploy.new.push(fn, File.basename(fn).gsub(%r{\.zip$}, ''))
      end
    end
  end
end
