#!/bin/bash

cd /var/www/us_mapraid/scripts/

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

ruby scan_segments.rb $1 $2 -80.67 40.65 -80.49 40.2 0.09
ruby scan_segments.rb $1 $2 -80.76 40.2 -80.49 40.02 0.09
ruby scan_segments.rb $1 $2 -80.85 40.02 -80.49 39.84 0.09
ruby scan_segments.rb $1 $2 -80.94 39.84 -80.49 39.75 0.09
ruby scan_segments.rb $1 $2 -80.94 39.75 -79.41 39.66 0.09
ruby scan_segments.rb $1 $2 -78.24 39.75 -78.06 39.66 0.09
ruby scan_segments.rb $1 $2 -81.03 39.66 -79.41 39.57 0.09
ruby scan_segments.rb $1 $2 -78.87 39.66 -78.69 39.57 0.09
ruby scan_segments.rb $1 $2 -78.51 39.66 -77.79 39.57 0.09
ruby scan_segments.rb $1 $2 -81.12 39.57 -79.41 39.48 0.09
ruby scan_segments.rb $1 $2 -79.14 39.57 -77.7 39.48 0.09
ruby scan_segments.rb $1 $2 -81.48 39.48 -81.39 39.39 0.09
ruby scan_segments.rb $1 $2 -81.3 39.48 -79.41 39.39 0.09
ruby scan_segments.rb $1 $2 -79.23 39.48 -77.7 39.39 0.09
ruby scan_segments.rb $1 $2 -81.57 39.39 -78.33 39.3 0.09
ruby scan_segments.rb $1 $2 -78.24 39.39 -77.7 39.3 0.09
ruby scan_segments.rb $1 $2 -81.75 39.3 -78.33 39.21 0.09
ruby scan_segments.rb $1 $2 -78.15 39.3 -77.7 39.21 0.09
ruby scan_segments.rb $1 $2 -81.84 39.21 -78.33 39.12 0.09
ruby scan_segments.rb $1 $2 -77.97 39.21 -77.79 39.12 0.09
ruby scan_segments.rb $1 $2 -81.84 39.12 -78.42 39.03 0.09
ruby scan_segments.rb $1 $2 -82.11 39.03 -78.51 38.94 0.09
ruby scan_segments.rb $1 $2 -82.2 38.94 -78.6 38.85 0.09
ruby scan_segments.rb $1 $2 -82.29 38.85 -78.78 38.76 0.09
ruby scan_segments.rb $1 $2 -82.2 38.76 -79.05 38.67 0.09
ruby scan_segments.rb $1 $2 -82.29 38.67 -79.05 38.58 0.09
ruby scan_segments.rb $1 $2 -82.38 38.58 -79.14 38.49 0.09
ruby scan_segments.rb $1 $2 -82.65 38.49 -79.68 38.4 0.09
ruby scan_segments.rb $1 $2 -79.5 38.49 -79.14 38.4 0.09
ruby scan_segments.rb $1 $2 -82.65 38.4 -79.68 38.31 0.09
ruby scan_segments.rb $1 $2 -82.65 38.31 -79.77 38.22 0.09
ruby scan_segments.rb $1 $2 -82.65 38.22 -79.86 38.04 0.09
ruby scan_segments.rb $1 $2 -82.56 38.04 -79.95 37.95 0.09
ruby scan_segments.rb $1 $2 -82.56 37.95 -80.04 37.86 0.09
ruby scan_segments.rb $1 $2 -82.47 37.86 -80.13 37.77 0.09
ruby scan_segments.rb $1 $2 -82.38 37.77 -80.22 37.59 0.09
ruby scan_segments.rb $1 $2 -82.2 37.59 -80.22 37.5 0.09
ruby scan_segments.rb $1 $2 -82.02 37.5 -80.31 37.41 0.09
ruby scan_segments.rb $1 $2 -82.02 37.41 -80.67 37.32 0.09
ruby scan_segments.rb $1 $2 -81.93 37.32 -80.85 37.23 0.09
ruby scan_segments.rb $1 $2 -81.75 37.23 -81.48 37.14 0.09

psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update segments set city_id = (select gid from cities_mapraid where ST_Contains(geom, ST_SetSRID(ST_Point(segments.longitude, segments.latitude), 4326)) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from segments where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from streets where id in (select id from streets except select distinct street_id from segments);'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'update segments s1 set dc_density = (select count(*) from segments s2 where not s2.connected and s2.latitude between (s1.latitude - 0.01) and (s1.latitude + 0.01) and s2.longitude between (s1.longitude - 0.01) and (s1.longitude + 0.01)) where not s1.connected and s1.dc_density is null;'
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "delete from updates where object = 'segments';"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "insert into updates (updated_at, object) values (current_timestamp,'segments');"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "refresh materialized view vw_segments;"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c "refresh materialized view vw_streets;"
psql -h $POSTGRESQL_DB_HOST -d us_mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum analyze;'

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
