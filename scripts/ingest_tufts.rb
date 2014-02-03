#!/usr/bin/env ruby

require 'json'
require 'awesome_print'
require 'net/http'
require 'dor-services'
require 'rsolr'

# 'http://sul-solr.stanford.edu/solr/ogp-dev/select?q=*:*'


def download(solr, x, w)
  puts "downloading #{x} to #{x+w}"
  url = "http://geodata.tufts.edu/solr/select?q=Institution:*&start=#{x}&rows=#{w}&wt=json&indent=on&fl=" +
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

  fn = "data_#{x}_#{x+w}.json"
  unless File.exist?(fn)
    system("curl '#{url}' > #{fn}")
  end

  json = JSON::parse(File.open(fn).read.to_s)
  json['response']['docs'].each do |doc|
    # ap({:doc => doc})
    puts "Adding #{doc['LayerId']}"
    solr.add doc
    # ap({:solr => solr})
  end
  solr.commit
  solr.optimize
  json['response']['docs'].length
end

solr = RSolr.connect(:url => 'http://localhost:18080/solr/ogp-test')
ap({:solr => solr})
x = 0
w = 100
n = 1
while n > 0 and x < 15000 do
  n = download(solr, x, w)
  puts 'Uploaded ' + n.to_s + ' records'
  x += w
end
