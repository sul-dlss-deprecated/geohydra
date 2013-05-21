Dor::Config.configure do

  geonetwork do
    service_root 'http://localhost:8080/geonetwork'
  end
  
  dor do
    service_root 'https://dorAdmin:dorAdmin@sul-lyberservices-dev.stanford.edu'
    num_attempts  1
    sleep_time   1
  end
  
  geoserver do
    service_root 'http://localhost:8080/geoserver'
    admin do
      user 'admin'
      password 'admin123'
    end 
    ssh "geostaff@kurma-podd1.stanford.edu"
    data_dir "/var/geoserver/current/data"
  end

end
