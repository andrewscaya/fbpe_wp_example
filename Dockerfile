FROM asclinux/linuxforphp-8.2-ultimate:7.3-nts

MAINTAINER Caya Technologies Inc. <services@etista.com>

# !!! IMPORTANT !!!
# Please CUSTOMIZE the environment variables by setting:
# * the deployment environment,
# * the Git tag version to deploy,
# * the email address of the user,
# * the username:access-key for GitHub,
# * the feature branch's name (if applicable),
# * and the URI of the server (dev and prod).
ENV PROJECT_ENV="dev"
ENV PROJECT_VERSION="1.0.0"
ENV PROJECT_GITHUB_EMAIL="andrewscaya@yahoo.ca"
ENV PROJECT_GITHUB_USER="andrewscaya"
ENV PROJECT_GITHUB_PASSWORD="CHANGEME-ACCESS-TOKEN"
ENV PROJECT_GITHUB_BRANCH_NAME="1.0.1-dev"
ENV PROJECT_DEV_HOSTNAME="192.168.1.6:8181"
ENV PROJECT_PROD_HOSTNAME="andrewcayaetistacom17.linuxforphp.com"

# Set up PHP-FPM socket
RUN sed -i 's/listen = 127.0.0.1:9000/; listen = 127.0.0.1:9000\nlisten = \/run\/php-fpm.sock/' /etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.owner = apache/listen.owner = apache/' /etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.group = apache/listen.group = apache/' /etc/php-fpm.d/www.conf
RUN sed -i -e '/proxy_module/s/^#//' -e '/proxy_fcgi_module/s/^#//' /etc/httpd/httpd.conf
RUN sed -i 's/<Proxy "fcgi:\/\/127.0.0.1:9000">/<Proxy "unix:\/run\/php-fpm.sock|fcgi:\/\/localhost\/">/' /etc/httpd/httpd.conf
RUN sed -i 's/SetHandler "proxy:fcgi:\/\/127.0.0.1:9000"/# SetHandler "proxy:fcgi:\/\/127.0.0.1:9000"/' /etc/httpd/httpd.conf
RUN sed -i 's/# SetHandler "proxy:unix:\/run\/php-fpm.sock|fcgi:\/\/localhost\/"/SetHandler "proxy:unix:\/run\/php-fpm.sock|fcgi:\/\/localhost\/"/' /etc/httpd/httpd.conf

# Configure PHP
RUN sed -i 's/.*xdebug.so/;&/' /etc/php.ini
RUN sed -i 's/extension=memcached.so/;extension=memcached.so/' /etc/php.ini
RUN sed -i 's/extension=amqp.so/;extension=amqp.so/' /etc/php.ini
RUN sed -i 's/extension=redis.so/;extension=redis.so/' /etc/php.ini
#RUN lfphp-get imagemagick
#RUN lfphp-get --force php-ext imagick
#RUN if [[ $( grep -Fxq "extension=imagick.so" /etc/php.ini && echo $? ) != 0 ]]; then echo -e "\nextension=imagick.so\n" >> /etc/php.ini; fi
RUN composer self-update

# Set up Web server and Web root - Depends on the environment
RUN sed -i 's/#LoadModule remoteip_module/LoadModule remoteip_module/' /etc/httpd/httpd.conf
RUN sed -i 's/%h/%a/g' /etc/httpd/httpd.conf
RUN echo 'RemoteIPHeader X-Real-IP' >> /etc/httpd/httpd.conf

# Add WordPress development save script - Depends on the environment
RUN echo -e '#!/usr/bin/env bash\n\
export DEVID=$( head /dev/urandom | tr -dc A-Za-z0-9 | head -c26 )\n\
export DEVBRANCH="$( cat /root/branch )"\n\
i=1\n\
for file in `ls /tmp/mysql-binlog.* | sort -V`; do\n\
    if [[ "$file" =~ "index" ]]; then\n\
        echo -e "\nIgnoring $file"\n\
    else\n\
        mysqlbinlog -D -d cms "$file" > /srv/tempo/data/migrations/migration_"$DEVID"_"$i"_"$( date "+%Y%m%d%H%M%S" )".sql\n\
        ((i=i+1))\n\
    fi\n\
done\n\
echo -e "\nMaking the exported environment sane..."\n\
find /srv/tempo/data/migrations -type f -exec sed -i "s/$PROJECT_DEV_HOSTNAME/$PROJECT_PROD_HOSTNAME/g" "{}" \;\n\
cd /srv/tempo\n\
git add -A\n\
git stash\n\
git checkout -b "$DEVBRANCH"\n\
git stash pop\n\
git add -A\n\
git commit -m "$( date "+%Y-%m-%d_%H%M" ): Creates $DEVBRANCH."\n\
git push --tags origin "$DEVBRANCH"\n\
exit' > /usr/bin/save.bash
RUN chmod +x /usr/bin/save.bash

# Add the entry point script
RUN echo -e '#!/usr/bin/env bash\n\
sed --follow-symlinks -i "s/max_allowed_packet = 1M/max_allowed_packet = 64M/" /etc/mysql/my.cnf\n\
sed --follow-symlinks -i "s/max_execution_time = 30/max_execution_time = 600/" /etc/php.ini\n\
sed --follow-symlinks -i "s/max_input_time = 60/max_input_time = 600/" /etc/php.ini\n\
sed --follow-symlinks -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini\n\
echo -e "\nCloning the code repository..."\n\
if [[ ! -d /srv/tempo/wordpress ]]; then\n\
  export DBINITFLAG="yes"\n\
  cd /srv\n\
  #git clone -b "$PROJECT_VERSION" https://"$PROJECT_GITHUB_USER:$PROJECT_GITHUB_PASSWORD"@github.com/andrewscaya/fbpe_wp_example tempo\n\
  git clone https://github.com/andrewscaya/fbpe_wp_example tempo1\n\
  if [[ -d /srv/tempo ]]; then\n\
    cp -rTf tempo1 tempo\n\
    rm -rf tempo1\n\
  else\n\
    mv tempo1 tempo\n\
  fi\n\
fi\n\
cd /srv/tempo\n\
git fetch --all\n\
git checkout -b "$PROJECT_VERSION"\n\
echo -e "\nFetching code repository objects..."\n\
git fetch --all\n\
/etc/init.d/mysql start\n\
sleep 5\n\
if [[ "$PROJECT_ENV" =~ "prod" ]]; then\n\
  if [[ "$DBINITFLAG" =~ "yes" ]]; then\n\
    export DBINITFLAG="no"\n\
    sed -i "1s/<?php/\<?php\\n\\ndefine(\"FORCE_SSL_ADMIN\", true);\\n\\nif (isset(\$_SERVER[\"HTTP_X_FORWARDED_PROTO\"]) \&\& \$_SERVER[\"HTTP_X_FORWARDED_PROTO\"] === \"https\") {\\n\t\$_SERVER[\"HTTPS\"] = \"on\";\\n}\\n/" /srv/tempo/wordpress/wp-config.php\n\
    sed -i "s/\r//g" /srv/tempo/wordpress/wp-config.php\n\
    sed -i "1s/<?php/\<?php\\n\\ndefine(\"FORCE_SSL_ADMIN\", true);\\n\\nif (\$_SERVER[\"HTTP_X_FORWARDED_PROTO\"] === \"https\") {\\n\t\$_SERVER[\"HTTPS\"] = \"on\";\\n}\\n/" /srv/tempo/wordpress/wp-admin/setup-config.php\n\
    #sed -i "1s/<?php/\<?php\\n\\ndefine("FORCE_SSL_ADMIN", true);\\n\\nif (\$_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {\\n\t\$_SERVER["HTTPS"] = "on";\\n}\\n/" /srv/tempo/wordpress/wp-admin/install.php\n\
    mysql -uroot -p$( cat /srv/backendpass ) -e "CREATE DATABASE cms;"\n\
    mysql -uroot -p$( cat /srv/backendpass ) -e "CREATE USER \"cmsuser\"@\"localhost\" IDENTIFIED BY \"testpass\";"\n\
    mysql -uroot -p$( cat /srv/backendpass ) -e "GRANT ALL PRIVILEGES ON cms.* TO \"cmsuser\"@\"localhost\";"\n\
    echo -e "\nLoading the database..."\n\
    mysql -uroot -p$( cat /srv/backendpass ) cms < /srv/tempo/data/wp_schema_data.sql\n\
  fi\n\
  if [[ $( ls -1 /srv/tempo/data/migrations/*.sql 2>/dev/null | wc -l ) != 0 ]]; then\n\
    echo -e "\nLoading the database migrations..."\n\
    for file in `ls /srv/tempo/data/migrations/*.sql | sort -V`; do\n\
      mysql -uroot -p$( cat /srv/backendpass ) cms < "$file"\n\
    done\n\
  fi\n\
fi\n\
if [[ "$PROJECT_ENV" =~ "dev" ]]; then\n\
  mysql -uroot -e "CREATE DATABASE cms;"\n\
  mysql -uroot -e "CREATE USER \"cmsuser\"@\"localhost\" IDENTIFIED BY \"testpass\";"\n\
  mysql -uroot -e "GRANT ALL PRIVILEGES ON cms.* TO \"cmsuser\"@\"localhost\";"\n\
  echo -e "\nLoading the database..."\n\
  mysql -uroot cms < /srv/tempo/data/wp_schema_data.sql\n\
  echo -e "\nMaking the environment sane..."\n\
  mysqldump --add-drop-database cms > /srv/tempo/data/tempo.sql\n\
  sed -i "s/$PROJECT_PROD_HOSTNAME/$PROJECT_DEV_HOSTNAME/g" /srv/tempo/data/tempo.sql\n\
  mysql -uroot cms < /srv/tempo/data/tempo.sql\n\
  rm /srv/tempo/data/tempo.sql\n\
  /etc/init.d/mysql stop\n\
  sleep 5\n\
  mysqld_safe --log-bin=/tmp/mysql-binlog --user=mysql 2>&1 >/dev/null &\n\
  sleep 5\n\
fi\n\
echo "$PROJECT_GITHUB_BRANCH_NAME" > /root/branch\n\
git config --global user.email "$PROJECT_GITHUB_EMAIL"\n\
git config --global user.name "$PROJECT_GITHUB_USER"\n\
git config --global user.password "$PROJECT_GITHUB_PASSWORD"\n\
cd /srv\n\
if [[ -L www ]]; then rm -f www; else mv www www.OLD; fi\n\
ln -s tempo/wordpress www\n\
chown -R apache:apache /srv/www\n\
/bin/lfphp --mysql --phpfpm --apache' > /entrypoint.bash

RUN chmod +x /entrypoint.bash

CMD ["/entrypoint.bash"]