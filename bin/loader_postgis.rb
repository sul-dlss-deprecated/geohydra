#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
#
# RGeoServer Batch load layers (batch_demo.rb)
# Usage: #{File.basename(__FILE__)} [input.yml]
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'optparse'
require 'mods'
require 'druid-tools'
require 'dor-services'
require 'tmpdir'

class LoaderPostGIS < GeoHydra::Process

  # USAGE: shp2pgsql [<options>] <shapefile> [[<schema>.]<table>]
  # OPTIONS:
  #   -s [<from>:]<srid> Set the SRID field. Defaults to 0.
  #       Optionally reprojects from given SRID (cannot be used with -D).
  #  (-d|a|c|p) These are mutually exclusive options:
  #      -d  Drops the table, then recreates it and populates
  #          it with current shape file data.
  #      -a  Appends shape file into current table, must be
  #          exactly the same table schema.
  #      -c  Creates a new table and populates it, this is the
  #          default if you do not specify any options.
  #      -p  Prepare mode, only creates the table.
  #   -g <geocolumn> Specify the name of the geometry/geography column
  #       (mostly useful in append mode).
  #   -D  Use postgresql dump format (defaults to SQL insert statements).
  #   -e  Execute each statement individually, do not use a transaction.
  #       Not compatible with -D.
  #   -G  Use geography type (requires lon/lat data or -r to reproject).
  #   -k  Keep postgresql identifiers case.
  #   -i  Use int4 type for all integer dbf fields.
  #   -I  Create a spatial index on the geocolumn.
  #   -S  Generate simple geometries instead of MULTI geometries.
  #   -t <dimensionality> Force geometry to be one of '2D', '3DZ', '3DM', or '4D'
  #   -w  Output WKT instead of WKB.  Note that this can result in
  #       coordinate drift.
  #   -W <encoding> Specify the character encoding of Shape's
  #       attribute column. (default: "UTF-8")
  #   -N <policy> NULL geometries handling policy (insert*,skip,abort).
  #   -n  Only import DBF file.
  #   -T <tablespace> Specify the tablespace for the new table.
  #       Note that indexes will still use the default tablespace unless the
  #       -X flag is also used.
  #   -X <tablespace> Specify the tablespace for the table's indexes.
  #       This applies to the primary key, and the spatial index if
  #       the -I flag is used.
  #   -?  Display this help screen.

  def main layer, flags, format = :shapefile
    druid = layer[:druid]
    zipfn = layer[:zipfn]
    projection = layer[:projection] || flags[:projection]
    schema = layer[:schema] || flags[:schema]
    encoding = layer[:encoding] || flags[:encoding]

    raise NotImplementedError, "Unsupported format: #{format}" unless format == :shapefile

    Dir.mktmpdir('shp', druid.temp_dir) do |d|
      begin
        system("unzip -oj '#{zipfn}' -d '#{d}'")
        system("ls -la #{d}")
        Dir.glob("#{d}/*.shp") do |shp|
          # XXX: HARD CODED projection here -- extract from MODS or ISO19139
          # XXX: Perhaps put the .sql data into the content directory as .zip for derivative
          # XXX: -G for the geography column causes some issues with GeoServer
          system("shp2pgsql -s #{projection} -d -D -I -W #{encoding}" +
                 " '#{shp}' #{schema}.#{druid.id} " +
                 "> '#{druid.temp_dir}/#{druid.id}.sql'")
          system('psql --no-psqlrc --no-password --quiet ' +
                 "--file='#{druid.temp_dir}/#{druid.id}.sql' ")
        end
      rescue Exception => e
        FileUtils.rm_rf(d) if File.exist?(d)
      end
    end
  end

  # locates the data.zip file, preferring one with explicit projection
  def druid2layer druid, flags
    ap({:druid => druid}) if flags[:debug]

    zipfn = nil
    projection = nil
    %w{4326}.each do |prj|
      Dir.glob(File.join(druid.content_dir, "data_EPSG_#{prj}.zip")) do |fn|
        puts "Found EPSG #{prj} zip: #{fn}" if flags[:verbose]
        projection = prj
        zipfn = fn
      end
    end
    
    if zipfn.nil?
      Dir.glob(File.join(druid.content_dir, 'data.zip')) do |fn|
        puts "Found native zip: #{fn}" if flags[:verbose]
        zipfn = fn
        projection = '4326' # XXX: Hardcoded assumption that native work is in WGS84 if missing derived work
      end
    end

    raise ArgumentError, "Missing data ZIP file: #{zipfn}" unless File.exist?(zipfn)
    raise ArgumentError, "Missing Projection" if projection.nil?
    ap({:zipfn => zipfn}) if flags[:debug]

    { 
      :druid => druid,
      :zipfn => zipfn,
      :projection => projection
    }
  end

  def run(args)
    flags = {
      :encoding => 'UTF-8',
      :workspacedir => GeoHydra::Config.geohydra.workspace || 'workspace',
      :schema => GeoHydra::Config.postgis.schema || 'druid'
    }
  
    OptionParser.new do |opts|
      opts.banner = "
  Usage: #{File.basename(__FILE__)} [-v] [druid ... | < druids]
"
      opts.on('-v', '--verbose', 'Run verbosely, use multiple times for debug level output') do
        flags[:debug] = true if flags[:verbose]  # -vv
        flags[:verbose] = true
      end
      opts.on('--workspace DIR', "Workspace directory for assembly (default: #{flags[:workspacedir]})") do |v|
        flags[:workspacedir] = v
      end

      %w{schema encoding}.each do |k|
        opts.on("--#{k} #{k.upcase}", "PostGIS #{k} (default: #{flags[k.to_sym]})") do |v|
          flags[k.to_sym] = v
        end
      end
    end.parse!(args)

    ap({:flags => flags}) if flags[:debug]
      
    (args.size > 0 ? args : $stdin).each do |s|
      druid = DruidTools::Druid.new(s.strip, flags[:workspacedir])
      main(druid2layer(druid, flags), flags)
    end
  end
end

# __MAIN__
LoaderPostGIS.new.run(ARGV)
