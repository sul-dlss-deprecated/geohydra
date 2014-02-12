#!/usr/bin/env ruby

require 'awesome_print'
require 'json'

class ValidateOgp
  def initialize(fn)
    @output = File.open(fn, 'wb')
    @output.write "[\n"
    yield self
    self.close
  end

  def validate_file(fn)
    puts "Validating #{fn}"
    json = JSON::parse(File.read(fn))
    json['response']['docs'].each do |doc|
      validate(doc)
    end
    json['response']['docs'].length
  end

  def validate(layer)
    id = layer['LayerId']
    return if id.nil?

    %w{MinX MinY MaxX MaxY LayerDisplayName}.each do |k|
      if layer[k].nil? or layer[k].to_s.empty?
        puts "#{id} missing #{k}"
        return
      end
    end

    k = 'GeoReferenced'
    unless layer[k].nil? or layer[k] == true
      puts "WARNING: #{id} has boundingbox but claims it is not georeferenced"
      #layer[k] = true
    end

    @output.write JSON::pretty_generate(layer)
    @output.write "\n,\n"
  end

  def close
    @output.write "\nnil]\n"
    @output.close
  end
end


# __MAIN__
ValidateOgp.new('out.json') do |ogp|
  Dir.glob("data/*.json") do |fn|
    ogp.validate_file(fn)
  end
end
