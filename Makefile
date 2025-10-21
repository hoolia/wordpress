include openshift/params/test.ini

help:
	@echo "build     - Builds Docker Image"
	@echo "install   - Build   + Generate TLS Certificate"
	@echo "run/start - Install + Up"
	@echo "up        - Start Wordpress (Docker-Compose up)"
	@echo "down      - Stop  Wordpress (Docker-Compose down)"
	@echo "stop      - Stop    + Delete all data"
	@echo "status    - Show running state (Docker-Compose ps)"
	@echo "logs      - Show PHP Wordpress logs"
	@echo "query     - MySQL command prompt"
	@echo "export    - Makes a mysqldump and saves it to git"
	@echo "apply     - Deploy to Openshift"

build:
	gunzip -c backup/mysql/$(NAMESPACE)/$(APP_NAME).sql.gz |sed 's/utf8mb4_0900_ai_ci/utf8mb4_general_ci/g' >mysql/V0__site.sql && gzip -f mysql/V0__site.sql
	sudo docker build -t image-registry.openshift-image-registry.svc.cluster.local:50000/$(NAMESPACE)/$(APP_NAME):latest .

install: build
	mkdir -p ./bin/ssl
	# If file exists or create new cert.pem
	[ -s ./bin/ssl/cert.pem ] || openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes \
                                             -out ./bin/ssl/wordpress.crt -keyout ./bin/ssl/wordpress.key \
                                             -subj "/C=SI/ST=Ljubljana/L=Ljubljana/O=Security/OU=IT Department/CN=wordpress.test" \
                                             && cat ./bin/ssl/wordpress.crt ./bin/ssl/wordpress.key > ./bin/ssl/cert.pem
	sudo setenforce 0

run: install
	git config core.fileMode false
	git config --add safe.directory `pwd`
	-sudo chmod --quiet -R a+rwX ./html 2>&1 #|grep -v "Operation not permitted"
	sudo docker-compose up -d

start: run

restart: stop start

up:
	sudo docker-compose up -d

down:
	sudo docker-compose down

stop: down
	sudo docker volume rm wordpress-db_data

clean:
	sudo rm -rf ./html/index.php ./html/health.php ./html/xmlrpc.php ./html/wp-admin/ ./html/wp-content/index.php ./html/wp-content/themes/index.php ./html/wp-content/themes/twenty*/ ./html/wp-includes ./html/wp-content/cache/* 

status:
	sudo docker-compose ps

logs:
	sudo docker logs -f wordpress

query:
	sudo docker exec -ti db bash -c 'mysql -u $${MYSQL_USER} --password=$${MYSQL_PASSWORD} $${MYSQL_DATABASE}'

exec:
	sudo docker exec -ti wordpress bash

export:
	sudo docker exec -ti db /bin/bash -c 'echo "DELETE FROM wp_options   WHERE option_name LIKE \"%_transient_%\"" |mysql -u $${MYSQL_USER} --password="$${MYSQL_PASSWORD}" $${MYSQL_DATABASE}'
	sudo docker exec -ti db /bin/bash -c 'mysqldump --no-tablespaces --ignore-table=$${MYSQL_DATABASE}.wp_redirection_404 --ignore-table=$${MYSQL_DATABASE}.wp_3_redirection_404 --ignore-table=$${MYSQL_DATABASE}.flyway_schema_history -u $${MYSQL_USER} --password="$${MYSQL_PASSWORD}" $${MYSQL_DATABASE} >/tmp/dump.sql && gzip /tmp/dump.sql'
	sudo docker cp db:/tmp/dump.sql.gz mysql/V9__site.sql.gz
	git add mysql/V9__site.sql.gz
	#git add .
	#git commit -m "`date`"
	#git push

apply:
	oc get ns $(NAMESPACE) || oc create ns $(NAMESPACE)
	oc -n $(NAMESPACE) process --allow-missing-template-keys --ignore-unknown-parameters --param-file openshift/params/prod.ini -f openshift/templates/db.yaml |oc -n $(NAMESPACE) apply -f -
	oc -n $(NAMESPACE) process --allow-missing-template-keys --ignore-unknown-parameters --param-file openshift/params/prod.ini -f openshift/templates/cache.yaml |oc -n $(NAMESPACE) apply -f -
	oc -n $(NAMESPACE) process --allow-missing-template-keys --ignore-unknown-parameters --param-file openshift/params/prod.ini -f openshift/templates/deploy.yaml |oc -n $(NAMESPACE) apply -f -
	oc start-build $(APP_NAME) --from-dir=. -Fw
