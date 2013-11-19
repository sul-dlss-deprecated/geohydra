# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

require 'rubygems'
require 'rspec'
require 'awesome_print'
require 'equivalent-xml'
require 'geohydra'

describe GeoHydra::Transform do
  
  describe '#to_geoMetadataDS' do
    Dir.glob('spec/fixtures/*/temp/*iso19139.xml') do |fn|
      druid = File.basename(File.dirname(File.dirname(fn)))
            
      context druid do
        it 'ISO19139 to geoMetadata' do
          iso = Nokogiri::XML(File.open(fn))
          
          isoFcFn = File.open(fn.gsub('iso19139', 'iso19139-fc'))
          if File.exist?(isoFcFn)
            isoFc = Nokogiri::XML(File.open(isoFcFn))
          else
            isoFc = nil
          end
          
          dsXml = GeoHydra::Transform.to_geoMetadataDS(iso, isoFc, {
            'purl' => "http://purl-test.stanford.edu/#{druid}"
          })
          geoFn = "spec/fixtures/#{druid}/metadata/geoMetadata.xml"
          geo = Nokogiri::XML(File.open(geoFn))
          
          dsXml.should be_equivalent_to(geo)
        end
      end
    end
  end
  
end
