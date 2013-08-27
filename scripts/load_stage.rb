#!/usr/bin/env ruby

require 'fileutils'
require 'druid-tools'

Dir.chdir('/var/geomdtk/current/stage')
puts 'scanning upload/druid for zips'
Dir.glob(File.join('/var/geomdtk/current/upload/druid/**/*.zip')) do |zipfn|
  druid = DruidTools::Druid.new(File.basename(File.dirname(File.dirname(zipfn))))
  FileUtils.ln_sf(zipfn, "#{druid.id}.zip", :verbose => true)
end

Dir.glob(File.join('/var/geomdtk/current/upload/druid/**/temp/*-iso19139.xml')) do |xmlfn|
  druid = DruidTools::Druid.new(File.basename(File.dirname(File.dirname(xmlfn))))
  FileUtils.ln_sf(File.expand_path(xmlfn), "#{druid.id}.xml", :verbose => true)
end

Dir.glob(File.join('/var/geomdtk/current/upload/druid/**/temp/geoOptions.json')) do |optfn|
  druid = DruidTools::Druid.new(File.basename(File.dirname(File.dirname(optfn))))
  FileUtils.ln_sf(File.expand_path(optfn), "#{druid.id}.json", :verbose => true)
end
