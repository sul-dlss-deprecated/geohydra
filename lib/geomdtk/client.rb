require 'rubygems'
require 'nokogiri'
require 'dor-services'
require 'rest_client'
require "savon"

module GeoMDTK
  class Client
    
    @@geonetwork_status_codes = %w{unknown draft approved retired submitted rejected}
    
    def self.site_info
      service("xml.info", { :type => 'site' }).xpath('/info/site')
    end

    def self.metrics
      service("../../monitor/metrics", { :pretty => 'true' })
    end

    def self.each_uuid
      xml = service("xml.search", { :remote => 'off'})
      xml.xpath('//uuid').each do |a_tag|
        yield a_tag.content.strip
      end
    end
    
    def self.fetch(path = '//uuid')
      r = {}
      each_uuid do |uuid|
        r[uuid] = fetch_by_uuid(uuid)
      end
      r
    end
    
    def self.fetch_by_uuid(uuid)
      xml = service("xml.metadata.status.get", { :uuid => uuid })
      i = xml.xpath('/response/record/statusid').first.content.to_i
      status = @@geonetwork_status_codes[i]
      
      xml = service("xml.metadata.get", { :uuid => uuid })
      xml.xpath('//geonet:info') { |e| e.remove }
      Struct.new(:content, :status).new(
        xml.xpath('//gmd:MD_Metadata').first,
        status
      )
    end
    
    def self.export(uuid, dir = ".", format = :mef)
      if format == :mef
        export_mef(uuid, dir)
      elsif format == :csw
        export_csw(uuid, dir)
      end
    end
    
    def self.search_wsdl(q = nil)
      client = Savon.client(wsdl: "#{Dor::Config.geonetwork.service_root}/srv/eng/xml.search")
      client.operations
      response = client.call() do
        message()
      end
      response.body
    end
    
    private
    
    def self.service(name, params, format = :default)
      if format == :default and name.start_with?('xml.')
        format = :xml
      end
      
      r = RestClient.get "#{Dor::Config.geonetwork.service_root}/srv/eng/#{name}", :params => params
      if format == :xml
        Nokogiri::XML(r)
      elsif format == :default
        r
      else
        raise ArgumentError, "service requires format valid parameter: #{format}"
      end
    end
    
    def self.export_mef(uuid, dir = ".")
      res = service("mef.export", { :uuid => uuid, :version => 'true' })
      File.open("#{dir}/#{uuid}.mef", 'wb') {|f| f.write(res.body) }
    end
  
    def self.export_csw(uuid, dir = ".")
      res = service("csw", { 
    	  :request => 'GetRecordById',
    		:service => 'CSW',
    		:version => '2.0.2',
    		:elementSetName => 'full',
    		:id => uuid 
  		})
      File.open("#{dir}/#{uuid}.csw", 'wb') {|f| f.write(res.body) }
    end
    
    
  end
end
