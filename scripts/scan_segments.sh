#!/bin/bash

cd /var/www/mapraid/scripts/

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

ruby scan_segments.rb $1 $2 -103.5 21.12 -102.96 21.03 0.09
ruby scan_segments.rb $1 $2 -103.77 21.03 -102.96 20.94 0.09
ruby scan_segments.rb $1 $2 -103.77 20.94 -102.87 20.85 0.09
ruby scan_segments.rb $1 $2 -103.77 20.85 -102.87 20.76 0.09
ruby scan_segments.rb $1 $2 -103.77 20.76 -102.78 20.67 0.09
ruby scan_segments.rb $1 $2 -103.77 20.67 -102.78 20.58 0.09
ruby scan_segments.rb $1 $2 -103.77 20.58 -102.78 20.49 0.09
ruby scan_segments.rb $1 $2 -103.77 20.49 -102.78 20.4 0.09
ruby scan_segments.rb $1 $2 -103.77 20.4 -102.78 20.31 0.09
ruby scan_segments.rb $1 $2 -103.77 20.31 -102.87 20.22 0.09
ruby scan_segments.rb $1 $2 -103.68 20.22 -102.96 20.13 0.09
ruby scan_segments.rb $1 $2 -103.68 20.13 -103.05 20.04 0.09
ruby scan_segments.rb $1 $2 -103.5 20.04 -103.05 19.95 0.09

psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'update segments set city_id = (select gid from cities_mapraid where ST_Contains(geom, ST_SetSRID(ST_Point(segments.longitude, segments.latitude), 4326)) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from segments where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from streets where id in (select id from streets except select distinct street_id from segments);'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'update segments s1 set dc_density = (select count(*) from segments s2 where not s2.connected and s2.latitude between (s1.latitude - 0.01) and (s1.latitude + 0.01) and s2.longitude between (s1.longitude - 0.01) and (s1.longitude + 0.01)) where not s1.connected and s1.dc_density is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "delete from updates where object = 'segments';"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "insert into updates (updated_at, object) values (current_timestamp,'segments');"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "refresh materialized view vw_segments;"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "refresh materialized view vw_streets;"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum analyze;'

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
