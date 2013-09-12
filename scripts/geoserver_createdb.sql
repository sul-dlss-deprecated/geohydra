CREATE EXTENSION plpgsql
 SCHEMA pg_catalog
 VERSION "1.0";

CREATE EXTENSION postgis
 SCHEMA public
 VERSION "2.0.1";

CREATE SCHEMA druid
  AUTHORIZATION geostaff;

GRANT ALL ON SCHEMA druid TO geostaff;
GRANT USAGE ON SCHEMA druid TO georead;

SET search_path TO public;

CREATE TABLE registered_layers
(
  druid character varying(11) NOT NULL, -- aa111aa1111
  layername character varying NOT NULL,
  title character varying NOT NULL,
  CONSTRAINT pk_registered_layers PRIMARY KEY (druid)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE registered_layers
  OWNER TO geostaff;
COMMENT ON COLUMN registered_layers.druid IS 'aa111aa1111';