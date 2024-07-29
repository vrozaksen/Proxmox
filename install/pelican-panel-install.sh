#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# Co-author: vrozaksen
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y tar
$STD apt-get install -y unzip
$STD apt-get install -y git
$STD apt-get install -y gnupg
$STD apt-get install -y nginx
$STD apt-get install -y lsb-release
msg_ok "Installed Dependencies"

msg_info "Installing PHP"
$STD wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
$STD echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
$STD apt-get update
$STD apt-get install -y php8.3 php8.3-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,sqlite3,fpm}
msg_ok "Installed PHP"

msg_info "Installing Composer"
$STD curl -sS https://getcomposer.org/installer | $STD sudo php -- --install-dir=/usr/local/bin --filename=composer
msg_ok "Installed Composer"

msg_info "Downloading Panel"
mkdir -p /var/www/pelican
cd /var/www/pelican
$STD curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | $STD sudo tar -xzv
chmod -R 755 storage/* bootstrap/cache/
msg_ok "Downloaded Panel"

msg_info "Installing Panel"
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer install --no-dev --optimize-autoloader
msg_ok "Installed Panel"

msg_info "Setting up Crontab and Permissions"
echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1" >> /var/spool/cron/crontabs/root
chown -R www-data:www-data /var/www/pelican/* 
msg_ok "Setup Crontab and Permissions"

msg_info "Creating Webserver Configuration"
rm /etc/nginx/sites-enabled/default
cat <<EOF >/etc/nginx/sites-available/pelican.conf
server {
    listen 80;
    server_name _;

    root /var/www/pelican/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/panel.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
systemctl restart nginx
msg_ok "Created Webserver Configuration"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
