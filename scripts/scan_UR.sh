#!/bin/bash

cd /var/www/us_mapraid/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from ur; delete from mp;'

ruby scan_UR.rb $1 $2 -81.15 40.65 -80.15 40.15 0.5
ruby scan_UR.rb $1 $2 -81.15 40.15 -79.15 39.65 0.5
ruby scan_UR.rb $1 $2 -78.65 40.15 -77.65 39.65 0.5
ruby scan_UR.rb $1 $2 -82.15 39.65 -77.65 39.15 0.5
ruby scan_UR.rb $1 $2 -82.65 39.15 -77.65 38.65 0.5
ruby scan_UR.rb $1 $2 -82.65 38.65 -78.65 38.15 0.5
ruby scan_UR.rb $1 $2 -82.65 38.15 -79.65 37.65 0.5
ruby scan_UR.rb $1 $2 -82.65 37.65 -80.15 37.15 0.5

psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update ur set city_id = (select gid from cities_mapraid where ST_Contains(geom, ur.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update mp set city_id = (select gid from cities_mapraid where ST_Contains(geom, mp.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update mp set weight = 0 where weight is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from ur where city_id is null; delete from mp where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_ur;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_mp;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'ur';"

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
