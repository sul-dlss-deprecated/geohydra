#!/usr/bin/env ruby

require 'optparse'
require 'geomdtk'

def do_file fn
  if File.basename(fn) =~ %r{^(.*).(shp|tif).xml$}
    puts "Processing #{$1}"
    GeoMDTK::Transform.extract_thumbnail fn, File.join(File.dirname(fn), "#{$1}.jpg")
  else
    raise OptionParser::InvalidOption, "File <#{fn}> is not ESRI metadata format"
  end
end

flags = {
  :datadir => '.',
  :verbose => false
}

optparse = OptionParser.new do |opts|
  opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [fn [fn...]]
EOM
  opts.on("-d", "--dir DIR", "Process all files in DIR (default: #{flags[:datadir]})") do |v|
    flags[:datadir] = v
  end
  opts.on("-v", "--[no-]verbose", "Run verbosely (default: #{flags[:verbose]})") do |v|
    flags[:verbose] = v
  end
end

begin
  optparse.parse!  
  if ARGV.empty?
    raise OptionParser::InvalidOption, flags[:datadir] + ' not a directory' unless File.directory?(flags[:datadir])
    Dir.glob(flags[:datadir] + '/*.xml').each {|fn| do_file fn }
  else
    ARGV.each {|fn| do_file fn }
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  $stderr.puts e
  $stderr.puts optparse
  exit -1
end