require 'rubygems'
require 'nokogiri'
require 'rest_client'
require "savon"

module GeoMDTK
  class Client

    def self.site_info
      service("xml.info", { :type => 'site' }).xpath('/info/site')
    end

    def self.metrics
      RestClient.get "#{@@geonetwork_base}/monitor/metrics", 
        :params => { :pretty => 'true' }
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
      {
        :status => service("xml.metadata.status.get", { :uuid => uuid }),
        :xml    => service("xml.metadata.get", { :uuid => uuid })
      }
    end
    
    def self.export(uuid, dir = ".", format = :mef)
      if format == :mef
        export_mef(uuid, dir)
      elsif format == :csw
        export_csw(uuid, dir)
      end
    end
    
    def self.search_wsdl(q = nil)
      client = Savon.client(wsdl: "#{@@geonetwork_base}/srv/eng/xml.search")
      client.operations
      response = client.call() do
        message()
      end
      response.body
    end
    
    private
    
    def self.service(name, params = {})
      Nokogiri::XML(service_raw(name, params))
    end

    def self.service_raw(name, params)
      RestClient.get "#{@@geonetwork_base}/srv/eng/#{name}", :params => params
    end
    
    def self.export_mef(uuid, dir = ".")
      res = service.raw("mef.export", { :uuid => uuid })
      File.open("#{dir}/#{uuid}.mef", 'wb') {|f| f.write(res.body) }
    end
  
    def self.export_csw(uuid, dir = ".")
      res = service_raw("csw", { 
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
