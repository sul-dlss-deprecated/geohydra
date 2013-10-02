#!/usr/bin/env ruby

require 'json'

n = 0
puts '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
Dir.glob('/Volumes/Geo3TB/document_cache/??/???/??/????/mods') do |fn|
  # puts fn
  if fn =~ %r{(../\d\d\d/../\d\d\d\d)/mods$}
    druid = $1.gsub(/\//, '')
  else 
    raise ArgumentError, fn
  end
  s = File.read(fn)
  if s =~ %r{(<subject>\s*<cartographics>.*<coordinates>.*</coordinates>.*</cartographics>\s*</subject>)}mi
    puts "<rdf:Description rdf:about=\"#{druid}\">"
    puts $1
    puts '</rdf:Description>'
    n = n + 1
  end
end
puts '</rdf:RDF>'
STDERR.puts "Wrote #{n} records"