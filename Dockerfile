FROM --platform=linux/x86_64 wordpress:6.8.3-php8.4-apache

LABEL com.redhat.deployments-dir="/var/www/html" \
      com.redhat.dev-mode="DEBUG:true" \
      io.k8s.description="Wordpress + Database-versioning" \
      io.k8s.display-name="Wordpress + Flyway" \
      io.openshift.expose-services="8080:http" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      io.openshift.tags="builder,php,php68,rh-php68,wordpress" \
      io.openshift.wants=mysql \
      io.openshift.min-memory=200Mi \
      io.openshift.min-cpu=0.1

EXPOSE 8080

USER 0

## FlyWay - Database Versioning ##
RUN  curl -sSLk https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/11.7.2/flyway-commandline-11.7.2-linux-x64.tar.gz |tar -C/usr/local -zx; \
     chmod +x   /usr/local/flyway-11.7.2/flyway; \
     rm -rf /usr/local/flyway-11.7.2/sql; \
     ln -s /var/www/sql/ /usr/local/flyway-11.7.2
COPY bin/flyway.sh             /usr/local/bin/flyway
COPY configuration/flyway.conf /usr/local/flyway-11.7.2/conf/flyway.conf

## Additional Utils ##
RUN curl -sSLk -o /usr/local/bin/wp-cli https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
ADD bin/*.sh   /usr/local/bin/
COPY bin/mysql.sh /usr/local/bin/mysql
RUN chmod +x /usr/local/bin/*

## Apache HTTPD - WebServer ##
COPY configuration/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf
COPY configuration/apache2/ports.conf /etc/apache2/ports.conf
COPY configuration/wp-config.php /usr/src/wordpress/wp-config-docker.php

## PHP Dependency - MySQL ##
RUN apt-get update && apt-get install -y default-mysql-client

## PHP Dependency - SMTP ##
RUN apt-get update && apt-get install -y msmtp msmtp-mta
ADD configuration/msmtprc /etc/msmtprc
ADD configuration/ssl/*.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

## PHP Plugins - MemCacheD ##
RUN apt-get update && apt-get install -y libmemcached-dev zlib1g-dev \
    && pecl install memcache  \
    && pecl install memcached \
    && docker-php-ext-enable memcache \
    && docker-php-ext-enable memcached

## PHP Plugins - MemCacheD ##
RUN apt-get update && apt-get install -y libzip-dev \
    && pecl install redis \
    && docker-php-ext-enable redis


## PHP Plugins - Misc ##
RUN docker-php-ext-enable opcache

## PHP Config ##
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY configuration/php.conf.d/ "$PHP_INI_DIR/conf.d/"

## Site itself ##
ADD              /html        /usr/src/wordpress
ADD --chmod=777  /mysql       /var/www/sql
#ADD --chmod=777 /archive     /var/www/archive
RUN chmod a+rwX  /var/www/sql /var/www/html

## Minify ##
#RUN apt-get install -y webpack
#RUN cd /usr/src/wordpress/wp-content/plugins/happy-quiz && NODE_ENV=production webpack -p --config webpack.config.js --mode production

## Wordpress Plugins ##
RUN apt-get install -y unzip vim less \
 && cd /usr/src/wordpress/wp-content/plugins \
 && for plugin in `ls */.gitkeep |cut -d/ -f1`; do \
 (version=`cat ${plugin}/version.txt 2>/dev/null`; echo "Installing Wordpress Plugin ${plugin} ${version}."; curl -sSLk -o ./${plugin}.zip https://downloads.wordpress.org/plugin/${plugin}${version}.zip && unzip -qo ${plugin}.zip; rm -f ${plugin}.zip || true) || true; done;
#echo "Installing Wordpress Plugin js_composer."; curl -sSLk -o ./js_composer.zip `curl -sSLk 'https://support.wpbakery.com/updates/download-link?product=vc&url=https%3A%2F%2Findehuidvan-nl-front-web-happyhorizon-scale.apps.scale-8747d275.p773994914889.aws-emea.sanofi.com&key=1a4e99fa-6c76-4e6a-89a2-0381852a00cb' |json_pp |grep url |awk -F\" '{print $4}'` && unzip -qo js_composer.zip; rm -f js_composer.zip; pwd;

## Runtime Config ##
USER 33
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
