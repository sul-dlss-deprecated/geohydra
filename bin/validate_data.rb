#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'

def validate(path, flags)
  ap({:path => path, :flags => flags}) if flags[:debug]
  File.umask(002)
  Dir.glob("#{flags[:srcdir]}/**/*.shp") do |shp|
    puts "Processing #{shp}" if flags[:debug]
    basefn = File.basename(shp, '.shp')
    unless GeoMDTK::Utils.shapefile?(shp)
      puts "Error <#{shp}>. Trying to repair..."
      Dir.glob("#{File.dirname(shp)}/#{basefn.gsub(' ', "\\ ")}.*") do |fn|
        newfn = File.join(File.dirname(fn), File.basename(fn).gsub(/[^a-zA-Z0-9_]/, '_'))
        FileUtils.mv fn, newfn
      end
    end
  end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :stagedir => GeoMDTK::Config.geomdtk.stage || 'stage',
    :tmpdir => GeoMDTK::Config.geomdtk.tmpdir || 'tmp'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] srcdir
EOM
    opts.on("--stagedir DIR", "Staging directory to place files (default: #{flags[:stagedir]})") do |v|
      flags[:stagedir] = v
    end
    opts.on("--tmpdir DIR", "Temporary directory (default: #{flags[:tmpdir]})") do |v|
      flags[:tmpdir] = v
    end
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
  end.parse!

  [:stagedir].each do |k|
    raise ArgumentError, "Missing directory #{flags[k]}" unless File.directory? flags[k]
  end
  
  flags[:srcdir] = ARGV.pop
  raise ArgumentError, "Missing directory #{flags[:srcdir]}" unless flags[:srcdir] and File.directory?(flags[:srcdir])

  puts "Examining #{flags[:srcdir]}" if flags[:debug]
  validate flags[:srcdir], flags
  rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
