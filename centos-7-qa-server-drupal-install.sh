#!/bin/sh

#install extra repository for software
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

#install php7
yum -y install php70w-fpm php70w-opcache php70w-gd php70w-xml php70w-tidy php70w-soap php70w-snmp php70w-recode php70w-pspell php70w-process php70w-pecl-imagick php70w-pecl-xdebug php70w-pdo php70w-mysqlnd php70w-mcrypt php70w-mbstring php70w-ldap php70w-intl php70w-imap php70w-enchant php70w-bcmath

#install mod_ruid2 to run php under user name
yum -y install mod_ruid2

#install mysql (mariadb)
yum -y install mariadb-server mysql

#install **drush**
yum -y install php-drush-drush

#install other tools
yum -y install vim-common vim-enhanced unzip zip rar unrar vim-minimal sysstat rdate atop glances screen  ImageMagick  iotop bash-completion  jwhois wget lynx telnet expect mc zip unzip lynx patch git cvs

#create 1gb size swapfile
dd if=/dev/zero of=/swapfile1 bs=1024 count=1048576
chown root:root /swapfile1
chmod 0600 /swapfile1
mkswap /swapfile1

swapon /swapfile1

echo "\n/swapfile1 none swap sw 0 0\n" >> /etc/fstab

# tell server to enable and start mysql and apache after reboot
systemctl enable mariadb.service
systemctl enable httpd
systemctl start mariadb.service
systemctl start httpd

#create user test
useradd test

mkdir /home/test/conf.d
mkdir /home/test/domains
mkdir /home/test/logs

chown test:test /home/test/conf.d
chown test:test /home/test/domains
chown test:test /home/test/logs

cat > /home/test/conf.d/template  <<_EOF
<VirtualHost *:80>
    ServerName {\$DOMAIN}

    DocumentRoot /home/test/domains/{\$DOMAIN}
    CustomLog /home/test/logs/{\$DOMAIN}.log combined
    ErrorLog /home/test/logs/{\$DOMAIN}.error.log

    <IfModule mod_ruid2.c>
        RMode   config
        RUidGid test test
    </IfModule>

    <Directory /home/test/domains/{\$DOMAIN}>
      Options Indexes FollowSymLinks
      AllowOverride All
      Require all granted
    </Directory>
</VirtualHost>
_EOF

cat > /etc/httpd/conf.d/test.conf  <<_EOF
NameVirtualHost *:80
IncludeOptional /home/test/conf.d/*.conf
_EOF

cat > /etc/sudoers.d/test <<_EOF
Cmnd_Alias TEST_CMDS = /usr/sbin/apachectl
test    ALL=(ALL)      NOPASSWD:TEST_CMDS
_EOF
