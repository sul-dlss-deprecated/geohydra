module GeoHydra
  module GisAssemblyWF

    class RegisterDruidTask < ManualTask; end
    
    class AuthorMetadataTask < ManualTask; end
    
    class ApproveMetadataTask < ManualTask; end
    
    class WrangleDataTask < ManualTask; end
    
    class ApproveDataTask < ManualTask; end
    
    class NormalizeDataTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class PackageDataTask
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class FinishDataTask < NoopTask; end
    
    class ExtractThumbnailTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class ExtractIso19139Task < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class GenerateGeoMetadataTask < Task
      def perform(*args)
        druid = args[:druid]
        isoFn = File.join(druid.temp_dir, 'iso19139.xml')
        fcFn = File.join(druid.temp_dir, 'iso19110.xml')
        geoFn = File.join(druid.metadata_dir, 'geoMetadata.xml')
        log_debug({:isoFn => isoFn, :fcFn => fcFn, :geoFn => geoFn, :flags => flags})
        
        unless FileUtils.uptodate?(geoFn, [isoFn, fcFn])
          isoXml = Nokogiri::XML(File.read(isoFn))
          fcXml = Nokogiri::XML(File.read(fcFn))
          log_verbose("Generating geoMetadata: #{geoFn} <- #{isoFn}, #{fcFn}")
          xml = GeoHydra::Transform.to_geoMetadataDS(isoXml, fcXml, { 'purl' => to_purl}) 
          File.open(geoFn, 'w') {|f| f << xml.to_xml(:indent => 2) }
        end
        'SUCCESS'
      end
    end

    class GenerateModsTask < Task
      def perform(*args)
        druid = args[:druid]
        geoFn = File.join(druid.metadata_dir, 'geoMetadata.xml')
        modsFn = File.join(druid.metadata_dir, 'descMetadata.xml')
        log_debug({:geoFn => geoFn, :modsFn => modsFn, :flags => flags})
        
        unless FileUtils.uptodate?(modsFn, [geoFn])
          # MODS from GeoMetadataDS
          geoMetadata = Dor::GeoMetadataDS.from_xml File.read(geoFn)
          geoMetadata.geometryType = args[:geometryType] || 'Polygon'
          geoMetadata.zipName = 'data.zip'
          geoMetadata.purl = to_purl
          
          log_debug({:geoMetadata => geoMetadata.ng_xml})
          File.open(modsFn, 'w') { |f| f << geoMetadata.to_mods.to_xml(:index => 2) }
        end
        'SUCCESS'
      end
    end

    class AssignPlacenamesTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class FinishMetadataTask < NoopTask; end
    
    class GenerateContentMetadataTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class FinishGisAssemblyPipeline < NoopTask; end
    
    class StartAssemblyWorkflowTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
    class StartDeliveryWorkflowTask < Task
      def perform(*args)
        raise NotImplementedError
      end
    end
    
  end
end