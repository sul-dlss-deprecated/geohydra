module GeoMDTK
  class Deploy
    @@TYPES = {
     'shapefile_zip' =>  %r{\.zip$},
     'shapefile' =>  %r{\.shp$}
    }
    @@SSH_CMD = '/usr/bin/ssh -F /dev/null -K'
    @@RSYNC_CMD = "/usr/bin/rsync -e '#{@@SSH_CMD}' --size-only"
    
    def self.push(fn, collection)
      @@TYPES.keys.each do |t|
        if @@TYPES[t].match fn
          return self.send("push_#{t}", fn, collection)
        end
      end
      raise NotImplementedError, "#{fn} type not supported"
    end
    
    def self.push_shapefile(basefn, collection)
      do_system("#{@@SSH_CMD} #{Dor::Config.geoserver.ssh}" +
                " mkdir -p #{Dor::Config.geoserver.data_dir}/#{collection}")
      do_system("#{@@SSH_CMD} #{Dor::Config.geoserver.ssh}" +
                " chmod 2770 #{Dor::Config.geoserver.data_dir}/#{collection}")
      do_system("#{@@SSH_CMD} #{Dor::Config.geoserver.ssh}" + 
                " chgrp tomcat #{Dor::Config.geoserver.data_dir}/#{collection}")
        
      fns = Dir.glob("#{x}.*")
      remotedir = "#{Dor::Config.geoserver.ssh}:#{Dor::Config.geoserver.data_dir}/#{collection}/"
      do_rsync(fns, remotedr)
      
      do_system("curl" +
                " --user #{Dor::Config.geoserver.admin.user}:#{Dor::Config.geoserver.admin.password}" +
                " -XPUT -H 'Content-type: text/plain'" +
                " -d 'file:///data/workspaces/geomdtk/#{collection}/#{File.basename(basefn)}'" +
                " #{Dor::Config.geoserver.service_root}/" +     
                "rest/workspaces/geomdtk/datastores/#{collection}/external.shp")
    end


    def self.push_shapefile_zip(zipfn, collection)
      metadatafn = "#{zipfn.gsub(%r{\.zip$}, '.xml')}"
      remotedir = "#{Dor::Config.geoserver.ssh}:#{Dor::Config.geoserver.data_dir}/data/metadata/"
      do_rsync([metadatafn], remotedir)

      do_system("echo curl -v" +
                " --user #{Dor::Config.geoserver.admin.user}:#{Dor::Config.geoserver.admin.password}" +
                " -XPUT -H 'Content-type: application/zip'" +
                " --data-binary '@#{zipfn}'" +
                " '#{Dor::Config.geoserver.service_root}/" +   
                " rest/workspaces/druid/datastores/#{collection}/file.shp'")
    end
    
  private
    def self.do_system(cmd)
      puts "Running: #{cmd}" if $DEBUG
      system(cmd) if $DEBUG
    end  
  
    def self.do_rsync(fns, remotedir)
      do_system("#{@@RSYNC_CMD} --progress --human-readable" +
        " --copy-links --chmod=ug+rw,ug-x,o-rw" +
        " #{fns.join(' ')} #{remotedir}")
    end
    
  end
end