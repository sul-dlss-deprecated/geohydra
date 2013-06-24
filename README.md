GeoMDTK
=======

Geospatial MetaData ToolKit for use in a GeoHydra head.

Setup
-----

If needed, configure host to use Ruby 1.9.3:

    % rvm_path=$HOME/.rvm rvm-installer --auto-dotfiles
    % source ~/.bashrc
    % rvm use 1.9.3@geomdtk
    % rvm rvmrc create

Run setup:

    % bundle install
    % bundle exec rake spec
    % bundle exec rake yard

Utilities
---------

To assemble the workspace, populate the geomdtk.stage directory with `_druid_.zip` files which contain the
Shapefiles files.

    % bundle exec bin/assemble.rb

To project all Shapefiles into EPSG:4326 (WGS84):

    % bundle exec bin/derive_wgs84.rb

To upload the druid metadata to DOR:

    % bundle exec bin/accession.rb druid1 [druid2 druid3...]

To upload the druid packages to GeoServer:

    % bundle exec bin/loader.rb druid1 [druid2 druid3...]
    
To enable logging for the Rest client, use

    % RESTCLIENT_LOG=stdout bundle exec ...
    
GeoHydra Head
=============

GeoServer
---------

    >> c = RGeoServer::Catalog.new
    Catalog: http://localhost:8080/geoserver/rest
    >> w = c.get_default_workspace
    RGeoServer::Workspace: druid
    >> ds = w.data_stores
    [
        [0] RGeoServer::DataStore: ww217dj0457,
        [1] RGeoServer::DataStore: fw920bc5473,
        [2] RGeoServer::DataStore: vk120xn2474,
        [3] RGeoServer::DataStore: df559hb2469,
        [4] RGeoServer::DataStore: zv925hd6723,
        [5] RGeoServer::DataStore: ks297fy1411,
        [6] RGeoServer::DataStore: rt625ws6022,
        [7] RGeoServer::DataStore: sq479mx3086,
        [8] RGeoServer::DataStore: zz943vx1492,
        [9] RGeoServer::DataStore: cs838pw3418
    ]
    >> ds.first.profile
    {
                         "name" => "ww217dj0457",
                      "enabled" => "true",
        "connection_parameters" => {
                  "url" => "file:/var/geoserver/current/data/data/druid/ww217dj0457/",
            "namespace" => "http://purl.stanford.edu"
        },
                 "featureTypes" => [
            [0] "ww217dj0457"
        ]
    }


