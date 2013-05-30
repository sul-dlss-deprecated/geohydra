require 'confstruct'
$config = Confstruct::Configuration.new do

  geonetwork do
    service_root 'http://geomdtk.stanford.edu/geonetwork'
  end
  
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end
  
  geoserver do
    service_root 'http://admin:admin123@kurma-podd1.stanford.edu/geoserver'
    workspace 'druid'
    namespace 'http://purl.stanford.edu'
  end

  geowebcache do
    service_root 'http://admin:admin123@kurma-podd1.stanford.edu/geoserver/gwc'
    srs 'EPSG:4326'
    zoom '1:10'
    format 'image/png'
    threadCount 1
  end

  geomdtk do
    workspace "/var/geomdtk/current/workspace"
    stage "/var/geomdtk/current/stage"
  end

end
