#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'fileutils'

TMPDIR = $config.geomdtk.tmpdir || 'tmp'
WORKDIR = $config.geomdtk.workspace || 'workspace'
STAGEDIR = $config.geomdtk.stage || 'stage'

# ogr2ogr is using a different WKT than GeoServer -- this one is from GeoServer 2.3
WKT = %q{GEOGCS["WGS 84", DATUM["World Geodetic System 1984", SPHEROID["WGS 84", 6378137.0, 298.257223563,AUTHORITY["EPSG","7030"]], AUTHORITY["EPSG","6326"]], PRIMEM["Greenwich", 0.0, AUTHORITY["EPSG","8901"]], UNIT["degree",0.017453292519943295], AXIS["Geodetic longitude", EAST], AXIS["Geodetic latitude", NORTH], AUTHORITY["EPSG","4326"]]}

def do_system cmd
  puts cmd
  # system(cmd)
end

def main(workdir = WORKDIR)
  Dir.glob(workdir + "/??/???/??/????/???????????/content/*.zip").each do |fn| # matches druid workspace structure
    puts "Processing #{fn}"
    k = File.basename(fn, '.zip')
    shp = k + '.shp'
    
    puts "Extracting #{fn}"
    do_system("mkdir /tmp/#{k} 2>/dev/null; unzip -jo #{fn} -d /tmp/#{k}")
    
    puts "Projecting #{fn}"
    dstfn = File.join(File.dirname(fn), 'EPSG', '4326', shp)
    puts "mkdir -p #{File.dirname(dstfn)}"
    FileUtils.mkdir_p File.dirname(dstfn)
    unless File.exist? dstfn
      do_system("ogr2ogr -progress -t_srs EPSG:4326 '#{dstfn}' '/tmp/#{k}/#{shp}'") 
      File.open(dstfn.gsub(%r{shp$}, 'prj'), 'w').write(WKT)
      do_system("rm -rf /tmp/#{k}")
      do_system("cd #{File.dirname(dstfn)}; zip -1vDj #{fn.gsub(%r{\.zip}, '_epsg_4326.zip')} #{k}.*")
      do_system("rm -rf #{File.dirname(dstfn)}/EPSG")
    end
  end
end

main