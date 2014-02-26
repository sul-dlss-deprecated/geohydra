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

    # For URN style @see http://www.ietf.org/rfc/rfc2141.txt
    # For ARK @see https://wiki.ucop.edu/display/Curation/ARK
    prefix = case layer['Institution']
    when 'Stanford'
      'http://purl.stanford.edu/'
    when 'Tufts'
      'urn:geodata.tufts.edu:'
    when 'MassGIS'
      'urn:massgis.state.ma.us:'
    when 'Berkeley'
      'http://ark.cdlib.org/ark:/'
    when 'MIT'
      'urn:arrowsmith.mit.edu:'
    when 'Harvard'
      'urn:hul.harvard.edu:'
    else
      ''
    end
    uuid = prefix + URI.encode(id)
    
    raise ArgumentError, "ERROR: #{id} no location" if layer['Location'].nil? or layer['Location'].empty?
    location = JSON::parse(layer['Location'])
    raise ArgumentError, "ERROR: #{id} has malformed location" unless location.is_a? Hash
    
    s = layer['MinY'].to_f
    w = layer['MinX'].to_f
    n = layer['MaxY'].to_f
    e = layer['MaxX'].to_f
    
    dt = DateTime.rfc3339(layer['ContentDate'])
    
    purl = location['purl']
    if purl.is_a? Array
      purl = purl.first
    end
    if purl.nil? and uuid =~ /^http/
      purl = uuid
    end
    
    # @see http://dublincore.org/documents/dcmi-terms/
    # @see http://wiki.dublincore.org/index.php/User_Guide/Creating_Metadata
    # @see http://www.ietf.org/rfc/rfc5013.txt
    new_layer = {
      :uuid               => uuid,
      :dc_coverage_sm     => splitter(layer['PlaceKeywords']),
      :dc_creator_t       => '',#layer['Publisher'], # XXX: fake data
      :dc_date_dt         => dt.strftime('%FT%TZ'), # Solr requires 1995-12-31T23:59:59Z
      :dc_description_t   => layer['Abstract'],
      :dc_format_s        => (layer['DataType'] == 'Raster' ? 'image/tiff' : 'application/x-esri-shapefile'), # XXX: fake data
      :dc_identifier_s    => uuid,
      :dc_language_s      => 'en', # XXX: fake data
      :dc_publisher_t     => layer['Publisher'],
      :dc_relation_url    => purl.nil?? '' : ('IsReferencedBy ' + clean_uri(purl)),
      :dc_rights_s        => (layer['Institution'] == 'Stanford' ? 'Restricted' : layer['Access']), # XXX: fake data for Stanford -- always restricted
      :dc_source_s        => layer['Institution'],
      :dc_subject_sm      => splitter(layer['ThemeKeywords']),
      :dc_title_t         => layer['LayerDisplayName'],
      :dc_type_s          => 'Dataset',
      :layer_bbox         => "#{w} #{s} #{e} #{n}", # minX minY maxX maxY
      :layer_collection_s => (layer['Institution'] == 'Stanford' ? 'My Collection' : ''), # XXX: fake data
      :layer_geom         => "POLYGON((#{w} #{n}, #{e} #{n}, #{e} #{s}, #{w} #{s}, #{w} #{n}))",
      :layer_id_s         => layer['WorkspaceName'] + ':' + layer['Name'],
      :layer_metadata_url => (layer['Institution'] == 'Stanford' ? purl : ''),
      :layer_ne_latlon    => "#{n},#{e}",
      :layer_ne_pt        => "#{e} #{n}",
      :layer_preview_image_url  => (layer['Institution'] == 'Stanford' ? "https://stacks.stanford.edu/file/druid:#{id}/preview.jpg" : ''),
      :layer_srs_s        => 'EPSG:4326', # XXX: fake data
      :layer_sw_latlon    => "#{s},#{w}",
      :layer_sw_pt        => "#{w} #{s}",
      :layer_type_s       => layer['DataType'],
      :layer_wcs_url      => location['wcs'],
      :layer_wfs_url      => location['wfs'],
      :layer_wms_url      => location['wms'],
      :layer_year_i       => dt.year, # XXX: migrate to copyField
      :ogp_area_f         => layer['Area'],
      :ogp_center_x_f     => layer['CenterX'],
      :ogp_center_y_f     => layer['CenterY'],
      :ogp_georeferenced_b   => (layer['GeoReferenced'].to_s.downcase == 'true'),
      :ogp_halfheight_f   => layer['HalfHeight'],
      :ogp_halfwidth_f    => layer['HalfWidth'],
      :ogp_layer_id_s     => layer['LayerId'],
      :ogp_name_s         => layer['Name'],
      :ogp_location_s     => layer['Location'],
      :ogp_workspace_s    => layer['WorkspaceName']
    }

    %w{layer_wms_url layer_wfs_url layer_wcs_url layer_metadata_url layer_preview_image_url}.each do |k|
      k = k.to_sym
      if new_layer[k].is_a? Array and not new_layer[k].first.nil?
        new_layer[k] = clean_uri(new_layer[k].first)
      else
        new_layer[k] = clean_uri(new_layer[k])
      end
    end

    new_layer.each do |k, v|
      new_layer.delete(k) if v.nil? or (v.respond_to?(:empty?) and v.empty?)
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
