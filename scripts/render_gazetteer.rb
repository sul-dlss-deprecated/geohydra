#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'json'
require 'uri'

puts "<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"></head><body>"
puts "<table border=0><tr><th>Key</th><th>Placename (GeoNames)</th><th>LOC Subject (SearchWorks)</th></tr>"

@@g = GeoHydra::Gazetteer.new
@@g.each {|k|
  gk = @@g.find_placename(k)
  id = @@g.find_id(k)
  lc = @@g.find_loc_keyword(k)
  puts "<tr>"
  if k == gk
    puts "<td><i>#{k}</i></td>"
  else
    puts "<td>#{k}</td>"
  end
  puts "<td><a href=\"http://sws.geonames.org/#{id}\">#{gk}</a> <small><a href=\"http://sws.geonames.org/#{id}/about.rdf\">rdf</a></small></td>"
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
