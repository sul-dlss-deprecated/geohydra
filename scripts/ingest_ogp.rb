#!/usr/bin/env ruby

require 'awesome_print'
require 'json'
require 'rsolr'

class IngestOgp
  def initialize(url = 'http://localhost:18080/solr/ogp-dev')
    @solr = RSolr.connect(:url => url)
    ap({:solr => @solr})
    yield self
    close
  end
  
  def ingest(fn)
    puts "Ingesting #{fn}"
    json = JSON::parse(File.read(fn))
    n = 0
    json.each do |doc|
      next unless doc.is_a? Hash
      next if doc['LayerId'].nil?
      doc.delete('_version_')
      doc.delete('timestamp')
      putc "."
      @solr.add doc
      n += 1
      if n % 1000 == 0
        @solr.commit 
        puts "\ncommit 1000 records, #{n} total\n"
      end
    end
    puts "\n#{n} records\n"
    @solr.commit
  end
  
  def close
    @solr.commit
    @solr.optimize
  end
  
end


# __MAIN__
IngestOgp.new do |ogp|
  Dir.glob("out/*.json") do |fn|
    ogp.ingest(fn)
  end
end
