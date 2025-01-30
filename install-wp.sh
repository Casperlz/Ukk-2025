#!/bin/bash

#install php 8.3
apt install php8.3-cli php8.3-fpm php8.3-mysql php8.3-opcache php8.3-mbstring php8.3-xml php8.3-gd php8.3-curl -y

#install Database server
apt install mariadb-server mariadb-client -y

#install web server
apt install nginx -y

#membuat database
DB_NAME="wordpress_db"
DB_USER="wp_user"
DB_PASSWORD="password_kuat"

mysql -u root << EOF
CREATE DATABASE ${DB_NAME};
GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOF

#download wordpress
wget https://wordpress.org/latest.tar.gz

#ekstrak file .tar.gz
tar xf latest.tar.gz

#memindahkan folder
mv wordpress/ /var/www/html/

#copy config.php
cp -R /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

#menambahkan owner
chown -R www-data:www-data /var/www/html/wordpress/
#mengubah pada file config.php
sed -i 's/wordpress_db/${DB_NAME}/g' /var/www/html/wordpress/wp-config.php
sed -i 's/wp_user/${DB_USER}/g' /var/www/html/wordpress/wp-config.php
sed -i 's/DB_PASSWORD/${DB_PASSWORD}/g' /var/www/html/wordpress/wp-config.php

#konfigurasi web-server
tee /etc/nginx/sites-available/domain.conf << EOF > /dev/null
server {
    listen 80;
    server_name www.ukk-namaKamu.net ukk-namaKamu.net;

    root /var/www/html/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|jpg|jpeg|png|gif|ico)$ {
        expires max;
        log_not_found off;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

#membuat symlink untul direktory lain
ln -s /etc/nginx/sites-available/ukk-randi.net.conf /etc/nginx/sites-enabled/

#reload nginx
systemctl reload nginx.service
