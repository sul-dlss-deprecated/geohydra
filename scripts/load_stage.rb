#!/usr/bin/env ruby

require 'fileutils'
require 'druid-tools'

Dir.chdir('/var/geomdtk/current/stage')
Dir.glob(File.join('/var/geomdtk/current/upload/druid/**/*.zip')) do |zipfn|
  druid = DruidTools::Druid.new(File.basename(File.dirname(File.dirname(zipfn))))
  FileUtils.ln(zipfn, "#{druid.id}.zip", :verbose => true)
  Dir.glob(File.join(File.dirname(zipfn), '..', '**', '*-iso19139.xml')) do |xmlfn|
    FileUtils.ln(File.expand_path(xmlfn), "#{druid.id}.xml", :verbose => true)
  end
end
