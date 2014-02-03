#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'druid-tools'
require 'fileutils'
require 'optparse'

class DeriveWGS84 < GeoHydra::Process
  def run(args)
    File.umask(002)
    flags = {
      :overwrite_prj => true,
      :verbose => false,
      :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace',
      :tmpdir => GeoHydra::Config.geohydra.tmpdir || 'tmp',
      # ogr2ogr is using a different WKT than GeoServer -- this one is from GeoServer 2.3.1.
      # As implemented by EPSG database on HSQL:
      #  http://docs.geotools.org/latest/userguide/library/referencing/hsql.html
      # Also see:
      #  http://spatialreference.org/ref/epsg/4326/prettywkt/
      :wkt => {
        '4326' => %Q{
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
        }.split.join.freeze
      }

    }  

    OptionParser.new do |opts|
      opts.banner = <<EOM
  Usage: #{File.basename(__FILE__)} [options] [druid...]
EOM
      opts.on("-v", "--verbose", "Run verbosely") do |v|
        flags[:verbose] = true
      end
      opts.on("--workspace DIR", "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
        flags[:workspacedir] = v
      end
      opts.on("--tmpdir DIR", "Temporary directory for assembly (default: #{flags[:tmpdir]})") do |v|
        flags[:tmpdir] = v
      end
      opts.on("--wkt SRID FILE", "Read WKT for SRID from FILE") do |srid, f|
        flags[:wkt][srid.to_s] = File.read(f).split.join.freeze
      end
    end.parse!(args)

    [flags[:tmpdir], flags[:workspacedir]].each do |d|
      raise ArgumentError, "Missing directory #{d}" unless File.directory? d
    end

    if args.empty?
      # matches druid workspace structure
      Dir.glob(flags[:workspacedir] + '/??/???/??/????/???????????/content/data.zip').each do |fn| 
        id = File.basename(File.dirname(File.dirname(fn)))
        druid = DruidTools::Druid.new(id, flags[:workspacedir])
        unless fn =~ %r{_EPSG_}i
          puts "Processing #{druid.id} #{fn}"
          GeoHydra::Transform.reproject druid, fn, flags 
        end
      end
    else
      args.each do |id|
        druid = DruidTools::Druid.new(id, flags[:workspacedir])
        Dir.glob(druid.content_dir + '/data.zip').each do |fn|
          unless fn =~ %r{_EPSG_}i
            puts "Processing #{druid.id} #{fn}"
            GeoHydra::Transform.reproject druid, fn, flags 
          end
        end
      end
    end
  end
end

# __MAIN__
begin
  DeriveWGS84.new.run(ARGV)
rescue SystemCallError => e
  $stderr.puts "ERROR: #{e.message}"
  exit(-1)
end
