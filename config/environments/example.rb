module GeoHydra
  Config = Confstruct::Configuration.new do
    geohydra do
      workspace "/var/geomdtk/current/workspace"
      stage "/var/geomdtk/current/stage"
      tmpdir "/var/geomdtk/current/tmp"
    end

    geonetwork do
      service_root 'http://host/geonetwork'
    end
    
    geoserver do
      workspace 'druid'
      datastore 'geoserver'
      namespace 'http://mynamespace'
    end

    geowebcache do
      service_root 'http://user:pwd@host/geoserver/gwc'
      seed do # one or more seeding options
        basic do
          gridSetId 'EPSG:4326' # required
          zoom '1:10' # required
          tileFormat 'image/png' # optional, defaults to image/png
          threadCount 2 # optional, defaults to 1
        end
        google_toponly do
          gridSetId 'EPSG:900913'
          zoom '1:3'
        end
      end
    end
    
    postgis do
      url 'postgres://geostaff:@localhost:5432/geoserver'
      schema 'myschema'
    end
    
    ogp do
      geoserver 'http://host/geoserver'
      purl 'http://host'
      solr do
        url 'http://host/solr'
        collection 'mycollection'
      end
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
  
  ssl do
    cert_file File.join(File.dirname(__FILE__) + '/../certs', "my.crt")
    key_file  File.join(File.dirname(__FILE__) + '/../certs', "my.key")
    key_pass ''
  end
  
  purl do
    base_url 'http://purl.my.host/'
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
