OSver=$(cat /etc/redhat-release | sed -r 's/[a-zA-Z ]+([0-9.]+).*/\1/' | cut -d. -f1)                                                                                          
installRemiRepo(){
OSver="$1"
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-"${OSver}".rpm
rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-"${OSver}".noarch.rpm
yum -y install redis --enablerepo=remi --disableplugin=priorities

if { ${OSver} -eq 6 }
then
	chkconfig redis on
	service redis start
elif { ${OSver} -eq 7 }
	systemctl enable redis
	systemctl start redis
fi
}

addPortsToCSF(){
egrep '^TCP_IN' /etc/csf/csf.conf | grep 6379 || sed -i -r '/^TCP_IN/s/.$/,6379"/' /etc/csf/csf.conf

echo 'tcp|in|d=6379|s=*' >> /etc/csf/csf.deny
echo 'tcp|in|d=6379|s=127.0.0.1' >> /etc/csf/csf.allow

csf -r 
}

compileRedisCP(){
        phpver="$1"
        cd ~;
        wget -O redis.tgz https://pecl.php.net/get/redis;
        tar -xvf redis.tgz;
        cd ~/redis* || exit;
        /opt/cpanel/ea-php"$phpver"/root/usr/bin/phpize;
        ./configure --with-php-config=/opt/cpanel/ea-php"$phpver"/root/usr/bin/php-config;
        make clean && make install;
        echo 'extension=redis.so' > /opt/cpanel/ea-php"$phpver"/root/etc/php.d/redis.ini;
        rm -rf ~/redis*;
}


compileRedisCL(){
	phpver="$1"
        cd ~;
        wget -O redis.tgz https://pecl.php.net/get/redis;
        tar -xvf redis.tgz;
        cd ~/redis* || exit;
        /opt/alt/php"$phpver"/usr/bin/phpize;
        ./configure --with-php-config=/opt/alt/php"$phpver"/usr/bin/php-config;
        make clean && make install;
        echo 'extension=redis.so' > /opt/alt/php"$phpver"/etc/php.d/redis.ini;
        rm -rf ~/redis*;
}


doRun(){
installRemiRepo "${OSver}"
addPortsToCSF
for phpver in $(ls -1 /opt/alt/ |egrep 'php[0-9]{2}' | sed -r 's@php([0-9]{2})/@\1@g') ; 
do 
	compileRedisCP ${phpver}
	compileRedisCL ${phpver}
	
done

/scripts/restartsrv_httpd
/scripts/restartsrv_apache_php_fpm
}

doRun
