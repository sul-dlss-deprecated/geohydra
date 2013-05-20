$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'bundler/setup'
require 'rspec'
require 'rspec/autorun'
require 'rspec/mocks'

describe GeoMDTK::Validate do

  before(:each) do
    @v = GeoMDTK::Validate.new
  end
  
  describe "#validate" do
    it "read-only" do
      Dir.glob("/Volumes/Geo3TB/data/druid/*.xml").each do |fn|
        puts "Processing #{fn}"
        ap @v.validate(fn)
      end
    end
  end
end
