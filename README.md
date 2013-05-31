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
