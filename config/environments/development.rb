module GeoMDTK
  Config = Confstruct::Configuration.new do
    geomdtk do
      workspace "/var/geomdtk/current/workspace"
      stage "/var/geomdtk/current/stage"
    end

    geonetwork do
      service_root 'http://geomdtk.stanford.edu/geonetwork'
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
  end
end

require 'dor-services'
Dor::Config.configure do
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end

  fedora do 
    url 'https://dorAdmin:dorAdmin@dor-dev.stanford.edu/fedora'
  end
  
  gsearch do
    url 'http://dorAdmin:dorAdmin@dor-dev.stanford.edu/solr'
  end

  solrizer do
    url 'https://dorAdmin:dorAdmin@dor-dev.stanford.edu/solr/'
  end
  
  ssl do
    cert_file File.join(File.dirname(__FILE__) + '/../certs', "dlss-dev-drh-dor-dev.crt")
    key_file  File.join(File.dirname(__FILE__) + '/../certs', "dlss-dev-drh-dor-dev.key")
    key_pass ''
  end

  suri do
    mint_ids true
    id_namespace 'druid'
    url 'http://lyberservices-dev.stanford.edu'
    user 'labware'
    pass 'lyberteam'
  end
  
  workflow do
    url 'http://dorAdmin:dorAdmin@lyberservices-dev.stanford.edu/workflow/'
  end
  
end
