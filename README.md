# wordpress
Wordpress docker image.
Does not fiddle with mysql databases, stays within its wordpress-app scope. Therefore assumes a mysql database is created out-of-scope and should just be referenced to.

# Setup
```
oc project openshift
oc new-build https://github.com/hoolia/wordpress.git
```

# Changelog
- Initial: copy from library/wordpress
- 2015-09-14: Removed mysql dependency
- 2016-08-14: Added S2I scripts
- 2016-08-14: Added Flyway
- 2025-10-01: Added Redis Cache + MariaDB Operator
