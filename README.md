GeoHydra
=======

Geospatial MetaData ToolKit for use as a Geo[Hydra](http://projecthydra.org) head.

Setup
-----

Core requirements, with versions as-tested:

* ArcGIS 10.2
* GeoNetwork 2.8 (optional for metadata management)
* GEOS 3.3
* GeoServer 2.2
* OpenGeoPortal 1.2
* PostGIS 2.0
* PostgreSQL 9.2
* Red Hat Enterprise Linux Server release 6.4 (Santiago)
* Ruby 1.9

If needed, configure host to use Ruby 1.9.3:

    % rvm_path=$HOME/.rvm rvm-installer --auto-dotfiles
    % source $HOME/.bashrc
    % cd geohydra
    % rvm use 1.9.3@geohydra --create
    % rvm rvmrc create

To install the native extensions to Ruby pg:

    # yum install postgresql92-devel
    % gem install pg -- --with-pg_config=/usr/pgsql-9.2/bin/pg_config 

You need to customize your configuration parameters like so (see the `config/environments/example.rb` first):

    % $EDITOR config/environments/development.rb

Run setup:

    % bundle install
    % bundle exec rake spec
    % bundle exec rake yard

Utilities
---------

Assemble all your metadata and data as described in *Data Wrangling* into the
stage directory `/var/geomdtk/current/stage`. The utilities will use `/var/geomdtk/current/workspace` as the output folder, akin to `/dor/workspace`.

Caveats: to enable logging for the Rest client, use

    % RESTCLIENT_LOG=stdout bundle exec ...

Preparing `stage`
===============

To assemble the workspace, populate the *geohydra.stage* directory with
`druid` directories which contain the data as described in the Data Wrangling
section below.

To generate the `geoOptions.json` files which contain inspections of the Shapefiles:

    % bundle exec bin/build_stage_options.rb

To ingest ArcGIS `*.shp.xml` files and transform into ISO 19139 files

    % bundle exec bin/ingest_arcgis.rb
    
To package up the .shp files into .zip files:

    % bundle exec bin/assemble_data.rb

Preparing workspace with assembly
=================================

To load the `workspace` and generate metadata files from the `stage`, use:

    % bundle exec bin/assemble.rb

To project all Shapefiles into EPSG:4326 (WGS84), as needed:

    % bundle exec bin/derive_wgs84.rb druid1...
    
Upload workspace files to lyber-services-prod:/dor/workspace:

    % cd /var/geomdtk/current/workspace
    % rsync -av ./ lyberadmin@lyber-services-prod:/dor/workspace/

Accessioning
============

To upload the druid metadata to DOR:

    % bundle exec bin/accession.rb druid1 [druid2 druid3...]
    
Use Argo to initiate the assemblyWF.    

To upload the druid packages to PostGIS, you will need `shp2pgsql` then use:

    % bundle exec bin/loader_postgis.rb druid1 [druid2 druid3...]

Then, login to GeoServer and import the data layers from PostGIS

    % bundle exec bin/sync_geoserver_metadata.rb

To upload the druid packages to GeoServer use OpenGeo's *Import Data* feature. Or if you need an automated tool see `bin/loader.rb`.

To upload the OpenGeoPortal Solr documents, use:

    % bundle exec bin/solr_indexer.rb 

Data Wrangling
==============

Step 1: Preparing for stage
---------------------------

The file system structure will initially look like the following (see [Consul
page](https://consul.stanford.edu/x/C5xSC) for a description) where the temp
files for the shapefiles are all hard links to reduce space requirements: This
is *pre-stage*:

    zv925hd6723/
      temp/
        geoOptions.json
        OGWELLS.dbf
        OGWELLS.prj
        OGWELLS.shp
        OGWELLS.shp.xml
        OGWELLS.shx

The `geoOptions.json` contain meta-metadata about the package, including the
druid, geometry type, and filename. These files can be generated using
bin/build_stage_options.rb but it requires manual supervision.

    { "druid":"cg716wc7949", 
      "geometryType":"Raster", 
      "filename":"world_admin1.tif" }

Step 2: Staged
--------------

Once staged, the data look like this:

    zv925hd6723/
      content/
        data.zip
        preview.jpg
      temp/
        geoOptions.json
        OGWELLS-iso19139-fc.xml
        OGWELLS-iso19139.xml


Step 3: Assembly
----------------

Then at the end of assembly processing -- see above prior to accessioning -- it will
look like in your workspace:

    zv925hd6723/
      metadata/
        contentMetadata.xml (generated later by accessioning scriptie)
        descMetadata.xml
        geoMetadata.xml
      content/
        data.zip
        data_ESRI_4326.zip (optionally)
        preview.jpg
        some-other-file.ext (optionally)
      temp/
        iso19139.xml
        ogpSolr.xml
        spatialSolr.xml

Credits
=======

Author:  
Darren Hardy <drh@stanford.edu>,  
Digital Library Systems and Services,  
Stanford University Libraries

