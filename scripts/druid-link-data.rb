#!/usr/bin/env ruby
require 'csv'
#require 'awesome_print'

CSV.foreach('metadata/GISLayers 20140108.csv') do |row|
  name = row[0].gsub(' ', '_')
  name.gsub!(%r{[_ ]}, '?')

  druid = row[2]

  srcdir = row[5]
  srcdir.gsub!(%r{^Q:/GIS_Shared/GIS_Lab/DATA/}, '')
  srcdir.gsub!(%r{[_ ]}, '?')

  #puts({:druid => druid, :name => name, :srcdir => srcdir})

  Dir.glob("data/original/#{srcdir}/#{name}*").each do |fn|
    next if fn =~ /.shp.xml$/
    #puts({:fn => fn, :destdir => "druid/#{druid}/temp"})
    puts("ln -sf \"`pwd`/#{fn}\" druid-20140108/#{druid}/temp")
  end
end
#Q:/GIS_Shared/GIS_Lab/DATA/
