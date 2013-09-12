#!/usr/bin/env ruby
require 'fileutils'
Dir.glob('/var/geohydra/current/workspace-prod/**/{geo,desc}Metadata.xml') do |fn|
  druid = File.basename(File.dirname(File.dirname(fn)))
  FileUtils.cp fn, [druid, File.basename(fn)].join('_')
end
