#!/usr/bin/env ruby
require 'fileutils'
WORKDIR = '/var/geomdtk/current/workspace'

# ogr2ogr is using a different WKT than GeoServer -- this one is from GeoServer 2.3
WKT = %q{GEOGCS["WGS 84", DATUM["World Geodetic System 1984", SPHEROID["WGS 84", 6378137.0, 298.257223563,AUTHORITY["EPSG","7030"]], AUTHORITY["EPSG","6326"]], PRIMEM["Greenwich", 0.0, AUTHORITY["EPSG","8901"]], UNIT["degree",0.017453292519943295], AXIS["Geodetic longitude", EAST], AXIS["Geodetic latitude", NORTH], AUTHORITY["EPSG","4326"]]}

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
    unless File.exist? dstfn
      do_system("ogr2ogr -progress -t_srs EPSG:4326 '#{dstfn}' '#{fn}'") 
      File.open(dstfn.gsub(%r{shp$}, 'prj'), 'w').write(WKT)
    end
  end
end

main