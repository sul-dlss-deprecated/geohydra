module GeoMDTK
  class Deploy
    TYPES = {
     'shapefile_zip' =>  %r{\.zip$},
     'shapefile' =>  %r{\.shp$}
    }
    SSH_CMD = '/usr/bin/ssh -F /dev/null -K'
    RSYNC_CMD = "/usr/bin/rsync -e '#{SSH_CMD}' --size-only"
    
    def push(fn, collection)
      TYPES.keys.each do |t|
        if TYPES[t].match fn
          return self.send("push_#{t}", fn, collection)
        end
      end
      raise NotImplementedError, "#{fn} type not supported"
    end
    
    def do_system(cmd)
      puts "Running: #{cmd}"
      system(cmd)
    end
    
    def push_shapefile(basefn, collection)
      x = basefn.gsub(%r{\.shp$}, '')
      name = File.basename(x).downcase
      do_system("#{SSH_CMD} #{Dor::Config.geoserver.ssh} mkdir -p #{Dor::Config.geoserver.data_dir}/#{collection}")
      do_system("#{SSH_CMD} #{Dor::Config.geoserver.ssh} chmod 2770 #{Dor::Config.geoserver.data_dir}/#{collection}")
      do_system("#{SSH_CMD} #{Dor::Config.geoserver.ssh} chgrp tomcat #{Dor::Config.geoserver.data_dir}/#{collection}")
      fns = Dir.glob("#{x}.*").join(' ')
      remotedir = "#{Dor::Config.geoserver.ssh}:#{Dor::Config.geoserver.data_dir}/#{collection}/"
      puts "Pushing #{name} to #{remotedir}"
      do_system("#{RSYNC_CMD} --progress --human-readable --copy-links --chmod=ug+rw,ug-x,o-rw #{fns} #{remotedir}")
      
      do_system("curl -u #{Dor::Config.geoserver.admin} -XPUT -H 'Content-type: text/plain' -d 'file:///data/workspaces/geomdtk/#{collection}/#{File.basename(basefn)}' #{Dor::Config.geoserver.service_root}/rest/workspaces/geomdtk/datastores/#{collection}/external.shp")
    end


    def push_shapefile_zip(zipfn, collection)
      metadatafn = "#{zipfn.gsub(%r{\.zip$}, '.xml')}"
      puts "#push_shapefile_zip: #{collection} #{metadatafn}"
      remotedir = "#{Dor::Config.geoserver.ssh}:#{Dor::Config.geoserver.data_dir}/data/metadata/"
      do_system("#{RSYNC_CMD} --progress --human-readable --copy-links --chmod=ugo+rw,ug-x,o-w #{metadatafn} #{remotedir}")

      puts "#push_shapefile_zip: #{collection} #{zipfn}"
      do_system("echo curl -v -u '#{Dor::Config.geoserver.admin}' " + 
                "-XPUT -H 'Content-type: application/zip' " +
                "--data-binary '@#{zipfn}' " +
                "'#{Dor::Config.geoserver.service_root}/rest/workspaces/druid/datastores/#{collection}/file.shp'")
    end
  end
end