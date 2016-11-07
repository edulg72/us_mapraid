#!/bin/bash

cd /var/www/mapraid/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from ur; delete from mp;'

ruby scan_UR.rb $1 $2 -103.5 21.12 -102.96 21.03 0.09
ruby scan_UR.rb $1 $2 -103.77 21.03 -102.96 20.94 0.09
ruby scan_UR.rb $1 $2 -103.77 20.94 -102.87 20.85 0.09
ruby scan_UR.rb $1 $2 -103.77 20.85 -102.87 20.76 0.09
ruby scan_UR.rb $1 $2 -103.77 20.76 -102.78 20.67 0.09
ruby scan_UR.rb $1 $2 -103.77 20.67 -102.78 20.58 0.09
ruby scan_UR.rb $1 $2 -103.77 20.58 -102.78 20.49 0.09
ruby scan_UR.rb $1 $2 -103.77 20.49 -102.78 20.4 0.09
ruby scan_UR.rb $1 $2 -103.77 20.4 -102.78 20.31 0.09
ruby scan_UR.rb $1 $2 -103.77 20.31 -102.87 20.22 0.09
ruby scan_UR.rb $1 $2 -103.68 20.22 -102.96 20.13 0.09
ruby scan_UR.rb $1 $2 -103.68 20.13 -103.05 20.04 0.09
ruby scan_UR.rb $1 $2 -103.5 20.04 -103.05 19.95 0.09

psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'update ur set city_id = (select gid from cities_mapraid where ST_Contains(geom, ur.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'update mp set city_id = (select gid from cities_mapraid where ST_Contains(geom, mp.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from ur where city_id is null; delete from mp where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_ur;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_mp;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'ur';"

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
