#!/bin/bash

#update dan upgrade
apt update && apt upgrade -y

#install Bins9 sebagai DNS server
apt install bind9 resolvconf dnsutils -y

#install php 8.3
apt install php8.3-cli php8.3-fpm php8.3-mysql php8.3-opcache php8.3-mbstring php8.3-xml php8.3-gd php8.3-curl -y

#install Database server
apt install mariadb-server mariadb-client -y

#install web server
apt install nginx -y

#copy file pada bind9
echo "nama domain kamu"
read domain
echo "ip anda"
read ip
echo "domain proxmox"
read domainpx
echo "ip proxmox"
read ippx

cp -R /etc/bind/db.local /etc/bind/${domain}
cp -R /etc/bind/db.127 /etc/bind/${domain}.reverse

#edit file
sed -n '13p' /etc/bind/${domain} >> /etc/bind/${domain}
sed -i "s/localhost/${domain}/g" /etc/bind/${domain}
sed -i "s/::1/${domain}./g" /etc/bind/${domain}
sed -i "14s/@/www.${domain}./g" /etc/bind/${domain}
sed -i "13s/127.0.0.1/${ip}/g" /etc/bind/${domain}
sed -i "s/AAAA/CNAME/g" /etc/bind/${domain}
sed -i "15s/@/${domainpx}/g" /etc/bind/${domain}
sed -i "15s/127.0.0.1/${ippx}/g" /etc/bind/${domain}

echo "Ip belakang anda"
read ip2

echo "Ip proxmox belakang anda"
read ip3

sed -n '13p' /etc/bind/${domain}.reverse >> /etc/bind/${domain}.reverse
sed -n '13p' /etc/bind/${domain}.reverse >> /etc/bind/${domain}.reverse
sed -i "s/localhost/${domain}/g" /etc/bind/${domain}.reverse
sed -i "14s/1.0.0/${ip2}/g" /etc/bind/${domain}.reverse
sed -i "15s/1.0.0/${ip3}/g" /etc/bind/${domain}.reverse
sed -i "14s/${domain}/www.${domain}/g" /etc/bind/${domain}.reverse
sed -i "15s/${domain}/${domainpx}/g" /etc/bind/${domain}.reverse

#edit file named.local
tee /etc/bind/named.conf.local << EOF > /dev/null
zone "${domain}" {
        type master;
        file "/etc/bind/${domain}";
};

// Reverse Zone
zone "10.10.10.in-addr.arpa" {
        type master;
        file "/etc/bind/${domain}.reverse";
};
zone "${domainpx}" {
        type master;
        file "/etc/bind/${domain}";
};
EOF

#restart named.service
systemctl restart named.service

#mengganti nameserver
sed -i "s/127.0.0.53/${ip}/g" /etc/resolv.conf
sed -i "s/search ./search ${domain}/" /etc/resolv.conf
