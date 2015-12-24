#!/bin/bash

cd $OPENSHIFT_HOMEDIR/app-root/repo/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'delete from pu; delete from places;'

# León
ruby scan_PU.rb $1 $2 -102.096 21.3302 -101.318 20.6874 0.1

# Merida
ruby scan_PU.rb $1 $2 -89.8878 21.206 -89.2721 20.6017 0.1

# Queretaro
ruby scan_PU.rb $1 $2 -100.597 20.971 -100.041 20.2855 0.1

psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'update pu set city_id = (select gid from cities_mapraid where ST_Contains(geom, pu.position) limit 1) where city_id is null;'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'delete from pu where city_id is null;'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'select vw_pu_refresh_table();'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'pu';"

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
