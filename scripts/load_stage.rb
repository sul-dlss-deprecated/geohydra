#!/usr/bin/env ruby
#
srcdir='/var/geomdtk/current/upload/druid'
Dir.glob(File.join(srcdir, '**', '*.zip')) do |zipfn|
  druid = File.basename(File.dirname(File.dirname(zipfn)))
  system("ln -s #{zipfn} #{druid}.zip")
  Dir.glob(File.join(File.dirname(zipfn), '..', '**', '*-iso19139.xml')) do |xmlfn|
    system("ln -s #{xmlfn} #{druid}.xml")
  end
end
