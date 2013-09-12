#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'

def main(flags)
  Dir.glob('/var/geomdtk/current/workspace/**/ogpSolr.xml') do |fn|
    puts "Uploading #{fn}"
    system('curl -X POST  -H "Content-Type: text/xml" ' +
           "--data-binary @#{fn} " +
           "#{flags[:solr]}/#{flags[:collection]}/update")
  end
  system("curl '#{flags[:solr]}/#{flags[:collection]}/update?commit=true'")
  system("curl '#{flags[:solr]}/#{flags[:collection]}/update?optimize=true'")
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :collection => GeoHydra::Config.ogp.solr.collection || 'ogp',
    :solr => GeoHydra::Config.ogp.solr.url
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options]
EOM
    opts.on('-v', '--verbose', 'Run verbosely') do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
  end.parse!

  main flags
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
