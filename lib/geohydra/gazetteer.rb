# encoding: UTF-8

require 'csv'
require 'awesome_print'

module GeoHydra
  class Gazetteer
    
    CSV_FN = File.join(File.dirname(__FILE__), 'gazetteer.csv')
    
    def initialize
      @registry = {}
      n = 0
      CSV.foreach(CSV_FN, :encoding => 'UTF-8') do |v|
        n += 1
        next if n == 1
        k = v[0].to_s.strip
        k = v[1].to_s.strip if k.nil? or k.empty?
        @registry[k] = {
          :geonames_placename => v[1].to_s.strip,
          :geonames_id => v[2].to_i,
          :loc_name => v[3].to_s.strip,
          :loc_id => v[4]
        }
      end
    end
    
    def _get(k, i)
      return nil unless @registry.include?(k)
      @registry[k][i]
    end
    
    def each
      @registry.each_key {|k| yield k }
    end

    # @return [String] geonames name
    def find_placename_by_keyword(k)
      _get(k, :geonames_placename)
    end
    
    # @return [Integer] geonames id
    def find_id_by_keyword(k)
      _get(k, :geonames_id)
    end

    # @return [String] library of congress name
    def find_lc_by_keyword(k)
      _get(k, :loc_name)
    end
    
    # @return [String] library of congress valueURI
    def find_lcuri_by_keyword(k)
      lcid = _get(k, :loc_id)
      if lcid =~ /^lcsh:(\d+)$/ or lcid =~ /^sh(\d+)$/
        "http://id.loc.gov/authorities/subjects/sh#{$1}"
      elsif lcid =~ /^lcnaf:(\d+)$/ or lcid =~ /^n(\d+)$/
        "http://id.loc.gov/authorities/names/n#{$1}"
      elsif lcid =~ /^no(\d+)$/
        "http://id.loc.gov/authorities/names/no#{$1}"
      else
        nil
      end
    end
    
    def find_lcauth_by_keyword(k)
      lcid = _get(k, :loc_id)
      return $1 if lcid =~ /^(lcsh|lcnaf):/
      return 'lcsh' if lcid =~ /^sh\d+$/
      return 'lcnaf' if lcid =~ /^(n|no)\d+$/
      return 'lcsh' unless find_lc_by_keyword(k).nil? # default to lcsh if present
      nil
    end
    

    # @see http://www.geonames.org/ontology/documentation.html
    # @return [String] geonames uri (includes trailing / as specified)
    def find_uri_by_keyword(k)
      return nil if _get(k, :geonames_id).nil?
      "http://sws.geonames.org/#{_get(k, :geonames_id)}/"
    end
  
    # @return [String] The keyword
    def find_keyword_by_id(id)
      @registry.each do |k,v|
        return k if v[:geonames_id] == id
      end
      nil
    end
  end
end

