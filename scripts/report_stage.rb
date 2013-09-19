#!/usr/bin/env ruby
stagedir = '/var/geomdtk/current/stage'
%w{shp.xml shp zip json jpg}.each do |ext|
  system("set -x; find -L #{stagedir} -name '*.#{ext}' | wc -l")
end
