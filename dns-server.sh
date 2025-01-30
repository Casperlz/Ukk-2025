#!/bin/bash

#install Bins9 sebagai DNS server
apt install bind9 resolvconf dnsutils -y

#copy file pada bind9
echo "nama domain kamu"
read domain
echo "ip anda"
read ip

cp -R /etc/bind/db.local /etc/bind/${domain}
cp -R /etc/bind/db.127 /etc/bind/${domain}.reverse

#edit file
sed -i "s/localhost/${domain}/g"; "s/::1/${domain}./g" /etc/bind/${domain}
sed -i "14s/@/www.${domain}./g" /etc/bind/${domain}
sed -i "s/127.0.0.1/${ip}/g" /etc/bind/${domain}

echo "Ip belakang anda"
read ip2

sed -n '13p' ${domain}.reverse >> /etc/bind/${domain}.reverse
sed -i "s/localhost/${domain}/g" /etc/bind/${domain}.reverse
sed -i "s/1.0.0/${ip2}/g" /etc/bind/${domain}.reverse

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
EOF

#restart named.service
systemctl restart named.service

#mengganti nameserver
sed -i "s/127.0.0.53/${ip}/g" /etc/resolv.conf
sed -i "s/./${domain}/g" /etc/resolv.conf
