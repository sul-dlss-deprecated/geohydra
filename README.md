GeoMDTK
=======

Geospatial MetaData ToolKit

Setup
-----

    % bundle install
    % rake spec
    % rake yard

Utilities
---------

To assemble the workspace, populate the geomdtk.stage directory with `druid.zip` files which contain the
Shapefiles files.

    % bundle exec bin/assemble.rb

To project all Shapefiles into EPSG:4326 (WGS84):

    % bundle exec bin/derive_wgs84.rb

To upload the druid packages to GeoServer:

    % bundle exec bin/loader.rb druid1 [druid2 druid3...]
    
    
GeoHydra head example
----

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
    

