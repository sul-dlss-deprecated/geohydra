#!/usr/bin/env ruby

require 'awesome_print'
require 'json'
require 'rsolr'

class IngestOgp
  def initialize(url = 'http://localhost:8080/solr/ogp-dev')
    @solr_url = url
  end
  
  def ingest(fn)
    puts "Ingesting #{fn}"
    json = JSON::parse(File.read(fn))
    json['response']['docs'].each do |doc|
      # ap({:doc => doc})
      doc.delete('_version_')
      doc.delete('timestamp')
      putc "."
      @solr.add doc
    end
    puts
    @solr.commit
    json['response']['docs'].length
  end
  
  def open
    @solr = RSolr.connect(:url => @solr_url)
    ap({:solr => @solr})
  end
  
  def close
    @solr.commit
    @solr.optimize
  end
  
end


# __MAIN__
ogp = IngestOgp.new
ogp.open
Dir.glob("data/*.json") do |fn|
  ogp.ingest(fn)
end
ogp.close