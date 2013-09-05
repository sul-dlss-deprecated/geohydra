#!/bin/bash -x
export PATH="/usr/pgsql-9.2/bin:$PATH"

createdb -e geoserver
createuser -e -W --encrypted --replication geostaff
createuser -e -W --encrypted georead