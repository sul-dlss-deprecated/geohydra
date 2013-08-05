#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'
require 'csv'

def assemble(druid, path, flags)
  ap({:druid => druid, :path => path, :flags => flags}) if flags[:debug]
  File.umask(002)
  Dir.glob("#{path}/**/*.shp") do |shp|
    raise ArgumentError, shp unless GeoMDTK::Utils.shapefile?(shp)

    ap({:shp => shp}) if flags[:debug]
    geometry_type = GeoMDTK::Transform.geometry_type(shp)
    ap({:geometry_type => geometry_type}) if flags[:debug]
    basename = File.basename(shp, '.shp')
    zipfn = File.join(File.dirname(shp), basename + '.zip')
    puts "Compressing #{basename} into #{zipfn}" if flags[:verbose]
    fns = Dir.glob("#{File.dirname(shp)}/#{basename}.*").select do |fn|
      fn !~ /\.zip$/
    end
    Dir.glob("#{File.dirname(shp)}/#{basename}-iso19139*.xml").each do |fn|
      fns << fn
    end
    system "zip -9vj '#{zipfn}' #{fns.join(' ')}"
    fns.each {|fn| FileUtils.rm(fn)}
    flags[:csvout] << [druid, File.basename(shp), geometry_type]
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

  flags[:csvout] = CSV.open('druid.csv', 'w')
  flags[:csvout] << ['druid', 'shapefile', 'geometry_type']
  puts "Searching for druid folders in #{flags[:srcdir]}..." if flags[:verbose]
  n = 0
  GeoMDTK::Utils.find_druid_folders(flags[:srcdir]) do |path|
    assemble DruidTools::Druid.new(File.basename(path)), path, flags
    n = n + 1
  end
  puts "Processed #{n} folders."
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
