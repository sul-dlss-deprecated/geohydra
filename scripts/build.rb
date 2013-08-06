#!/usr/bin/env ruby

require 'csv'
require 'fileutils'
require 'druid-tools'

flags = {
  :base => '/var/geomdtk/current/upload',
  :include_iso19139 => true,
  :debug => true
}

def build(druid, name, flags)
  dp = File.join(flags[:base], 'druid', druid.id)
  %w{metadata content temp}.each do |d| 
    p = File.join(dp, d)
    FileUtils.mkdir_p(p, :verbose => true) unless File.directory?(p)
  end
  p = File.join(flags[:base], 'data', 'ready')
  Dir.glob("#{p}/**/#{name}.*") do |fn|
    FileUtils.ln_s([File.expand_path(fn)], File.join(dp, 'temp'), :verbose => true)
  end
  if flags[:include_iso19139]
    Dir.glob("#{p}/**/#{name}-iso19139*.xml") do |fn|
      FileUtils.ln_s([File.expand_path(fn)], File.join(dp, 'temp'), :verbose => true)
    end
  end
end

puts "ingesting .shp.xml files" if flags[:debug]
system("bundle exec bin/ingest_arcgis.rb -vv #{flags[:base]}/data/ready")
Dir.glob("#{flags[:base]}/data/ready/**/*-iso19139.xml") do |fn|
  puts "<#{fn}>" if flags[:debug]
  IO.popen("xsltproc #{File.dirname(__FILE__)}/extract.xsl #{fn}") do |i|
    puts "<#{i}>" if flags[:debug]
    i.each do |line|
      CSV.parse(line.to_s) do |row|
        druid = DruidTools::Druid.new(row[0].to_s.strip)
        name = row[1].to_s.strip
        build druid, name, flags
      end
    end
  end
end
