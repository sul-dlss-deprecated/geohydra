module GeoMDTK
  Config = Confstruct::Configuration.new do
    geomdtk do
      workspace "/var/geomdtk/current/workspace"
      stage "/var/geomdtk/current/stage"
    end

    geonetwork do
      service_root 'http://host/geonetwork'
    end
    
    geoserver do
      service_root 'http://admin:mypassword@host/geoserver'
      workspace 'druid'
      namespace 'http://mynamespace'
    end

    geowebcache do
      service_root 'http://admin:mypassword@host/geoserver/gwc'
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
    service_root 'http://user:mypassword@host'
    num_attempts  1
    sleep_time   1
  end

  fedora do 
    url 'https://user:mypassowrd@host/fedora'
  end
  
  gsearch do
    url 'http://user:mypassword@host/solr'
  end

  solrizer do
    url 'http://user:mypassword@host/solr'
  end
  
  ssl do
    cert_file File.join(File.dirname(__FILE__) + '/../certs', "my.crt")
    key_file  File.join(File.dirname(__FILE__) + '/../certs', "my.key")
    key_pass ''
  end

  suri do
    mint_ids true
    id_namespace 'druid'
    url 'http://host'
    user 'myuser'
    pass 'mypassword'
  end
  
  workflow do
    url 'http://user:mypassword@host/workflow/'
  end
  
end
