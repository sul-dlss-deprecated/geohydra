require 'druid-tools'

module GeoHydra
  class Task
    STATUS = %w{HOLD READY RUNNING DEFERRED ERROR COMPLETED}
    # @param [String] status 
    # @return [Boolean] true if the given status is one of the valid Task.STATUS values
    def valid_status? status
      STATUS.include? status.upcase
    end
    
    attr_accessor :druid, :flags

    def initialize(data = {})
      @flags = {}
      @flags[:debug] = data[:debug] || false
      @flags[:geoserver] = data[:geoserver] || GeoHydra::Config.ogp.geoserver || 'http://127.0.0.1:8080/geoserver'
      @flags[:purl] = data[:purl] || GeoHydra::Config.ogp.purl || 'http://purl.stanford.edu'
      @flags[:solr] = data[:solr] || GeoHydra::Config.ogp.solr || 'http://127.0.0.1:8983/solr'
      @flags[:stagedir] = data[:stagedir] || GeoHydra::Config.geohydra.stage || 'stage'
      @flags[:tmpdir] = data[:tmpdir] || GeoHydra::Config.geohydra.tmpdir || 'tmp'
      @flags[:verbose] = data[:verbose] || false
      @flags[:workspacedir] = data[:workspacedir] || GeoHydra::Config.geohydra.workspace || 'workspace'
      
      @druid = nil
      @druid = _setup_druid(data[:druid]) unless data[:druid].nil?
    end
    
    # Perform the task
    # @param [Hash] data
    # @return [String] one of the `Task.STATUS` values
    def perform(data = {})
      raise NotImplementedError, 'abstract method'
    end

    # @param [String] druid `aa111bb2222`
    def druid= druid
      _init_druid druid
    end
    
    # Converts the current @druid into a PURL
    # @return [String] `http://purl.stanford.edu/aa111bb2222`
    def to_purl
      File.join(flags[:purl], @druid.id)
    end
    
    def log_info(args)
      puts args
    end

    def log_verbose(args)
      ap({:verbose => args}) if flags[:verbose]
    end

    def log_debug(args)
      ap({:debug => args}) if flags[:debug]
    end

    def log_error(args)
      ap({:error => args})
    end
    
    private
    def _setup_druid s
      druid = DruidTools::Druid.new(s, flags[:workspacedir])
      raise ArgumentError if druid.nil? or not DruidTools::Druid.valid?(druid.druid)
      druid
    end
  end
  
  class NoopTask < Task
    def perform(data)
      'COMPLETED'
    end
  end

  class ManualTask < Task
    def perform(data)
      'HOLD'
    end
  end
end