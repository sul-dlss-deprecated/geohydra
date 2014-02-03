#!/usr/bin/env ruby

require 'optparse'
require 'geohydra'

class ExtractThumbnail < GeoHydra::Process
  def do_file fn, flags
    if fn =~ %r{^(.*)\.(shp|tif)\.xml$}i
      puts "Processing #{fn} for JPEG" if flags[:verbose]
      GeoHydra::Transform.extract_thumbnail fn, File.join(File.dirname(fn), 'preview.jpg')
    else
      raise OptionParser::InvalidOption, "File <#{fn}> is not ESRI metadata format"
    end
  end

  def run(args)
    flags = {
      :datadir => '.',
      :recurse => false,
      :verbose => false
    }

    optparse = OptionParser.new do |opts|
      opts.banner = <<EOM
    Usage: #{File.basename(__FILE__)} [options] [fn [fn...]]
EOM
      opts.on("-d", "--dir DIR", "Process all files in DIR (default: #{flags[:datadir]})") do |v|
        flags[:datadir] = v
      end
      opts.on("-r", "--recursive", "Process all files recurvisely") do |v|
        flags[:recurse] = true
      end

      opts.on("-v", "--verbose", "Run verbosely") do |v|
        flags[:verbose] = true
      end
    end

    optparse.parse!(args)  
    if args.empty?
      raise OptionParser::InvalidOption, flags[:datadir] + ' not a directory' unless File.directory?(flags[:datadir])
      Dir.glob(flags[:datadir] + (flags[:recurse] ? '/**/*.shp.xml' : '/*.shp.xml')).each {|fn| do_file fn, flags }
    else
      args.each {|fn| do_file fn, flags }
    end
  end
end

ExtractThumbnail.new.run(ARGV)

