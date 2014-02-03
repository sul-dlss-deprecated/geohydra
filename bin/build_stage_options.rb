#!/usr/bin/env ruby

require 'geohydra'
require 'json'

class BuildStageOptions < GeoHydra::Process
  # @param [String] shp assumes foo/bar/aa111bb1111/temp/shapefile.shp
  def doit(shp)
    r = {}
    r['druid'] = File.basename(File.dirname(File.dirname(shp)))
    raise ArgumentError, "SyntaxError: Not a shapefile: #{shp}" unless GeoHydra::Utils.shapefile?(shp)
    r['geometryType'] = GeoHydra::Transform.geometry_type(shp)
    r['filename'] = File.basename(shp)
    File.open(File.join(File.dirname(shp), 'geoOptions.json'), 'w') do |f|
      f.puts r.to_json.to_s
    end
  end

  def run(args)
    if args.empty?
      Dir.glob('/var/geomdtk/current/stage/**/temp/*.shp') do |shp|
        doit(shp)
      end
    else
      args.each do |shp|
        doit(shp)
      end
    end
  end
end

# __MAIN__
BuildStageOptions.new.run(ARGV)