#!/usr/bin/env ruby

require 'json'
require 'awesome_print'
require 'net/http'
require 'dor-services'
require 'rsolr'

# 'http://sul-solr.stanford.edu/solr/ogp-dev/select?q=*:*'


def download(solr, x, y)
  puts "downloading #{x} to #{y}"
	url = "http://geodata.tufts.edu/solr/select?q=Institution:*&start=#{x}&rows=#{y}&wt=json&indent=on&fl=" +
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

  fn = "data_#{x}_#{y}.json"
	unless File.exist?(fn)
		system("curl '#{url}' > #{fn}")
	end
	n = 0
	json = JSON::parse(File.open(fn).read.to_s)
	json['response']['docs'].each do |doc|
		# ap({:doc => doc})
		puts "Adding #{doc['LayerId']}"
		solr.add doc
		if n == 100
			puts "Commit"
			solr.commit
			n = 0
		end
		n += 1
		# ap({:solr => solr})
	end
	solr.commit
	solr.optimize
	json['response']['docs'].length
end

solr = RSolr.connect(:url => 'http://localhost:18080/solr/ogp-test')
ap({:solr => solr})
w = 500
x = 0
y = w
n = 1
while n > 0 and y < 15000 do
  n = download(solr, x, y)
  puts 'Uploaded ' + n.to_s + ' records'
	
  x += w
  y += w
end
