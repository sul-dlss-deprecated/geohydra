#!/usr/bin/env ruby

require 'awesome_print'
require 'json'
require 'uri'

class TransformOgp
  def initialize(fn)
    @output = File.open(fn, 'wb')
    @output.write "[\n"
    yield self
    self.close
  end

  def transform_file(fn)
    stats = { :accepted => 0, :rejected => 0 }
    puts "Parsing #{fn}"
    json = JSON::parse(File.read(fn))
    json.each do |doc| # contains JSON Solr query results
      unless doc.empty?
	begin
	  transform(doc)
	  stats[:accepted] += 1
	rescue ArgumentError => e
	  puts e
	  stats[:rejected] += 1
	end
      end
    end
    stats
  end

  def transform(layer)
    id = layer['LayerId'].to_s.strip
    puts "Tranforming #{id}"
    
    raise ArgumentError, "ERROR: #{id} no location" if layer['Location'].nil? or layer['Location'].empty?
    location = JSON::parse(layer['Location'])
    raise ArgumentError, "ERROR: #{id} has malformed location" unless location.is_a? Hash
    
    s = layer['MinY'].to_f
    w = layer['MinX'].to_f
    n = layer['MaxY'].to_f
    e = layer['MaxX'].to_f
    new_layer = {
      # :dc_contributor_s => nil,
      :dc_coverage_sm => splitter(layer['PlaceKeywords']),
      # :dc_creator_s => nil,
      :dc_date_dt => layer['ContentDate'],
      :dc_description_t => layer['Abstract'],
      :dc_format_s => "Dataset##{layer['DataType']}",
      :dc_identifier_s => (layer['Insititution'] == 'Stanford' ? "edu.stanford.purl:druid:#{id}" : id),
      :dc_language_s => "en",
      :dc_publisher_s => layer['Publisher'],
      :dc_relation_url => location['purl'],
      :dc_rights_s => layer['Access'],
      :dc_source_s => layer['Institution'],
      :dc_subject_sm => splitter(layer['ThemeKeywords']),
      :dc_title_s => layer['LayerDisplayName'],
      # :dc_type_s => nil,
      :layer_id => id,
      :layer_nw_latlon => "#{n},#{w}",
      :layer_se_latlon => "#{s},#{e}",
      # :layer_nw_pt => "POINT(#{w} #{n})",
      # :layer_se_pt => "POINT(#{e} #{s})",
      # :layer_bbox => "POLYGON((#{w} #{n}, #{e} #{n}, #{e} #{s}, #{w} #{s}, #{w} #{n}))",
      :layer_wms_url => location['wms'],
      :layer_wfs_url => location['wfs'],
      :layer_wcs_url => location['wcs'],
      :layer_metadata_url => location['purl'],
      :layer_workspace_s => layer['WorkspaceName']
    }

    new_layer.each do |k, v|
      new_layer[k] = '' if v.nil? or v.empty?
    end

    %w{dc_relation_url layer_wms_url layer_wfs_url layer_wcs_url}.each do |k|
      k = k.to_sym
      if new_layer[k].is_a? Array
        new_layer[k] = URI(new_layer[k].first)
      end
    end

    @output.write JSON::pretty_generate(new_layer)
    @output.write "\n,\n"
  end

  def close
    @output.write "\n {} \n]\n"
    @output.close
  end
  
  private
  
  def splitter(s)
    a = s.split(/\s*;\s*/)
    if a.size == 1
      a = s.split(a.first)
    end
    a
  end

  def validate_location(id, location)
    begin
      x = JSON::parse(location)
      if x['wms'].nil? or (x['wcs'].nil? and x['wfs'].nil?)
        raise ArgumentError, "ERROR: #{id}: Missing WMS or WCS/WFS: #{x}"
      end
      
      %w{wms wcs wfs}.each do |protocol|
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
          end
        rescue Exception => e
          raise ArgumentError, "ERROR: #{id}: Invalid #{k}: #{x}"
        end        
      end
      
      return x.to_json
    rescue JSON::ParserError => e
      raise ArgumentError, "ERROR: #{id}: Invalid JSON: #{location}"
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
TransformOgp.new(ARGV[0].nil?? 'transformed.json' : ARGV[0]) do |ogp|
  stats = { :accepted => 0, :rejected => 0 }
  Dir.glob('valid*.json') do |fn|
    s = ogp.transform_file(fn)
    stats[:accepted] += s[:accepted]
    stats[:rejected] += s[:rejected]
  end
  ap({:statistics => stats})
end
