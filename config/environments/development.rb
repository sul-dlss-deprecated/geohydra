module GeoMDTK
  CONFIG = Confstruct::Configuration.new do

    geomdtk do
      workspace "/var/geomdtk/current/workspace"
      stage "/var/geomdtk/current/stage"
    end
    
    geoserver do
      service_root 'http://admin:admin@localhost:8080/geoserver'
      workspace 'geomdtk'
      namespace 'geomdtk'
    end

    geowebcache do
      service_root 'http://admin:admin123@localhost:8080/geoserver/gwc'
      srs 'EPSG:4326'
      zoom '1:10'
      format 'image/png'
      threadCount 1
    end

    geonetwork do
      service_root 'http://localhost:8081/geonetwork'
    end
  
  end.freeze
end
