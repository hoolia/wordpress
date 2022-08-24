#FROM hoolia/wordpress:3.8.38
FROM docker.io/centurylink/wordpress:3.9.1

LABEL com.redhat.deployments-dir="/var/www/html" \
      com.redhat.dev-mode="DEBUG:true" \
      io.k8s.description="Wordpress + Database-versioning" \
      io.k8s.display-name="Wordpress + Flyway" \
      io.openshift.expose-services="8080:http" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      io.openshift.tags="builder,php,php56,rh-php56,wordpress" \
      io.openshift.wants=mysql \
      io.openshift.min-memory=200Mi \
      io.openshift.min-cpu=0.1

EXPOSE 8080

USER 0

ADD s2i/bin/*   /usr/local/s2i/
#ADD flyway-commandline-7.8.1-linux-x64.tar.gz /usr/local
RUN  curl https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/7.8.1/flyway-commandline-7.8.1-linux-x64.tar.gz |tar -C/usr/local -zx; \
     chmod +x   /usr/local/flyway-7.8.1/flyway; \
     rm -rf /usr/local/flyway-7.8.1/sql; \
     ln -s /var/www/sql/ /usr/local/flyway-7.8.1
COPY bin/flyway.sh             /usr/local/bin/flyway
COPY configuration/flyway.conf /usr/local/flyway-7.8.1/conf/flyway.conf
COPY configuration/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY configuration/apache2/ports.conf /etc/apache2/ports.conf
COPY configuration/wp-config.php /var/www/html/wp-config.php

USER 33

ENTRYPOINT ["/usr/local/s2i/run"]
