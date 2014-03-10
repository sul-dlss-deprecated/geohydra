module GeoHydra
  module GisDiscoveryWF
    class GenerateSolr < Task
      def perform_solr(app)
        modsFn = File.join(druid.metadata_dir, 'descMetadata.xml')
        solrFn = File.join(druid.temp_dir, "#{app}Solr.xml")
        log_debug({:modsFn => modsFn, :solrFn => solrFn, :flags => flags})
        
        unless FileUtils.uptodate?(solrFn, [modsFn])
          # Solr document from descMetadataDS
          cmd = [ 'xsltproc',
                  "--stringparam geoserver_root '#{flags[:geoserver]}'",
                  "--stringparam purl '#{to_purl}'",
                  "--output '#{solrFn}'",
                  "'#{File.expand_path(File.dirname(__FILE__) + '/../mods2#{app}.xsl')}'",
                  "'#{modsFn}'"
                  ].join(' ')
          log_debug({:cmd => cmd})
          system(cmd)
        end
        'SUCCESS'
      end      
      
    end

    class StartGisDiscoveryPipelineTask < NoopTask; end
    
    class GenerateOgpTask < GenerateSolr
      def perform(data)
        initialize(data)
        perform_solr('ogp')
      end
      
    end
    
    class LoadOgpTask < Task

    end
    
    class GenerateGeosearchTask < Task
      def perform(data)
        initialize(data)
        perform_solr('geoblacklight')
      end
    end
    
    class LoadGeosearchTask < Task
      
    end

    class FinishGisDiscoveryPipeline < Task
      
    end
  end
end