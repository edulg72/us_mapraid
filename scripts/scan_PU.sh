#!/bin/bash

cd /var/www/mapraid/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from pu; delete from places;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum pu;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum places;'

ruby scan_PU.rb $1 $2 -103.5 21.12 -102.96 21.03 0.09
ruby scan_PU.rb $1 $2 -103.77 21.03 -102.96 20.94 0.09
ruby scan_PU.rb $1 $2 -103.77 20.94 -102.87 20.85 0.09
ruby scan_PU.rb $1 $2 -103.77 20.85 -102.87 20.76 0.09
ruby scan_PU.rb $1 $2 -103.77 20.76 -102.78 20.67 0.09
ruby scan_PU.rb $1 $2 -103.77 20.67 -102.78 20.58 0.09
ruby scan_PU.rb $1 $2 -103.77 20.58 -102.78 20.49 0.09
ruby scan_PU.rb $1 $2 -103.77 20.49 -102.78 20.4 0.09
ruby scan_PU.rb $1 $2 -103.77 20.4 -102.78 20.31 0.09
ruby scan_PU.rb $1 $2 -103.77 20.31 -102.87 20.22 0.09
ruby scan_PU.rb $1 $2 -103.68 20.22 -102.96 20.13 0.09
ruby scan_PU.rb $1 $2 -103.68 20.13 -103.05 20.04 0.09
ruby scan_PU.rb $1 $2 -103.5 20.04 -103.05 19.95 0.09

psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'update pu set city_id = (select gid from cities_mapraid where ST_Contains(geom, pu.position) limit 1) where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'delete from pu where city_id is null;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'refresh materialized view vw_pu;'
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'pu';"
psql -h $POSTGRESQL_DB_HOST -d mapraid -U $POSTGRESQL_DB_USERNAME -c 'vacuum pu;'

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
