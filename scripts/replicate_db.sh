#!/bin/bash -x

export PGDATABASE="geoserver"
export PGHOST="kurma-db1-dev"
export PATH="/usr/pgsql-9.2/bin:$PATH"

pg_dump -n druid | PGHOST= psql -h kurma-db2-dev
