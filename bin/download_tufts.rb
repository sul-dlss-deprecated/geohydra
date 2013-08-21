#!/usr/bin/env ruby

require 'json'
require 'awesome_print'
require 'net/http'
require 'dor-services'
require 'rsolr'

# 'http://sul-solr.stanford.edu/solr/ogp-dev/select?q=*:*'

solr = RSolr.connect(:url => 'http://localhost:18080/solr/ogp-dev')
ap({:solr => solr})

url = 'http://geodata.tufts.edu/solr/select?q=Institution:*&start=10000&rows=100000&wt=json&indent=on&fl=' +
%w{
Abstract
Access
Area
Availability
CenterX
CenterY
ContentDate
DataType
ExternalLayerId
FgdcText
GeoReferenced
HalfHeight
HalfWidth
Institution
LayerDisplayName
LayerId
Location
MaxX
MaxY
MinX
MinY
Name
PlaceKeywords
Publisher
SrsProjectionCode
ThemeKeywords
WorkspaceName
}.join(',')


unless File.exist?('data.json')
  system("curl '#{url}' > data.json")
end

json = JSON::parse(File.open('data.json').read.to_s)
json['response']['docs'].each do |doc|
  # ap({:doc => doc})
  puts "Adding #{doc['LayerId']}"
  solr.add doc
  solr.commit
  # ap({:solr => solr})
end
solr.optimize
puts json['response']['docs'].length


