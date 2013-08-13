#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require 'active_record'
require 'active_support'
flags = {
  :verbose => true,
  :debug => true,
  :schema => 'druid',
  :geowrite => 'geostaff',
  :georead => 'georead'
}

ap({:flags => flags}) if flags[:debug]
flags.merge! YAML.load(File.read(File.dirname(__FILE__) + '/../config/database.yml'))[ENV['GEOMDTK_ENVIRONMENT']||'development']
ap({:flags => flags}) if flags[:debug]

conn = ActiveRecord::Base.establish_connection flags
conn.with_connection do |db|
  db.execute("GRANT ALL ON SCHEMA #{flags[:schema]} TO #{flags[:geowrite]}")
  db.execute("GRANT USAGE ON SCHEMA #{flags[:schema]} TO #{flags[:georead]}")
end

