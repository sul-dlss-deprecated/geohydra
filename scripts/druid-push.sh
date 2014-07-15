#!/bin/bash -x
cd /var/geomdtk/current/upload/druid-20140108
rsync -avL --delete ./ geomdtk-test:`pwd`/
