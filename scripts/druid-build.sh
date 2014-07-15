cd /var/geomdtk/current/upload
test -d druid-20140108 && echo "$(pwd)/druid/ already exists" && exit -1
mkdir druid-20140108

find -L `pwd`/metadata/current -type d -name '???????????' | while read d; do
	druid=$(basename $d)
	echo druid $druid at $d
	test -d druid-20140108/$druid && echo ERROR: $druid already exists && exit -2
	mkdir -p druid-20140108/$druid
        for x in temp; do
		mkdir -p druid-20140108/$druid/$x
        	ln -sf $d/$x/* druid-20140108/$druid/$x/
	done
done
