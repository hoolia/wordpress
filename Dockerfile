FROM library/wordpress:apache

LABEL io.openshift.tags       wordpress
LABEL io.openshift.wants      mysql
LABEL io.openshift.min-memory 200Mi
LABEL io.openshift.min-cpu    0.1


COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
