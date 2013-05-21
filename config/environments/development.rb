Dor::Config.configure do

  geonetwork do
    service_root 'http://admin:admin@geomdtk-dev.stanford.edu/geonetwork'
  end
  
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end
  
  geoserver do
    service_root 'http://admin:admin123@kurma-podd1.stanford.edu/geoserver'
    host "kurma-podd1.stanford.edu"
    workspace "druid"
    data_dir "/var/geoserver/current/data"
  end

end
