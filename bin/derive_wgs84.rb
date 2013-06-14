#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'fileutils'

TMPDIR = GeoMDTK::Config.geomdtk.tmpdir || 'tmp'
WORKDIR = GeoMDTK::Config.geomdtk.workspace || 'workspace'
STAGEDIR = GeoMDTK::Config.geomdtk.stage || 'stage'

# ogr2ogr is using a different WKT than GeoServer -- this one is from GeoServer 2.3.1.
# As implemented by EPSG database on HSQL:
#  http://docs.geotools.org/latest/userguide/library/referencing/hsql.html
# Also see:
#  http://spatialreference.org/ref/epsg/4326/prettywkt/
WKT = <<EOM
GEOGCS["WGS 84",
    DATUM["WGS_1984",
        SPHEROID["WGS 84",6378137,298.257223563,
            AUTHORITY["EPSG","7030"]],
        AUTHORITY["EPSG","6326"]],
    PRIMEM["Greenwich",0,
        AUTHORITY["EPSG","8901"]],
    UNIT["degree",0.01745329251994328,
        AUTHORITY["EPSG","9122"]],
    AUTHORITY["EPSG","4326"]]
EOM
.split.join.freeze

def do_system cmd, dry_run = false
  puts "RUNNING: #{cmd}"
  system(cmd) unless dry_run
end

# @param overwrite_prj [Boolean] ogr2ogr writes a .prj file that GeoServer doesn't recognize as EPSG:4326
def main(workdir = WORKDIR, tmpdir = TMPDIR, overwrite_prj = true)
  Dir.glob(workdir + "/??/???/??/????/???????????/content/*.zip").each do |fn| # matches druid workspace structure
    puts "Processing #{fn}"
    k = File.basename(fn, '.zip')
    shp = k + '.shp'
    
    puts "Extracting #{fn}"
    tmp = "#{tmpdir}/#{k}"
    FileUtils.rm_rf tmp if File.directory? tmp
    FileUtils.mkdir_p tmp
    do_system("unzip -j #{fn} -d #{tmp}")
    
    ofn = File.join(File.dirname(fn), 'EPSG', '4326', shp)
    odir = File.dirname(ofn)
    puts "Projecting #{fn} into #{ofn}"
    FileUtils.mkdir_p odir unless File.directory? odir
    unless File.exist? ofn
      do_system("ogr2ogr -progress -t_srs '#{WKT}' '#{ofn}' '#{tmp}/#{shp}'") 
      if overwrite_prj
        File.open(ofn.gsub(%r{shp$}, 'prj'), 'w') {|f| f.write(WKT)}
      end
      FileUtils.rm_rf tmp
      do_system("zip -Dj #{fn.gsub(%r{\.zip}, '_EPSG_4326.zip')} #{odir}/#{k}.*")
      FileUtils.rm_rf(File.join(File.dirname(fn), 'EPSG'))
    end
  end
end

main