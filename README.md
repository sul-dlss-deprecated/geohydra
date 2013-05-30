= GeoMDTK

To assemble the workspace, populate the geomdtk.stage directory with _druid_.zip files which contain only the Shapefiles files.

    % bin/assemble.rb

To project all Shapefiles into EPSG:4326 (WGS84):

    % bin/derive_wgs84.rb

To upload the druid packages to GeoServer:

    % bin/loader.rb druid1 [druid2 druid3...]
