#!/bin/tcsh

# 3) Enable SSH
/usr/bin/sed -i '' 's/sshd_enable="NO"/sshd_enable="YES"/g' /etc/rc.conf
# Generate root keys &  Enable root login (with SSH keys). 
# [Optional, to continue install straight from SSH to the jail]
/usr/bin/ssh-keygen -b 4096 -N '' -f ~/.ssh/id_rsa -t rsa -q
echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
# Start SSH
/usr/sbin/service sshd start

# 4) Update packages and upgrade any.
/usr/sbin/pkg update -f
/usr/sbin/pkg upgrade -y

# Commented out because everything is from pkg. Comment out if you want to compile nginx with gzip support.
#/usr/sbin/portsnap fetch
#/usr/sbin/portsnap extract

# 5) Create user first installing git will install a git user to 1001 (First FreeNAS user.)
# Add git user.
pw add user -n git -u 913 -m -s /usr/local/bin/bash -c "GitLab"

# 6) Install Dependencies
/usr/sbin/pkg install -y cmake gmake bash git redis icu libxml2 libxslt python2 nginx rubygem-bundler rubygem-rake libressl libssh2 libgit2 krb5 mysql56-server rubygem-rack-ssl pkgconf
# Update 
/usr/local/bin/gem update --system

# 7) Enable both servers
echo 'redis_enable="YES"' >> /etc/rc.conf
echo 'mysql_enable="YES"' >> /etc/rc.conf
echo 'nginx_enable="YES"' >> /etc/rc.conf
# Start up both servers.
/usr/sbin/service redis start
/usr/sbin/service mysql-server start


# 8) Secure mysql install. [Default root password is empty.] 
# Create git mysql user and database for gitlab.
/usr/local/bin/mysql_secure_installation
# Add the mysql git user.
/usr/local/bin/mysql -u root -p < gitlab_2.sql

# Steps 10-17, run as user git.
su - git -c "/tmp/gitlab_git.sh"

# 18) NGINX setup.
/bin/cp /usr/home/git/gitlab/lib/support/nginx/gitlab /usr/local/etc/nginx/gitlab.conf
# Tell nginx where to find the gitlab stuff.
/usr/bin/sed -i ".bak" "s/proxy_pass http:\/\/gitlab;/proxy_pass http:\/\/127.0.0.1:8080;/g" /usr/local/etc/nginx/gitlab.conf
# Disable gzip static. If you compile nginx from ports you can enable gzip. pkg comes with it disabled by default.
/usr/bin/sed -i ".bak" "s/gzip_static on;/#gzip_static on;/g" /usr/local/etc/nginx/gitlab.conf
# nginx permissions
/bin/mkdir -p /var/tmp/nginx /var/log/nginx
/usr/sbin/chown -R www: /var/log/nginx /var/tmp/nginx

# 19) Copy the gitlab init
/bin/cp /usr/home/git/gitlab/lib/support/init.d/gitlab /usr/local/etc/rc.d/gitlab
