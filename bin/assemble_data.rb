#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'optparse'

def assemble(druid, path, flags)
  ap({:druid => druid, :path => path, :flags => flags}) if flags[:debug]
  File.umask(002)
  Dir.glob("#{path}/**/*.shp") do |shp|
    raise ArgumentError, shp unless GeoMDTK::Utils.shapefile?(shp)

    ap({:shp => shp}) if flags[:debug]
    geometry_type = GeoMDTK::Transform.geometry_type(shp)
    ap({:geometry_type => geometry_type}) if flags[:debug]
    puts ['Scanned', File.basename(shp), geometry_type].join("\t") if flags[:verbose]
    
    basename = File.basename(shp, '.shp')
    zipfn = File.join(druid.content_dir, basename + '.zip')
    puts "Compressing #{basename} into #{zipfn}" if flags[:verbose]
    fns = Dir.glob("#{File.dirname(shp)}/#{basename}.*").select do |fn|
      fn !~ /\.zip$/
    end
    Dir.glob("#{File.dirname(shp)}/#{basename}-iso19139*.xml").each do |fn|
      fns << fn
    end
    system "zip -9vj '#{zipfn}' #{fns.join(' ')}"
    fns.each {|fn| FileUtils.rm(fn)}
  end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] srcdir
EOM
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
  end.parse!

  
  flags[:srcdir] = ARGV.pop
  raise ArgumentError, "Missing directory #{flags[:srcdir]}" unless flags[:srcdir] and File.directory?(flags[:srcdir])

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
