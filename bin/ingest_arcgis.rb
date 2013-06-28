#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'

def process_file fn, flags
  puts "Processing <#{fn}>" if flags[:verbose]
  if fn =~ %r{^(.*).shp.xml$}
    ofn = $1 + '-iso19139.xml'
    ofn_fc = $1 + '-iso19139-fc.xml'
    ap({:fn => fn, :ofn => ofn, :ofn_fc => ofn_fc}) if flags[:debug]
    GeoMDTK::Transform.from_arcgis fn, ofn, ofn_fc
  end
end

flags = {
  :datadir => nil,
  :verbose => false,
  :debug => false
}
OptionParser.new do |opts|
  opts.banner = "
Usage: #{__FILE__} [-v] file.shp.xml [file.shp.xml ...]
       #{__FILE__} [-v] --datadir=DIR
"
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    flags[:debug] = true if flags[:verbose]
    flags[:verbose] = true
  end
  opts.on("-d DIR", "--datadir=DIR", 
          "Data directory to process (default: #{flags[:datadir]})") do |v|
    flags[:datadir] = File.expand_path(v)
    opts.abort "Missing: #{flags[:datadir]}" unless File.directory? flags[:datadir]
  end
end.parse!

ap [flags, ARGV] if flags[:verbose]

if ARGV.empty? 
  raise ArgumentError, 'No files' if flags[:datadir].nil?
  Dir.glob(flags[:datadir] + '/**/*.shp.xml') do |fn|
    process_file fn, flags
  end
else
  raise ArgumentError, 'Cannot provide both --datadir and filenames' unless flags[:datadir].nil?
  ARGV.each do |fn|
    if File.exist? fn
      process_file fn, flags
    else
      $stderr.puts "WARNING: Missing file <#{fn}>"
      next
    end
  end
end

