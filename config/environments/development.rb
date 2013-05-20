Dor::Config.configure do

  geonetwork do
    service_root 'http://geomdtk-dev.stanford.edu/geonetwork'
  end
  
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end
  
  geoserver do
    service_root 'http://localhost:38080/geoserver'
    admin 'admin:admin123'
    ssh "geostaff@kurma-podd1.stanford.edu"
    data_dir "/var/geoserver/current/data"
  end

end
