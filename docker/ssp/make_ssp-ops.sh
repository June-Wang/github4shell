#!/bin/bash

docker run -d -p 8765:80 \
--name ssp-ops \
--restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/ssp/conf/config.inc.php:/usr/share/self-service-password/conf/config.inc.php \
ops/self-service-password
#-v /data/ssp/conf/php.ini:/usr/local/etc/php/php.ini \
#-v /data/ssp/conf/000-default.conf:/etc/apache2/sites-available/000-default.conf \
