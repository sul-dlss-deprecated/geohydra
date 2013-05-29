module GeoMDTK
  class Deploy
    TYPES = {
     'shapefile_zip' =>  %r{\.zip$}
    }
    @@config = Dor::Config
    
    def self.push(fn, collection)
      TYPES.keys.each do |t|
        if TYPES[t].match fn
          return self.send("push_#{t}", fn, collection)
        end
      end
      raise NotImplementedError, "#{fn} type not supported"
    end

    def self.push_shapefile_zip(zipfn, datastore)
      puts "Uploading #{zipfn}"
      do_system("curl" +
                " -XPUT -H 'Content-type: application/zip'" +
                " --data-binary '@#{zipfn}'" +
                " '#{@@config.geoserver.service_root}/" +   
                "rest/workspaces/#{@@config.geoserver.workspace}/datastores/#{datastore}/file.shp'")
    end
    
  private
    def self.do_system(cmd)
      puts "Running: #{cmd}" if $DEBUG
      system(cmd)
    end  
      
  end
end