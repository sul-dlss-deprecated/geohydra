# encoding: UTF-8

require 'csv'
require 'awesome_print'

module GeoHydra
  class Gazetteer
    
    CSV_FN = File.join(File.dirname(__FILE__), 'gazetteer.csv')
    
    def initialize
      @registry = {}
      CSV.foreach(CSV_FN, :encoding => 'UTF-8') do |v|#, {:headers => true, }) do |v|
        @registry[v[0]] = {
          :id => v[1].to_i,
          :lc => v[2],
          :uri => "http://geonames.org/#{v[1].to_i}"
        }
      end
    end
    
    # @return [Integer] geonames id
    def find_id_by_keyword(kw)
      @registry.include?(kw) ? @registry[kw][:id].to_i : nil
    end
    
    # @return [String] library of congress name
    def find_lcnaf_by_keyword(kw)
      @registry.include?(kw) ? @registry[kw][:lc] : nil
    end

    # @return [String] geonames uri
    def find_uri_by_keyword(kw)
      @registry.include?(kw) ? @registry[kw][:uri] : nil
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

