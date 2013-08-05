GeoMDTK
=======

Geospatial MetaData ToolKit for use in a GeoHydra head.

Setup
-----

If needed, configure host to use Ruby 1.9.3:

    % rvm_path=$HOME/.rvm rvm-installer --auto-dotfiles
    % source ~/.bashrc
    % rvm use 1.9.3@geomdtk --create
    % rvm rvmrc create

To install the native extensions to Ruby pg:

    # yum install postgresql92-devel
    % gem install pg -- --with-pg_config=/usr/pgsql-9.2/bin/pg_config 

You need to customize your configuration parameters like so:

    % $EDITOR config/environments/development.rb

Run setup:

    % bundle install
    % bundle exec rake spec
    % bundle exec rake yard

Utilities
---------

To ingest ArcGIS *.shp.xml files and transform into ISO19139 files

    % bundle exec bin/ingest_arcgis.rb /var/geomdtk/current/upload/data/ready

To package up the .shp files into .zip files:

    % bundle exec bin/assemble_data.rb /var/geomdtk/current/upload/druid

To assemble the workspace, populate the geomdtk.stage directory with `_druid_.zip` files which contain the
Shapefiles files.

    % bundle exec bin/assemble.rb --srcdir /var/geomdtk/current/workspace

To project all Shapefiles into EPSG:4326 (WGS84), if needed:

    % bundle exec bin/derive_wgs84.rb

To upload the druid metadata to DOR:

    % bundle exec bin/accession.rb druid1 [druid2 druid3...]

To upload the druid packages to PostGIS, use:

    % bundle exec bin/loader_postgis.rb druid1 [druid2 druid3...]

Then, login to GeoServer and import the data layers from PostGIS

    % bundle exec bin/sync_geoserver_metadata.rb

To upload the druid packages to GeoServer via the filesystem:

    % bundle exec bin/loader.rb druid1 [druid2 druid3...]

To upload the OGP Solr documents, use:

    % bundle exec bin/solr_indexer.rb 


Caveats
=======

To enable logging for the Rest client, use

    % RESTCLIENT_LOG=stdout bundle exec ...

These utilities assume a few things:

* /var/geomdtk/current is the core root folder for data/metadata
* upload holds data to be processed
* upload/druid holds data and metadata in the druid workspace structure

You can use the scripts/build.rb to help build out a druid/ folder with data for upload.

The file system structure will initially look like this:

    zv925hd6723/
      metadata/
      content/
      temp/
        OGWELLS.dbf
        OGWELLS.prj
        OGWELLS.sbn
        OGWELLS.sbx
        OGWELLS.shp
        OGWELLS.shp.xml
        OGWELLS.shx

then at the end of processing it will look like:

    zv925hd6723/
      metadata/
        descMetadata.xml
        geoMetadata.xml
      content/
        OGWELLS_preview.jpg
        OGWELLS.zip
      temp/
        dc.xml
        ogpSolr.xml
        OGWELLS.dbf
        OGWELLS.prj
        OGWELLS.sbn
        OGWELLS.sbx
        OGWELLS.shp
        OGWELLS.shp.xml
        OGWELLS.shx

