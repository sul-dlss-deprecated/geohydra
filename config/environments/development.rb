Dor::Config.configure do

  geonetwork do
    service_root 'http://geomdtk.stanford.edu/geonetwork'
  end
  
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end
  
  geoserver do
    service_root 'http://admin:admin123@localhost:8080/geoserver'
    host "kurma-podd1.stanford.edu"
    workspace "druid"
    data_dir "/var/geoserver/current/data"
  end

  geomdtk do
    workspace "/tmp/workspace"
  end

end
