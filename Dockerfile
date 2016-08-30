FROM library/wordpress:apache

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


USER 0

ADD s2i/bin/*   /usr/local/s2i/

#RUN  curl https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/4.0/flyway-commandline-4.0-linux-x64.tar.gz |tar -C/usr/local -zx; \
#     chmod +x   /usr/local/flyway-4.0/flyway; \
#     rm -rf /usr/local/flyway-4.0/sql; \
#     ln -s /var/www/sql/ /usr/local/flyway-4.0
#COPY bin/flyway.sh             /usr/local/bin/flyway
#COPY configuration/flyway.conf /usr/local/flyway-4.0/conf/flyway.conf

USER 33

ENTRYPOINT ["/usr/local/s2i/run"]
CMD ["apache2-foreground"]
