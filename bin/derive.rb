#!/usr/bin/env ruby
require 'fileutils'
WORKDIR = '/var/geomdtk/current/workspace'

def do_system cmd
  puts cmd
  system(cmd)
end

def main(workdir = WORKDIR)
  Dir.glob(workdir + "/??/???/??/????/???????????/content/*.shp").each do |fn| # matches druid workspace structure
    puts fn
    dstfn = File.join(File.dirname(fn), 'EPSG', '4326', File.basename(fn))
    puts "mkdir -p #{File.dirname(dstfn)}"
    FileUtils.mkdir_p File.dirname(dstfn)
    do_system("ogr2ogr -progress -t_srs EPSG:4326 '#{dstfn}' '#{fn}'") unless File.exist? dstfn
  end
end

main