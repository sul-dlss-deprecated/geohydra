#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'fileutils'

TMPDIR = $config.geomdtk.tmpdir || 'tmp'
WORKDIR = $config.geomdtk.workspace || 'workspace'
STAGEDIR = $config.geomdtk.stage || 'stage'

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

def main(workdir = WORKDIR, tmpdir = TMPDIR, overwrite_prj = false)
  Dir.glob(workdir + "/??/???/??/????/???????????/content/*.zip").each do |fn| # matches druid workspace structure
    puts "Processing #{fn}"
    k = File.basename(fn, '.zip')
    shp = k + '.shp'
    
    puts "Extracting #{fn}"
    tmp = "#{tmpdir}/#{k}"
    FileUtils.mkdir_p tmp unless File.directory? tmp
    do_system("unzip -jo #{fn} -d #{tmp}")
    
    puts "Projecting #{fn}"
    dstfn = File.join(File.dirname(fn), 'EPSG', '4326', shp)
    ddir = File.dirname(dstfn)
    FileUtils.mkdir_p ddir unless File.directory? ddir
    unless File.exist? dstfn
      do_system("ogr2ogr -progress -t_srs '#{WKT}' '#{dstfn}' '#{tmp}/#{shp}'") 
      if overwrite_prj
        File.open(dstfn.gsub(%r{shp$}, 'prj'), 'w').write(WKT)
      end
      FileUtils.rm_rf tmp
      do_system("zip -vDj #{fn.gsub(%r{\.zip}, '_EPSG_4326.zip')} #{ddir}/#{k}.*")
      FileUtils.rm_rf "#{ddir}/EPSG"      
    end
  end
end

main