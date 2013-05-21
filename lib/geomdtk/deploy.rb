module GeoMDTK
  class Deploy
    @@TYPES = {
     'shapefile_zip' =>  %r{\.zip$}
    }
    @@SSH_CMD = '/usr/bin/ssh -F /dev/null -K'
    @@RSYNC_CMD = "/usr/bin/rsync -e '#{@@SSH_CMD}'"
    @@config = Dor::Config
    
    def self.push(fn, collection)
      @@TYPES.keys.each do |t|
        if @@TYPES[t].match fn
          return self.send("push_#{t}", fn, collection)
        end
      end
      raise NotImplementedError, "#{fn} type not supported"
    end

    def self.push_shapefile_zip(zipfn, datastore)
      do_system("curl -v" +
                " -XPUT -H 'Content-type: application/zip'" +
                " --data-binary '@#{zipfn}'" +
                " '#{@@config.geoserver.service_root}/" +   
                "rest/workspaces/#{@@config.geoserver.workspace}/datastores/#{datastore}/file.shp'")
      do_rsync(["#{zipfn.gsub(%r{\.zip$}, '.xml')}"], datastore)
    end
    
  private
    def self.do_system(cmd)
      puts "Running: #{cmd}" if $DEBUG
      system(cmd)
    end  
  
    def self.do_rsync(fns, datastore)
      do_system("#{@@RSYNC_CMD} --copy-links --chmod=ug+rw,ug-x,o-rw" +
        " #{fns.join(' ')} #{@@config.geoserver.host}:#{@@config.geoserver.data_dir}/data/metadata/")
    end
    
  end
end