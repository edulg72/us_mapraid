#!/bin/bash

cd /var/www/us_mapraid/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from pu; delete from places;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum pu;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum places;'

ruby scan_PU.rb $1 $2 -81.15 40.65 -80.15 40.15 0.5
ruby scan_PU.rb $1 $2 -81.15 40.15 -79.15 39.65 0.5
ruby scan_PU.rb $1 $2 -78.65 40.15 -77.65 39.65 0.5
ruby scan_PU.rb $1 $2 -82.15 39.65 -77.65 39.15 0.5
ruby scan_PU.rb $1 $2 -82.65 39.15 -77.65 38.65 0.5
ruby scan_PU.rb $1 $2 -82.65 38.65 -78.65 38.15 0.5
ruby scan_PU.rb $1 $2 -82.65 38.15 -79.65 37.65 0.5
ruby scan_PU.rb $1 $2 -82.65 37.65 -80.15 37.15 0.5

psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update pu set city_id = (select gid from cities_mapraid where ST_Contains(geom, pu.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from pu where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_pu;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'pu';"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum pu;'

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
