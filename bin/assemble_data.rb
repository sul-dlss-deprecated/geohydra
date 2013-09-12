#!/usr/bin/env ruby
# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'

def assemble(path, flags)
  ap({:path => path, :flags => flags}) if flags[:debug]
  File.umask(002)
  Dir.glob(File.join(path, '**', '*.shp')) do |shp|
    raise ArgumentError, shp unless GeoHydra::Utils.shapefile?(shp)

    ap({:shp => shp}) if flags[:debug]
    geometry_type = GeoHydra::Transform.geometry_type(shp)
    ap({:geometry_type => geometry_type}) if flags[:debug]
    puts ['Scanned', File.basename(shp), geometry_type].join("\t") if flags[:verbose]
    
    basename = File.basename(shp, '.shp')
    zipfn = File.join(path, 'content', 'data.zip')
    puts "Compressing #{basename} into #{zipfn}" if flags[:verbose]
    fns = Dir.glob(File.join(File.dirname(shp), "#{basename}.*")).select do |fn|
      fn !~ /\.zip$/
    end
    metadata_fns = []
    Dir.glob(File.join(File.dirname(shp), "#{basename}-iso19139*.xml")).each do |fn|
      metadata_fns << fn
    end
    cmd =  "zip -vj '#{zipfn}' #{fns.join(' ')} #{metadata_fns.join(' ')}"
    ap({:cmd => cmd, :fns => fns}) if flags[:debug]
    system cmd
    fns.each {|fn| FileUtils.rm(fn)} unless flags[:debug]
  end
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :srcdir => '/var/geohydra/current/upload/druid'
  }

  OptionParser.new do |opts|
    opts.banner = <<EOM
Usage: #{File.basename(__FILE__)} [options] [srcdir]
EOM
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
  end.parse!

  
  flags[:srcdir] = ARGV.pop unless File.directory?(flags[:srcdir])
  raise ArgumentError, "Missing directory #{flags[:srcdir]}" unless flags[:srcdir] and File.directory?(flags[:srcdir])

  puts "Searching for druid folders in #{flags[:srcdir]}..." if flags[:verbose]
  n = 0
  GeoHydra::Utils.find_druid_folders(flags[:srcdir]) do |path|
    assemble path, flags
    n = n + 1
  end
  puts "Processed #{n} folders."
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
