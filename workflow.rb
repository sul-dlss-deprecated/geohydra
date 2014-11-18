WORKFLOW_STEPS = %w{
  gisAssemblyWF_start-gis-assembly-pipeline
  gisAssemblyWF_register-druid
  gisAssemblyWF_author-metadata
  gisAssemblyWF_approve-metadata
  gisAssemblyWF_wrangle-data
  gisAssemblyWF_approve-data
  gisAssemblyWF_normalize-data
  gisAssemblyWF_package-data
  gisAssemblyWF_finish-data
  gisAssemblyWF_extract-thumbnail
  gisAssemblyWF_extract-iso19139
  gisAssemblyWF_generate-geo-metadata
  gisAssemblyWF_generate-mods
  gisAssemblyWF_assign-placenames
  gisAssemblyWF_finish-metadata
  gisAssemblyWF_generate-content-metadata
  gisAssemblyWF_finish-gis-assembly-pipeline
  gisAssemblyWF_start-assembly-workflow
  gisAssemblyWF_start-delivery-workflow
  gisDeliveryWF_start-gis-delivery-pipeline
  gisDeliveryWF_load-vector
  gisDeliveryWF_load-raster
  gisDeliveryWF_load-geoserver
  gisDeliveryWF_load-geowebcache
  gisDeliveryWF_seed-geowebcache
  gisDeliveryWF_finish-gis-delivery-pipeline
  gisDeliveryWF_start-gis-discovery-workflow
  gisDiscoveryWF_start-gis-discovery-pipeline
  gisDiscoveryWF_generate-ogp
  gisDiscoveryWF_load-ogp
  gisDiscoveryWF_generate-geosearch
  gisDiscoveryWF_load-geosearch
  gisDiscoveryWF_finish-gis-discovery-pipeline
}