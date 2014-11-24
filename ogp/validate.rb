#!/usr/bin/env ruby
#
# Usage: validate_ogp [output.json]
#
#  Requires data/*.json as input and output to valid.json
#
require 'awesome_print'
require 'json'
require 'uri'
require 'date'

class ValidateOgp
  def initialize(fn)
    @wms_servers = {}
    @output = File.open(fn, 'wb')
    @output.write "[\n"
    yield self
    self.close
  end

  def validate_file(fn)
    stats = { :accepted => 0, :rejected => 0 }
    puts "Validating #{fn}"
    json = JSON::parse(File.read(fn))
    json['response']['docs'].each do |doc| # contains JSON Solr query results
      begin
        validate(doc)
        stats[:accepted] += 1
      rescue ArgumentError => e
        puts e
        stats[:rejected] += 1
      end
    end
    stats
  end


  def validate(layer)
    id = layer['LayerId']

    %w{LayerId Name Institution Access MinX MinY MaxX MaxY LayerDisplayName}.each do |k|
      if layer[k].nil? || layer[k].to_s.empty?
        raise ArgumentError, "ERROR: #{id} missing #{k}"
        return
      end
    end
    
    k = 'LayerId'
    raise ArgumentError, "ERROR: #{k} is not a String" unless layer[k].is_a? String
    
    %w{MinX MaxX}.each do |lon|
      raise ArgumentError, "ERROR: #{id}: Invalid longitude value: #{layer[lon]}" unless lon?(layer[lon])
    end

    
    %w{MinY MaxY}.each do |lat|
      raise ArgumentError, "ERROR: #{id} Invalid latitude value: #{layer[lat]}" unless lat?(layer[lat])
    end
    
    k = 'Institution'
    if ([layer[k]] & %w{Berkeley Harvard MIT MassGIS Stanford Tufts UCLA Minnesota Columbia Columbia\ University}).empty?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
      return
    end

    k = 'DataType'
    if ([layer[k]] & %w{Line Paper\ Map Point Polygon Raster LibraryRecord}).empty?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
      return
    end

    k = 'Access'
    if ([layer[k]] & %w{Public Restricted}).empty?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
    end

    k = 'WorkspaceName'
    if layer[k].nil?
      layer[k] = layer['Institution']
    end

    k = 'Availability'
    if layer[k].downcase == 'online' # cleanup 
      layer[k] = 'Online'
    end
    if layer[k].downcase == 'offline'
      layer[k] = 'Offline'
    end
    if ([layer[k]] & %w{Online Offline}).empty?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
      return
    end

    k = 'Location'
    layer[k] = validate_location(id, layer[k])
    if layer[k].nil?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
    end

    k = 'GeoReferenced'
    unless layer[k].nil? or layer[k] == true
      puts "WARNING: #{id} has boundingbox but claims it is not georeferenced"
      #layer[k] = true
    end
    
    k = 'Area'
    unless layer[k].to_i >= 0
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
    end
    
    k = 'ContentDate'
    if layer[k].nil? or layer[k].empty?
      raise ArgumentError, "ERROR: #{id} has unsupported #{k}: #{layer[k]}"
    end
    dt = Date.rfc3339(layer[k])
    if dt.year < 1500 or dt.year > 2100
      raise ArgumentError, "ERROR: #{id} has invalid #{k}: #{layer[k]}"
    end
    
    # k = 'FgdcText'
    # unless layer[k].nil? or layer[k].empty?
    #   layer[k] = ''
    # end

    @output.write JSON::pretty_generate(layer)
    @output.write "\n,\n"
  end

  def close
    @output.write "\n {} \n]\n"
    @output.close
    ap({:wms_servers => @wms_servers})
  end
  
  private
  
  def validate_location(id, location)
    begin
      x = JSON::parse(location)
      unless x['externalDownload'].nil?
        x['download'] = x['externalDownload']
        x.delete('externalDownload')
      end
      unless x['libRecord'].nil?
        x['url'] = x['libRecord']
        x.delete('libRecord')
      end
      # if x['download'].nil? && x['wms'].nil? && (x['wcs'].nil? && x['wfs'].nil?) && x['url'].nil?
      #   raise ArgumentError, "ERROR: #{id}: Missing Download or WMS or WCS/WFS: #{x}"
      # end
      
      %w{download wms wcs wfs url}.each do |protocol|
        begin
          unless x[protocol].nil?
            if x[protocol].is_a? String
              x[protocol] = [x[protocol]]
            end
            
            unless x[protocol].is_a? Array
              raise ArgumentError, "ERROR: #{id}: Unknown #{protocol} value: #{x}"
            end
            
            x[protocol].each do |url|
              uri = URI.parse(url)
              raise ArgumentError, "ERROR: #{id}: Invalid URL: #{uri}" unless uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
            end
            
            # convert from Array to String
            x[protocol] = x[protocol].first
          end
        rescue Exception => e
          raise ArgumentError, "ERROR: #{id}: Invalid key #{protocol}: #{x}"
        end        
      end
      
      @wms_servers[x['wms']] = true      

      return x.to_json
    rescue JSON::ParserError => e
      raise ArgumentError, "ERROR: #{id}: Invalid JSON in Location: #{location}"
    end
    nil
  end
  
  def lon? lon
    lon >= -180 and lon <= 180
  end
  
  def lat? lat
    lat >= -90 and lat <= 90
  end
end


# __MAIN__
ValidateOgp.new(ARGV[0].nil?? 'valid.json' : ARGV[0]) do |ogp|
  stats = { :accepted => 0, :rejected => 0 }
  Dir.glob('data/*.json') do |fn|
    s = ogp.validate_file(fn)
    stats[:accepted] += s[:accepted]
    stats[:rejected] += s[:rejected]
  end
  ap({:statistics => stats})
end
