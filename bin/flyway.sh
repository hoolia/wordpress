#!/bin/bash -x

echo "Found SQL files:"
cd /usr/local/flyway*/sql
ls -l *.sql

/usr/local/flyway*/flyway -X $* \
  -url=jdbc:mysql://${WORDPRESS_DB_HOST:=mysql}:${WORDPRESS_DB_PORT:=3306}/${WORDPRESS_DB_NAME:=wordpress} \
  -user=${WORDPRESS_DB_USER:=root} \
  -password=${WORDPRESS_DB_PASSWORD} \
  -schemas=${WORDPRESS_DB_NAME:=wordpress}
