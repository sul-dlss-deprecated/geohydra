
h1. Solr schema

The schema is on Github here: https://github.com/sul-dlss/geohydra/blob/master/solr/kurma-app-test/conf/schema.xml.
The Solr documents are generated from either MODS or from existing OGP documents.

h2. Primary key

* *uuid*: Unique Identifier. Examples:
** [http://purl.stanford.edu/vr593vj7147],
** [http://ark.cdlib.org/ark:/28722/bk0012h535q],
** urn:geodata.tufts.edu:Tufts.CambridgeGrid100_04.

h2. Dublin Core

See the [Dublin Core Elements Guide|http://dublincore.org/documents/2012/06/14/dces/] for semantic descriptions of all of these fields.

* *dc_coverage_spatial_sm*: Coverage, placenames. Multiple values allowed. Example: "Paris, France".
* *dc_coverage_temporal_sm*: Coverage, years. Multiple values allowed. Example: "2010".
* *dc_creator_s*: Author. Example: "Washington, George".
* *dc_date_dt*: Date in Solr syntax. Example: "2001-01-01T00:00:00Z".
* *dc_description_s*: Description.
* *dc_format_s*: File format (not MIME types). Valid values:
** "Shapefile"
** "GeoTIFF"
* *dc_identifier_s*: Unique identifier. Same as UUID.
* *dc_language_s*: Language. Example: "English".
* *dc_publisher_s*: Publisher. Example: "ML InfoMap (Firm)".
* *dc_relation_url*: URL to related item: Multiple values allowed. Example:
"http://purl.stanford.edu/vr593vj7147"
* *dc_rights_s*: Rights for access. Valid values:
** "Restricted"
** "Public"
* *dc_source_s*: Source institution: Examples:
** Berkeley
** Harvard
** MassGIS
** MIT
** Stanford
** Tufts
* *dc_subject_sm*: Subject. Multiple values allowed. Example: "Human settlements", "Census".
* *dc_title_s*: Title.
* *dc_type_s*: Resource type. Valid values: "Dataset".

h2. Layer-specific metadata

* *layer_bbox*: Bounding box as maximum values for W S E N. Example: "76.76 12.62309 84.76618 19.91705"
* *layer_collection_s*: Collection to which the layer belongs.
* *layer_geom*: Shape of the layer as a Point, LineString, or Polygon WKT.
Example: "POLYGON((76.76 19.91705, 84.76618 19.91705, 84.76618 12.62309, 76.76 12.62309, 76.76 19.91705))"
* *layer_slug_s*. Unique identifier visible to the user, used for Permalinks.
* Example: stanford-vr593vj7147.
* *layer_id_s*. The complete identifier for the WMS/WFS/WCS layer.
Example: "druid:vr593vj7147",
* *layer_srs_s*: The spatial reference system for the layer. Example: EPSG:4326.
* *layer_geom_type_s*. Valid values are: "Point", "Line", "Polygon", and "Raster".
* *layer_wcs_url*: Service root for the WCS service that holds this layer. _If applicable._ Example: "http://geowebservices-restricted.stanford.edu/geoserver/wcs"
* *layer_wfs_url*: Service root for the WFS service that holds this layer. _If applicable._ Example: "http://geowebservices-restricted.stanford.edu/geoserver/wfs"
* *layer_wms_url*: Service root for the WMS service that holds this layer "http://geowebservices-restricted.stanford.edu/geoserver/wms"

h2. Derived metadata

* *layer_ne_pt* (from layer_bbox). North-eastern most point of the bounding box, as (y, x). Example: "83.1,-128.5"
* *layer_sw_pt* (from layer_bbox). South-western most point of the bounding box, as (y, x). Example: "81.2,-130.1"
* *layer_year_i* (from dc_date_dt): Year for which layer is valid. Example: 2012.

h2. Solr schema syntax

See complete schema on https://github.com/sul-dlss/geomdtk/blob/master/solr/kurma-app-test/conf/schema.xml

Note on the types:

|| Suffix || Solr data type using dynamicField ||
| \_s | String |
| \_sm | String, multivalued |
| \_t | Text, English |
| \_i | Integer |
| \_dt | Date time |
| \_url | URL as a non-indexed String |
| \_bbox | Spatial bounding box, Rectangle as (w, s, e, n) |
| \_pt | Spatial point as (y,x) |
| \_geom | Spatial shape as WKT |


{code:xml}
<?xml version="1.0" encoding="UTF-8"?>
<schema name="GeoBlacklight" version="1.5">
  <uniqueKey>uuid</uniqueKey>
  <fields>
  ...
    <!-- Spatial field types:
    
         Solr3:
           <field name="my_pt">83.1,-117.312</field> 
             as (y,x)

         Solr4:             

           <field name="my_bbox">-117.312 83.1 -115.39 84.31</field> 
             as (W S E N)

           <field name="my_geom">POLYGON((1 8, 1 9, 2 9, 2 8, 1 8))</field> 
             as WKT for point, linestring, polygon

      -->
    <dynamicField name="*_pt"     type="location"     stored="true" indexed="true"/>
    <dynamicField name="*_bbox"   type="location_rpt" stored="true" indexed="true"/>
    <dynamicField name="*_geom"   type="location_jts" stored="true" indexed="true"/>
  </fields>
  <types>
    ...
    <fieldType name="location" class="solr.LatLonType" subFieldSuffix="_d"/>
    <fieldType name="location_rpt" class="solr.SpatialRecursivePrefixTreeFieldType"
               distErrPct="0.025"
               maxDistErr="0.000009"
               units="degrees"
            />
    <fieldType name="location_jts" class="solr.SpatialRecursivePrefixTreeFieldType"
               spatialContextFactory="com.spatial4j.core.context.jts.JtsSpatialContextFactory"
               distErrPct="0.025"
               maxDistErr="0.000009"
               units="degrees"
            />
  </types>
</schema>
{code}


----
h1. Solr queries

* Use the Solr query interface with LatLon data on [sul-solr-a|http://sul-solr-a/solr/#/] to try these using ogp core.
* For the polygon or JTS queries use [ogpapp-test|http://localhost:8983/solr/#/] via ssh tunnel to jetty 8983.

h2. Solr 3: Pseudo-spatial using _solr.LatLon_

{warning}
solr.LatLon does not correctly work across the international dateline in these queries
{warning}

h3. Search for point within 50 km of N40 W114

Note: Solr _bbox_ uses circle with radius not rectangles.

{code:xml}
<str name="d">50</str>
<str name="q">*:*</str>
<str name="sfield">layer_latlon</str>
<str name="pt">40,-114</str>
<str name="fq">{!geofilt}</str>
{code}


h3. Search for single point _within_ a bounding box of SW=40,-120 NE=50,-110

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_latlon:[40,-120 TO 50,-110]</str>
{code}

h3. Search for bounding box _within_ a bounding box of SW=20,-160 NE=70,-70

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_sw_latlon:[20,-160 TO 70,-70] AND layer_ne_latlon:[20,-160 TO 70,-70]</str>
{code}

h2. Solr 4 Spatial -- non JTS

h3. Search for point _within_ a bounding box of SW=20,-160 NE=70,-70

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_pt:"Intersects(-160 20 -70 70)"</str>
{code}

h3. Search for bounding box _within_ a bounding box of SW=20,-160 NE=70,-70

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_sw_pt:[20,-160 TO 70,-70] AND layer_ne_pt:[20,-160 TO 70,-70]</str>
{code}


h3. Solr 4: ... using polygon intersection

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_bbox:"Intersects(-160 20 -70 70)"</str>
{code}


h3. Solr 4: ... using polygon containment

{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_bbox:"IsWithin(-160 20 -150 30)"</str>
{code}

h3. Solr 4: ... using polygon containment for spatial relevancy

{code:xml}
<str name="q">layer_bbox:"IsWithin(-160 20 -150 30)"^10 text:railroad</str>
<str name="fq">layer_bbox:"Intersects(-160 20 -150 30)"</str>
{code}


h2. Solr 4 Spatial -- JTS

{warning}
This query requires [JTS|http://tsusiatsoftware.net/jts/main.html] installed in Solr 4
{warning}


h3. Search for bbox _intersecting_ bounding box of SW=20,-160 NE=70,-70 using polygon intersection


{code:xml}
<str name="q">*:*</str>
<str name="fq">layer_bbox:"Intersects(POLYGON((-160 20, -160 70, -70 70, -70 20, -160 20)))"</str>
{code}



h2. Scoring formula

{code}
text^1
dc_description_ti^2
dc_creator_ti^3
dc_publisher_ti^3
layer_collection_ti^4
dc_subject_tmi^5
dc_coverage_spatial_tmi^5
dc_coverage_temporal_tmi^5
dc_title_ti^6
dc_rights_ti^7
dc_source_ti^8
layer_geom_type_ti^9
layer_slug_ti^10
dc_identifier_ti^10
{code}

h2. Facets

{code:xml}
<str name="facet.field">dc_coverage_spatial_sm</str>
<str name="facet.field">dc_creator_s</str>
<str name="facet.field">dc_format_s</str>
<str name="facet.field">dc_language_s</str>
<str name="facet.field">dc_publisher_s</str>
<str name="facet.field">dc_rights_s</str>
<str name="facet.field">dc_source_s</str>
<str name="facet.field">dc_subject_sm</str>
<str name="facet.field">layer_collection_s</str>
<str name="facet.field">layer_geom_type_s</str>
<str name="facet.field">layer_srs_s</str>
<str name="facet.field">layer_year_i</str>
{code}


----
h1. Solr example documents

See [https://github.com/sul-dlss/geohydra/blob/master/ogp/transform.rb].
Ideally, these metadata would be generated from MODS, or FGDC, or ISO 19139.

{code}
      {
        "uuid": "http://purl.stanford.edu/zy658cr1728",
        "dc_coverage_spatial_sm": [
          "Andaman and Nicobar Islands",
          "Andaman",
          "Nicobar",
          "Car Nicobar Island",
          "Port Blair",
          "Indira Point",
          "Diglipur",
          "Nancowry Island"
        ],
        "dc_creator_s": "ML InfoMap (Firm)",
        "dc_date_dt": "2001-01-01T00:00:00Z",
        "dc_description_t": "This point dataset shows village locations with socio-demographic and economic Census data for 2001 for the Union Territory of Andaman and Nicobar Islands, India linked to the 2001 Census. Includes village socio-demographic and economic Census attribute data such as total population, population by sex, household, literacy and illiteracy rates, and employment by industry. This layer is part of the VillageMap dataset which includes socio-demographic and economic Census data for 2001 at the village level for all the states of India. This data layer is sourced from secondary government sources, chiefly Survey of India, Census of India, Election Commission, etc. This map Includes data for 547 villages, 3 towns, 2 districts, and 1 union territory.; This dataset is intended for researchers, students, and policy makers for reference and mapping purposes, and may be used for village level demographic analysis within basic applications to support graphical overlays and analysis with other spatial data.; ",
        "dc_format_s": "Shapefile",
        "dc_identifier_s": "http://purl.stanford.edu/zy658cr1728",
        "dc_language_s": "English",
        "dc_publisher_s": "ML InfoMap (Firm)",
        "dc_relation_url": "http://purl.stanford.edu/zy658cr1728",
        "dc_rights_s": "Restricted",
        "dc_source_s": "Stanford",
        "dc_subject_sm": [
          "Human settlements",
          "Villages",
          "Census",
          "Demography",
          "Population",
          "Sex ratio",
          "Housing",
          "Labor supply",
          "Caste",
          "Literacy",
          "Society",
          "Location"
        ],
        "dc_title_s": "Andaman and Nicobar, India: Village Socio-Demographic and Economic Census Data, 2001",
        "dc_type_s": "Dataset",
        "layer_bbox": "92.234924 6.761581 94.262535 13.637013",
        "layer_collection_s": "My Collection",
        "layer_geom": "POLYGON((92.234924 13.637013, 94.262535 13.637013, 94.262535 6.761581, 92.234924 6.761581, 92.234924 13.637013))",
        "layer_ne_pt_0_d": 13.637013,
        "layer_ne_pt_1_d": 94.262535,
        "layer_ne_pt": "13.637013,94.262535",
        "layer_sw_pt_0_d": 6.761581,
        "layer_sw_pt_1_d": 92.234924,
        "layer_sw_pt": "6.761581,92.234924",
        "layer_slug_s": "stanford-zy658cr1728",
        "layer_id_s": "druid:zy658cr1728",
        "layer_srs_s": "EPSG:4326",
        "layer_geom_type_s": "Point",
        "layer_wfs_url": "http://geowebservices-restricted.stanford.edu/geoserver/wfs",
        "layer_wms_url": "http://geowebservices-restricted.stanford.edu/geoserver/wms",
        "layer_year_i": 2001,
        "_version_": 1461588063304024000,
        "timestamp": "2014-03-03T20:36:37.138Z",
        "score": 1.6703978
      }
{code}

h1. Links

* Solr 4: [http://wiki.apache.org/solr/SolrAdaptersForLuceneSpatial4]
* Solr 3: [http://wiki.apache.org/solr/SpatialSearch]
* JTS: [http://tsusiatsoftware.net/jts/main.html]