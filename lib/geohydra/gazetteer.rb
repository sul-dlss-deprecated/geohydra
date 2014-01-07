# encoding: UTF-8

require 'csv'
require 'awesome_print'

module GeoHydra
  class Gazetteer
    
    CSV_FN = File.join(File.dirname(__FILE__), 'gazetteer.csv')
    
    def initialize
      @registry = {}
      CSV.foreach(CSV_FN, :encoding => 'UTF-8') do |v|
        @registry[v[0]] = {
          :id => v[1].to_i,
          :lc => v[2],
          :lcid => v[3]
        }
      end
    end
    
    def _get(k, i)
      return nil unless @registry.include?(k)
      @registry[k][i]
    end
    
    # @return [Integer] geonames id
    def find_id_by_keyword(k)
      _get(k, :id)
    end

    # @return [String] library of congress name
    def find_lc_by_keyword(k)
      _get(k, :lc)
    end
    
    # @return [String] library of congress valueURI
    def find_lcuri_by_keyword(k)
      lcid = _get(k, :lcid)
      if lcid =~ /^lcsh:(\d+)$/ or lcid =~ /^sh(\d+)$/
        "http://id.loc.gov/authorities/subjects/sh#{$1}"
      elsif lcid =~ /^lcnaf:(\d+)$/ or lcid =~ /^n(\d+)$/
        "http://id.loc.gov/authorities/names/n#{$1}"
      else
        nil
      end
    end
    
    def find_lcauth_by_keyword(k)
      lcid = _get(k, :lcid)
      return $1 if lcid =~ /^(lcsh|lcnaf):/
      return "lc#{$1}" if lcid =~ /^(sh|n)\d+$/
      return 'lcsh' unless find_lc_by_keyword(k).nil? # default to lcsh if present
      nil
    end
    

    # @see http://www.geonames.org/ontology/documentation.html
    # @return [String] geonames uri (includes trailing / as specified)
    def find_uri_by_keyword(k)
      return nil if _get(k, :id).nil?
      "http://sws.geonames.org/#{_get(k, :id)}/"
    end
  
    # @return [String] The keyword
    def find_keyword_by_id(id)
      @registry.each do |k,v|
        return k if v[:id] == id
      end
      nil
    end
  end
end

