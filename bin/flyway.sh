#!/bin/sh -x

echo "Found SQL files:"
cd /usr/local/flyway-4.0/sql
ls -l *.sql

/usr/local/flyway-4.0/flyway -X $* \
  -url=${WORDPRESS_DB_HOST}
  -user=${MYSQL_ENV_MYSQL_USER} \
  -password=${DMYSQL_ENV_MYSQL_PASSWORD} \
  -schemas=${MYSQL_ENV_MYSQL_DATABASE}
#  -target=${OPENSHIFT_BUILD_REFERENCE/v/}
