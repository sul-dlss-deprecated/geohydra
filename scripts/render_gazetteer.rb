#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'json'
require 'uri'

puts "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head><body>"
puts "<table border=0><tr><th>GeoNames</th><th>SearchWorks by subject</th></tr>"

@@g = GeoHydra::Gazetteer.new
@@g.each {|k|
  id = @@g.find_id_by_keyword(k)
  lc = @@g.find_lc_by_keyword(k)
  puts "<tr>"
  puts "<td><a href=\"http://sws.geonames.org/#{id}\">#{k}</a> <small><a href=\"http://sws.geonames.org/#{id}/about.rdf\">rdf</a></small></td>"
  unless lc.nil?
    href = URI.encode_www_form("f[geographic_facet][]" => lc.strip, 
              # "q" => "\"#{lc}\"", # general search for phrase
              # "search_field" => "subject_terms"
              )
    puts "<td><a href=\"http://searchworks.stanford.edu/?#{href}\">#{lc}</a></td>"
  else
    puts "<td></td>"
  end
  puts "</tr>"
}

puts "</table></body></html>"
