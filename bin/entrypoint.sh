#!/bin/bash

set -ex
env

echo "Decompressing SQL files ..."
gunzip /var/www/sql/*.gz || echo "No SQL files found to decompress"
ls -alh /var/www/sql/

echo "Migrating Database..."
for i in {1..5}; do 
	/usr/local/bin/flyway migrate \
	&& break || sleep 15
done

echo "Starting Wordpress ..."
exec docker-entrypoint.sh apache2-foreground
