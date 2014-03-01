#!/usr/bin/env ruby
#
# Usage: transform_ogp output.json
#
#  Reads valid*.json in current directory
#

require 'awesome_print'
require 'json'
require 'uri'
require 'date'

# Transforms an OGP schema into GeoBlacklight. Requires input of a JSON array
# of OGP hashs.
class TransformOgp
  KNOWN_KEYWORDS = [
    'United States',
    'North America',
    'North Pacific Ocean',
    'North Atlantic Ocean',
    'South Atlantic Ocean',
    'Gulf of Mexico',
    'San Francisco Bay Area',
    'San Francisco',
    'Indian Ocean',
    'Pacific Ocean',
    'Atlantic Ocean',
    'Soviet Union',
    'Antarctic Ocean',
    'New York',
    'New Mexico',
    'Latin America',
    'New Hampshire',
    'New England',
    'United Arab Emirates',
    'New York (State)',
    'Great Lakes Region (North America)',
    'British Columbia'
  ]
  def initialize(fn)
    @output = File.open(fn, 'wb')
    @output.write "[\n"
    yield self
    self.close
  end
  
  # @param [String|Array] s the URI to clean up
  # @return [String] a normalized URI
  def clean_uri(s)
    unless s.nil? or s.empty?
      return (s.is_a?(Array) ? URI(s.first) : URI(s)).to_s
    end
    ''
  end

  # @param [String] fn filename of JSON array of OGP hash objects
  # @return [Hash] stats about :accepted vs. :rejected records
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

  # Transforms a single OGP record into a GeoBlacklight record
  # @param [Hash] layer an OGP hash for a given layer
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
    
    # Parse out the Location to get the WMS/WFS/WCS URLs
    raise ArgumentError, "ERROR: #{id} no location" if layer['Location'].nil? or layer['Location'].empty?
    location = JSON::parse(layer['Location'])
    raise ArgumentError, "ERROR: #{id} has malformed location" unless location.is_a? Hash
    
    # Parse out the bounding box
    s = layer['MinY'].to_f
    w = layer['MinX'].to_f
    n = layer['MaxY'].to_f
    e = layer['MaxX'].to_f
    
    # Parse out the ContentDate date/time
    dt = DateTime.rfc3339(layer['ContentDate'])
    
    # Parse out the PURL and other metadata for Stanford
    if layer['Institution'] == 'Stanford'
      access = 'Restricted' # always restricted, XXX: fake data if really Public
      collection = 'My Collection' # XXX: need to parse out of MODS
      preview_jpg = "https://stacks.stanford.edu/file/druid:#{id}/preview.jpg"
      purl = location['purl']
      if purl.is_a? Array
        purl = purl.first
      end
      if purl.nil? and uuid =~ /^http/
        purl = uuid
      end
    else
      access = layer['Access']
      collection = ''
      preview_jpg = ''
      purl = ''      
    end
    
    # Make the conversion from OGP to GeoBlacklight
    #
    # @see http://dublincore.org/documents/dcmi-terms/
    # @see http://wiki.dublincore.org/index.php/User_Guide/Creating_Metadata
    # @see http://www.ietf.org/rfc/rfc5013.txt
    new_layer = {
      :uuid               => uuid,
      :dc_coverage_sm     => string2array(layer['PlaceKeywords']),
      # :dc_creator_s       => '', # not used
      :dc_date_dt         => dt.strftime('%FT%TZ'), # Solr requires 1995-12-31T23:59:59Z
      :dc_description_t   => layer['Abstract'],
      :dc_format_s        => (
        layer['DataType'] == 'Raster' ? 
        'GeoTIFF' : # 'image/tiff' : 
        'Shapefile' # 'application/x-esri-shapefile'
      ), # XXX: fake data
      :dc_identifier_s    => uuid,
      :dc_language_s      => 'English', # 'en', # XXX: fake data
      :dc_publisher_s     => layer['Publisher'],
      :dc_relation_url    => purl.empty?? '' : ('IsReferencedBy ' + clean_uri(purl)),
      :dc_rights_s        => access,
      :dc_source_s        => layer['Institution'],
      :dc_subject_sm      => string2array(layer['ThemeKeywords']),
      :dc_title_t         => layer['LayerDisplayName'],
      :dc_type_s          => 'Dataset',
      :layer_bbox         => "#{w} #{s} #{e} #{n}", # minX minY maxX maxY
      :layer_collection_s => collection,
      :layer_geom         => "POLYGON((#{w} #{n}, #{e} #{n}, #{e} #{s}, #{w} #{s}, #{w} #{n}))",
      :layer_id_s         => layer['WorkspaceName'] + ':' + layer['Name'],
      :layer_metadata_url => purl,
      :layer_ne_latlon    => "#{n},#{e}",
      :layer_ne_pt        => "#{e} #{n}",
      :layer_preview_image_url  => preview_jpg,
      :layer_srs_s        => 'EPSG:4326', # XXX: fake data
      :layer_sw_latlon    => "#{s},#{w}",
      :layer_sw_pt        => "#{w} #{s}",
      :layer_type_s       => layer['DataType'].to_s.capitalize,
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

    # For the layer URLs, ensure that they are clean
    %w{layer_wms_url layer_wfs_url layer_wcs_url layer_metadata_url layer_preview_image_url}.each do |k|
      k = k.to_sym
      if new_layer[k].is_a? Array and not new_layer[k].first.nil?
        new_layer[k] = clean_uri(new_layer[k].first)
      else
        new_layer[k] = clean_uri(new_layer[k])
      end
    end

    # Remove any fields that are blank
    new_layer.each do |k, v|
      new_layer.delete(k) if v.nil? or (v.respond_to?(:empty?) and v.empty?)
    end

    # Write the JSON record for the GeoBlacklight layer
    @output.write JSON::pretty_generate(new_layer)
    @output.write "\n,\n"
  end

  def close
    @output.write "\n {} \n]\n"
    @output.close
  end
  
  private
  
  # @param [String] s has semi-colon/comma/gt delimited array
  # @return [Array] results as array
  def string2array(s)
    if KNOWN_KEYWORDS.include?(s)
      s
    elsif s =~ /[;,>]/
      s.split(/\s*[;,>]\s*/).uniq
    else
      s.split.first # only extract first word
    end
  end

  # Ensure that the WMS/WFS/WCS location values are as expected
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
#
TransformOgp.new(ARGV[0].nil?? 'transformed.json' : ARGV[0]) do |ogp|
  stats = { :accepted => 0, :rejected => 0 }
  Dir.glob('valid*.json') do |fn|
    s = ogp.transform_file(fn)
    stats[:accepted] += s[:accepted]
    stats[:rejected] += s[:rejected]
  end
  ap({:statistics => stats})
end

# example input data
__END__
[
{
  "Abstract": "The boundaries of each supervisorial district in Sonoma County based on 2000 census. Redrawn in 2001 using Autobound.",
  "Access": "Public",
  "Area": 0.9463444815860053,
  "Availability": "Online",
  "CenterX": -122.942159,
  "CenterY": 38.4580755,
  "ContentDate": "2000-01-01T01:01:01Z",
  "DataType": "Polygon",
  "FgdcText": "...",
  "GeoReferenced": true,
  "HalfHeight": 0.39885650000000084,
  "HalfWidth": 0.593161000000002,
  "Institution": "Berkeley",
  "LayerDisplayName": "SCGISDB2_BASE_ADM_SUPERVISOR",
  "LayerId": "28722/bk0012h5s52",
  "Location": "{\"wms\":[\"http://gis.lib.berkeley.edu:8080/geoserver/wms\"],\"tilecache\":[\"http://gis.lib.berkeley.edu:8080/geoserver/gwc/service/wms\"],\"download\":\"\",\"wfs\":[\"http://gis.lib.berkeley.edu:8080/geoserver/wfs\"]}",
  "MaxX": -122.348998,
  "MaxY": 38.856932,
  "MinX": -123.53532,
  "MinY": 38.059219,
  "Name": "ADM_SUPERVISOR",
  "PlaceKeywords": "Sonoma County County of Sonoma Sonoma California Bay Area",
  "Publisher": "UC Berkeley Libraries",
  "ThemeKeywords": "Supervisorial districts 1st District 2nd District 3rd District 4th District 5th District",
  "WorkspaceName": "UCB"
}
]
