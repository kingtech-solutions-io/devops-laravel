#!/bin/bash

# PHP version to install (latest stable as of Sept 2026)
PHP_VERSION="8.5"

# Install Some PPAs
sudo apt-add-repository ppa:ondrej/php -y

# Update Package Lists
sudo apt-get update -y

# Install Generic PHP packages...TODO: Filter these out
sudo apt-get install -y --allow-change-held-packages \
php-imagick php-memcached php-redis php-xdebug php-dev imagemagick mcrypt

# PHP ${PHP_VERSION}
# Notes:
#  - opcache is built into PHP 8.5 (no separate php8.5-opcache package)
#  - imap and pspell moved to PECL in 8.4; interbase, sybase and xmlrpc may not
#    be built for every version. Packages not in the repo are skipped below
#    instead of failing the whole install.
EXTENSIONS=(
  bcmath bz2 cgi cli common curl dba dev enchant fpm gd gmp imap interbase intl ldap
  mbstring mysql odbc pgsql phpdbg pspell readline snmp soap sqlite3 sybase tidy
  xdebug xml xmlrpc xsl zip memcached redis
)

PACKAGES=("php${PHP_VERSION}")
for ext in "${EXTENSIONS[@]}"; do
  pkg="php${PHP_VERSION}-${ext}"
  if apt-cache show "$pkg" > /dev/null 2>&1; then
    PACKAGES+=("$pkg")
  else
    echo "Skipping $pkg (not available)"
  fi
done

sudo apt-get install -y --allow-change-held-packages "${PACKAGES[@]}"

# Backup files we are about to modify (only if they exist)
backup() {
  if [ -f "$1" ] && [ ! -f "$1.bak" ]; then
    sudo cp "$1" "$1.bak"
  fi
}
backup /etc/php/${PHP_VERSION}/cli/php.ini
backup /etc/php/${PHP_VERSION}/fpm/php.ini
backup /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
backup /etc/php/${PHP_VERSION}/mods-available/opcache.ini
backup /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Configure php.ini for CLI
#sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/${PHP_VERSION}/cli/php.ini
#sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/${PHP_VERSION}/cli/php.ini
#sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/${PHP_VERSION}/cli/php.ini
#sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/${PHP_VERSION}/cli/php.ini

# Configure Xdebug
#sudo bash -c "echo 'xdebug.mode = debug' >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini"
#sudo bash -c "echo 'xdebug.discover_client_host = true' >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini"
#sudo bash -c "echo 'xdebug.client_port = 9003' >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini"
#sudo bash -c "echo 'xdebug.max_nesting_level = 512' >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini"
# opcache has no mods-available/opcache.ini on 8.5 by default; set it in php.ini instead
#sudo sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" /etc/php/${PHP_VERSION}/fpm/php.ini

# Configure php.ini for FPM
#sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/${PHP_VERSION}/fpm/php.ini
#sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/${PHP_VERSION}/fpm/php.ini

# Append CA bundle settings once (skip if already present, so re-runs don't duplicate)
FPM_INI=/etc/php/${PHP_VERSION}/fpm/php.ini
if ! grep -q "^openssl.cainfo = /etc/ssl/certs/ca-certificates.crt" "$FPM_INI"; then
  printf "[openssl]\nopenssl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | sudo tee -a "$FPM_INI" > /dev/null
fi
if ! grep -q "^curl.cainfo = /etc/ssl/certs/ca-certificates.crt" "$FPM_INI"; then
  printf "[curl]\ncurl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | sudo tee -a "$FPM_INI" > /dev/null
fi

sudo systemctl restart php${PHP_VERSION}-fpm
