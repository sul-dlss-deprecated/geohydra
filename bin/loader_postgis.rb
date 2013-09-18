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

require 'active_record'
require 'active_support'
require 'tmpdir'

class RegisteredLayer < ActiveRecord::Base
  attr_accessible :druid, :layername, :title
  # self.primary_key = 'druid'
  
  def find_by_druid(druid)
    RegisteredLayer.find(:first, :conditions => [ "druid = ?", druid.to_s])
  end
end


# ENV['RGEOSERVER_CONFIG'] ||= ENV_FILE + '_rgeoserver.yml'
# require 'rgeoserver'

#=  Input data. *See DATA section at end of file*
# The input file is in YAML syntax with each record is a Hash with keys:
# - layername
# - filename
# - format
# - title
# and optionally
# - description
# - keywords
# - metadata_links

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

def main conn, layers, flags = {}
  ap({:layers => layers, :flags => flags}) if flags[:debug]
  layers.each do |k, v|
    %w{layername format filename title}.each do |i|
      raise ArgumentError, "Layer is missing required '#{i}'" if v[i.to_sym].nil? or not v.include?(i.to_sym)
    end
    puts "Processing layer #{k}" if flags[:verbose]
  
    layername = v[:layername].strip
    format = v[:format].downcase.strip.to_sym
    druid = v[:druid]
    title = v[:title].strip
      
    case format
    when :shapefile      
      ap({:v => v}) if flags[:debug]
      Dir.mktmpdir('shp', druid.temp_dir) do |d|
        begin
          system("unzip -oj '#{v[:filename]}' -d '#{d}'")
          system("ls -la #{d}")
          Dir.glob("#{d}/*.shp") do |shp|
            # XXX: HARD CODED projection here -- extract from MODS or ISO19139
            # XXX: Perhaps put the .sql data into the content directory as .zip for derivative
            # XXX: -G for the geography column causes some issues with GeoServer
            system("shp2pgsql -s :4326 -I -d '#{shp}' #{flags[:schema]}.#{druid.id} > '#{druid.temp_dir}/#{druid.id}.sql'")
            system('psql --no-psqlrc --no-password ' +
                   "--host='#{flags[:host.to_s]}' " +
                   "--port='#{flags[:port.to_s]}' " +
                   "--username='#{flags[:username.to_s]}' " + 
                   "--dbname='#{flags[:database.to_s]}' " +
                   "--file='#{druid.temp_dir}/#{druid.id}.sql' ")
          end
        rescue Exception => e
          FileUtils.rm_rf(d) if File.exist?(d)
        end
      end
      
      if flags[:register]
        puts "Registering layer #{druid.id}, #{layername}, #{title}" if flags[:verbose]
        layer = RegisteredLayer.find_by_druid druid.id
        ap({:found_layer => layer}) if flags[:debug]
        if layer.nil?
          layer = RegisteredLayer.new( 
            :druid => druid.id,
            :layername => layername,
            :title => title
          )
        end
        layer.layername = layername
        layer.title = title
        ap({:updated_layer => layer}) if flags[:debug]
        layer.save
      end
    else
      raise NotImplementedError, "Unsupported format #{format}"    
    end
  end
end

def from_druid druid, flags
  ap({:druid => druid}) if flags[:debug]
  prj = flags[:projection] || "EPSG:4326"
  prj = prj.split(':').join('_')
  druid = DruidTools::Druid.new(druid, flags[:datadir])
  mods_fn = druid.path('metadata/descMetadata.xml')
  puts "Loading #{mods_fn}" if flags[:verbose]
  mods = Mods::Record.new
  mods.from_url(mods_fn)
  ap({:mods => mods}) if flags[:debug]

  geo_fn = druid.path('metadata/geoMetadata.xml')
  puts "Loading #{geo_fn}" if flags[:verbose]
  geo = Dor::GeoMetadataDS.from_xml(File.read(geo_fn))
  ap({:geo => geo}) if flags[:debug]

  zipfn = nil
  layername = nil
  projection = nil
  Dir.glob(druid.content_dir + "/*_#{prj}.zip") do |fn|
    puts "Found EPSG 4326 zip: #{fn}" if flags[:verbose]
    projection = '4326'
    zipfn = fn
    layername = File.basename(zipfn, "_#{prj}.zip")
    puts "Derived layername #{zipfn} -> #{layername}" if flags[:verbose]
  end
  if not zipfn
    Dir.glob(druid.content_dir + "/*.zip") do |fn|
      zipfn = fn
      layername = File.basename(zipfn, '.zip')
    end
  end
  raise ArgumentError, zipfn unless File.exist?(zipfn) and layername
  ap({:zipfn => zipfn, :layername => layername}) if flags[:verbose]
  r = { 
    :vector => {
      :druid => druid,
      :format => 'Shapefile',
      :layername => layername,
      :filename => zipfn,
      :title => mods.full_titles.first,
      :projection => projection.nil?? '4326' : projection
    }
  }
  r
end

# __MAIN__
begin
  flags = {
    :debug => false,
    :verbose => false,
    :register => false,
    :register_drop => false,
    :register_table => 'registered_layers',
    :datadir => '/var/geomdtk/current/workspace',
    :schema => GeoHydra::Config.postgis.schema || 'public'
  }
  
  OptionParser.new do |opts|
    opts.banner = "
Usage: #{File.basename(__FILE__)} [-v] [druid ... | < druids]
"
    opts.on("-v", "--verbose", "Run verbosely") do |v|
      flags[:debug] = true if flags[:verbose]
      flags[:verbose] = true
    end
    opts.on("-d DIR", "--datadir DIR", "Data directory on GeoServer (default: #{flags[:datadir]})") do |v|
      raise ArgumentError, "Invalid directory #{v}" unless File.directory?(v)
      flags[:datadir] = v
    end    
    opts.on("-R", "--register", "Register shapefile") do |v|
      flags[:register] = true
    end

    %w{schema}.each do |k|
      opts.on("--#{k} #{k.upcase}", "PostGIS #{k} (default: #{flags[k.to_sym]})") do |v|
        flags[k.to_sym] = v
      end
    end
  end.parse!

  ap({:flags => flags}) if flags[:debug]
  dbfn = File.expand_path(File.dirname(__FILE__) + '/../config/database.yml')
  puts "Loading #{dbfn}" if flags[:verbose]
  dbconfig = YAML.load(File.read(dbfn))
  raise ArgumentError, "Missing configuration for environment" unless dbconfig.include?(ENV['GEOHYDRA_ENVIRONMENT'])
  flags.merge! dbconfig[ENV['GEOHYDRA_ENVIRONMENT']]
  ap({:flags => flags}) if flags[:debug]
  
  ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new($stderr) if flags[:debug]
  
  conn = ActiveRecord::Base.establish_connection flags
  conn.with_connection do |db|
    # ap({:obj => db, :klass => db.class, :methods => db.public_methods, :schema_search_path => db.schema_search_path})
    puts "Connected to PostgreSQL #{db.select_value("SHOW server_version")} " +
         "using #{db.current_database} database" if flags[:verbose]
    if db.select_value('select default_version from pg_catalog.pg_available_extensions where name = \'postgis\'') =~ /^(2\.[\.\d]*)$/
      puts "Using PostGIS #{$1}" if flags[:verbose]
    else
      raise NotImplementedError, "Database does not have PostGIS support"
    end
    if flags[:register]
      n = db.select_value("SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' and tablename = '#{flags[:register_table]}'")
      if n.to_i == 0 or flags[:register_drop]
        puts "Creating registry table in public.#{flags[:register_table]}" if flags[:verbose]
        db.execute("DROP TABLE public.#{flags[:register_table]}") if flags[:register_drop]
        db.execute("
          CREATE TABLE public.#{flags[:register_table]}
          (
            druid character varying NOT NULL PRIMARY KEY,
            layername character varying NOT NULL,
            title character varying NOT NULL
          );      
          ")
      end
    end
  end
    
  (ARGV.size > 0 ? ARGV : $stdin).each do |s|
      main(conn, from_druid(s.strip, flags), flags)
  end
end