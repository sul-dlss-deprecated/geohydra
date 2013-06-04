require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geomdtk'

describe GeoMDTK::Transform do
  
  describe "#transform" do
    it "#validate" do
      Dir.glob('spec/fixtures/*_geoMetadata.xml') do |fn|
        geo = Nokogiri::XML(File.open(fn))
        mods = Nokogiri::XML(File.open(fn.sub('geo', 'desc')))
        GeoMDTK::Transform.to_mods(geo).should be_equivalent_to mods
      end
    end
  end
end
