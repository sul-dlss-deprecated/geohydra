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
          :lcsh => v[2],
          :uri => "http://geonames.org/#{v[1].to_i}"
        }
      end
    end
    
    # @return [Integer] geonames id
    def find_id_by_keyword(kw)
      @registry.include?(kw) ? @registry[kw][:id].to_i : nil
    end
    
    # @return [String] library of congress subject heading
    def find_lcsh_by_keyword(kw)
      @registry.include?(kw) ? @registry[kw][:lcsh] : nil
    end

    # @return [String] library of congress subject heading
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

