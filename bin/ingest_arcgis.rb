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
  :verbose => false,
  :debug => false
}
OptionParser.new do |opts|
  opts.banner = "
Usage: #{__FILE__} [-v] file.shp.xml [file.shp.xml ...]
       #{__FILE__} [-v] directory
"
  opts.on("-v", "--verbose", "Run verbosely") do |v|
    flags[:debug] = true if flags[:verbose]
    flags[:verbose] = true
  end
end.parse!

ap({:flags => flags, :argv => ARGV}) if flags[:debug]

ARGV.each do |fn|
  if File.directory? fn
    Dir.glob(File.join(fn, '**', '*.shp.xml')) do |fn2|
      process_file fn2, flags
    end
  elsif File.exist? fn
    process_file fn, flags
  else
    $stderr.puts "WARNING: Missing file <#{fn}>"
  end
end

