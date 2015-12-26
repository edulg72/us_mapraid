#!/bin/bash

cd /var/www/segments/scripts/

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

# León
ruby scan_segments.rb $1 $2 -102.096 21.3302 -101.318 20.6874 0.09

# Merida
ruby scan_segments.rb $1 $2 -89.8878 21.206 -89.2721 20.6017 0.09

# Queretaro
ruby scan_segments.rb $1 $2 -100.597 20.971 -100.041 20.2855 0.09

psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c 'update segments set city_id = (select gid from cities_mapraid where ST_Contains(geom, ST_SetSRID(ST_Point(segments.longitude, segments.latitude), 4326)) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c 'delete from segments where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c 'delete from streets where id in (select id from streets except select distinct street_id from segments);'
psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c 'update segments s1 set dc_density = (select count(*) from segments s2 where not s2.connected and s2.latitude between (s1.latitude - 0.01) and (s1.latitude + 0.01) and s2.longitude between (s1.longitude - 0.01) and (s1.longitude + 0.01)) where not s1.connected and s1.dc_density is null;'
psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'segments';"
psql -h $POSTGRESQL_DB_HOST -d $POSTGRESQL_DB_NAME -U $POSTGRESQL_DB_USERNAME -c 'vacuum analyze;'

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
