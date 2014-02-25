#!/usr/bin/env ruby

require 'awesome_print'
require 'json'
require 'uri'
require 'date'

class TransformOgp
  def initialize(fn)
    @output = File.open(fn, 'wb')
    @output.write "[\n"
    yield self
    self.close
  end
  
  def clean_uri(s)
    unless s.nil? or s.empty?
      return (s.is_a?(Array) ? URI(s.first) : URI(s)).to_s
    end
    ''
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

    prefix = case layer['Institution']
    when 'Stanford'
      'purl.stanford.edu'
    when 'Tufts'
      'geodata.tufts.edu'
    when 'MassGIS'
      'massgis.state.ma.us'
    when 'Berkeley'
      'gis.lib.berkeley.edu'
    when 'MIT'
      'arrowsmith.mit.edu'
    when 'Harvard'
      'hul.harvard.edu'
    else
      ''
    end
    uuid = 'urn:' + prefix + ':' + URI.encode(id)
    
    raise ArgumentError, "ERROR: #{id} no location" if layer['Location'].nil? or layer['Location'].empty?
    location = JSON::parse(layer['Location'])
    raise ArgumentError, "ERROR: #{id} has malformed location" unless location.is_a? Hash
    
    s = layer['MinY'].to_f
    w = layer['MinX'].to_f
    n = layer['MaxY'].to_f
    e = layer['MaxX'].to_f
    
    dt = DateTime.rfc3339(layer['ContentDate'])
    
    new_layer = {
      :uuid => uuid,
      # :dc_contributor_s => nil,
      :dc_coverage_sm => splitter(layer['PlaceKeywords']),
      :dc_creator_t => layer['Publisher'], # XXX: fake data
      :dc_date_dt => dt.strftime('%FT%TZ'), # Solr requires 1995-12-31T23:59:59Z
      :dc_date_it => dt.year, # XXX: migrate to copyField
      :dc_description_t => layer['Abstract'],
      :dc_format_s => (layer['DataType'] == 'Raster' ? 'image/tiff' : 'application/x-esri-shapefile'), # XXX: fake data
      :dc_identifier_s => uuid,
      :dc_language_s => 'en', # XXX: fake data
      :dc_publisher_t => layer['Publisher'],
      :dc_relation_url => location['purl'].nil?? '' : ('IsReferencedBy ' + clean_uri(location['purl'])),
      :dc_rights_s => (layer['Institution'] == 'Stanford' ? 'Restricted' : layer['Access']), # XXX: fake data for Stanford -- always restricted
      :dc_source_s => layer['Institution'],
      :dc_subject_sm => splitter(layer['ThemeKeywords']),
      :dc_title_t => layer['LayerDisplayName'],
      :dc_type_s => 'Dataset',
      :layer_id_s => layer['WorkspaceName'] + ':' + layer['Name'],
      :layer_name_s => layer['Name'],
      :layer_collection_s => 'My Collection', # XXX: fake data
      :layer_srs_s => 'EPSG:4326', # XXX: fake data
      :layer_type_s => layer['DataType'],
      :layer_ne_latlon => "#{n},#{e}",
      :layer_sw_latlon => "#{s},#{w}",
      :layer_ne_pt => "POINT(#{e} #{n})",
      :layer_sw_pt => "POINT(#{w} #{s})",
      :layer_bbox => "POLYGON((#{w} #{n}, #{e} #{n}, #{e} #{s}, #{w} #{s}, #{w} #{n}))",
      :layer_wms_url => clean_uri(location['wms']),
      :layer_wfs_url => clean_uri(location['wfs']),
      :layer_wcs_url => clean_uri(location['wcs']),
      :layer_metadata_url => clean_uri(location['purl']),
      :layer_preview_url => location['purl'].nil?? '' : (clean_uri(location['purl']) + '/preview.jpg'),
      :layer_workspace_s => layer['WorkspaceName']
    }

    new_layer.each do |k, v|
      new_layer[k] = '' if v.nil? or (v.respond_to?(:empty?) and v.empty?)
    end

    %w{dc_relation_url layer_wms_url layer_wfs_url layer_wcs_url}.each do |k|
      k = k.to_sym
      if new_layer[k].is_a? Array and not new_layer[k].first.nil?
        new_layer[k] = clean_uri(new_layer[k].first)
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
              uri = clean_uri.parse(url)
              raise ArgumentError, "ERROR: #{id}: Invalid URL: #{uri}" unless uri.kind_of?(clean_uri::HTTP) or uri.kind_of?(clean_uri::HTTPS)
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
