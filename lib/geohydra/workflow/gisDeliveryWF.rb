module GeoHydra
  module GisDeliveryWF

    class StartGisDeliveryPipelineTask < NoopTask; end
    
    class LoadVectorTask < Task
      
    end
    
    class LoadRasterTask < Task
      
    end
    
    class LoadGeoserverTask < Task
      
    end
    
    class LoadGeowebcacheTask < Task
      
    end
    
    class SeedGeowebcacheTask < Task
      
    end
    
    class FinishGisDeliveryPipelineTask < NoopTask; end
    
    class StartGisDiscoveryWorkflowTask < Task
      
    end
      
  end
end