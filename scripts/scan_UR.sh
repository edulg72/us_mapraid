#!/bin/bash

cd $OPENSHIFT_REPO_DIR/scripts

echo "Start: $(date '+%d/%m/%Y %H:%M:%S')"

psql -c 'delete from ur; delete from mp;'

# León
ruby scan_UR.rb $1 $2 -102.096 21.3302 -101.318 20.6874 0.05

# Merida
ruby scan_UR.rb $1 $2 -89.8878 21.206 -89.2721 20.6017 0.05

# Queretaro
ruby scan_UR.rb $1 $2 -100.597 20.971 -100.041 20.2855 0.05

psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'update ur set city_id = (select gid from cities_mapraid where ST_Contains(geom, ur.position) limit 1) where city_id is null;'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'update mp set city_id = (select gid from cities_mapraid where ST_Contains(geom, mp.position) limit 1) where city_id is null;'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'delete from ur where city_id is null; delete from mp where city_id is null;'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'select vw_ur_refresh_table();'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c 'select vw_mp_refresh_table();'
psql -h $OPENSHIFT_POSTGRESQL_DB_HOST -d $OPENSHIFT_APP_NAME -U $OPENSHIFT_POSTGRESQL_DB_USERNAME -c "update updates set updated_at = current_timestamp where object = 'ur';"

echo "End: $(date '+%d/%m/%Y %H:%M:%S')"
