#update & upgrade
apt update && apt upgrade -y

#install php
apt install apache2 php libapache2-mod-php php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl

#membuat database
echo "nama user"
read user
echo "nama database"
read db_name
echo "password"
read pswd

mysql -u root << EOF
CREATE DATABASE ${db_name};
GRANT ALL ON ${db_name}.* TO '${user}'@'localhost' IDENTIFIED BY '${pswd}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

#download wordpress
wget https://wordpress.org/latest.tar.gz

#ekstrak file .tar.gz
tar xf latest.tar.gz

#memindahkan folder
mv wordpress/ /var/www/html/

#copy config.php
cp -R /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

#mengubah pada file config.php
sed -i "s/database_name_here/${db_name}/g" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/${user}/g" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/${pswd}/g" /var/www/html/wordpress/wp-config.php

#mengubah izin
chown -R www-data:www-data /var/www/html/wordpress
chmod 755 -R /var/www/html/wordpress

#konfigurasi web server
echo "Nama domain kamu"
read domain
tee /etc/apache2/sites-available/${domain}.conf << EOF > /dev/null
<VirtualHost *:80>
     ServerAdmin ${domain}
      DocumentRoot /var/www/html/wordpress
     ServerName ${domain}

     <Directory /var/www/html/wordpress>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>

     ErrorLog ${APACHE_LOG_DIR}/${domain}_error.log
     CustomLog ${APACHE_LOG_DIR}/${domain}_access.log combined

</VirtualHost>
EOF

#mengaktifka modul
sudo a2enmod rewrite

#mengaktifkan file konfigurasi
sudo ln -s /etc/apache2/sites-available/${domain}.conf /etc/apache2/sites-enabled/

#disable site
a2dissite 000-default.conf

#enable site
a2ensite ${domain}.conf

#restart apache2
systemctl restart apache2
