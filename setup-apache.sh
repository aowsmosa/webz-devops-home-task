#!/bin/bash
set -e
HOST=$(hostname)
FIP=172.20.0.100

mkdir -p /var/www/webz
cat > /var/www/webz/index.html <<HTML
<!DOCTYPE html>
<html><head><title>Junior DevOps Engineer - Home Task</title></head>
<body><h1>Junior DevOps Engineer - Home Task</h1></body></html>
HTML

echo "Listen ${FIP}:80" > /etc/apache2/ports.conf

cat > /etc/apache2/sites-available/webz.conf <<CONF
<VirtualHost ${FIP}:80>
    ServerName webz-cluster
    DocumentRoot /var/www/webz
    Header always set X-Served-By "${HOST}"
    <Directory /var/www/webz>
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/webz-error.log
    CustomLog \${APACHE_LOG_DIR}/webz-access.log combined
</VirtualHost>
CONF

echo "ServerName webz-cluster" > /etc/apache2/conf-available/servername.conf
a2enmod headers >/dev/null
a2dissite 000-default >/dev/null
a2ensite webz >/dev/null
a2enconf servername >/dev/null
apache2ctl configtest
