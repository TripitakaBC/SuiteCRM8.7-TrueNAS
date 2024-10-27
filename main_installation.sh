#!/bin/sh

# Define variables
SUITECRM_VERSION="8.7.0"
MYSQL_USERNAME="suitecrm"
MYSQL_PASSWORD="your_password"
MYSQL_DATABASE="suitecrm"
SERVER_NAME="server.example.com" # Can also use IP address
SERVER_URL="http://server.example.com"

# Redirect all output to tee
exec > >(tee /tmp/installation.log) 2>&1

# Function to check the last command's exit status
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

echo "Starting SuiteCRM installation..."

# Update and upgrade the system
echo "Updating and upgrading the system..."
pkg update && pkg upgrade -y
check_exit_status "System update"

# Install required packages
echo "Installing required packages..."
pkg install -y apache24 mariadb105-server unzip php82 php82-extensions git php82-curl php82-intl php82-gd php82-mbstring php82-mysqli php82-pdo_mysql php82-soap php82-xml php82-zip php82-tokenizer php82-session php82-imap php82-ldap php82-ctype php82-dom mod_php82 php82-zlib
check_exit_status "Package installation"

# Download and extract SuiteCRM
echo "Downloading and extracting SuiteCRM ${SUITECRM_VERSION}..."
cd /tmp
wget "https://github.com/salesagility/SuiteCRM-Core/releases/download/v${SUITECRM_VERSION}/SuiteCRM-${SUITECRM_VERSION}.zip"
check_exit_status "SuiteCRM download"
if [ ! -f "SuiteCRM-${SUITECRM_VERSION}.zip" ]; then
    echo "Error: SuiteCRM zip file not found"
    exit 1
fi

echo "Extracting SuiteCRM..."
if unzip "SuiteCRM-${SUITECRM_VERSION}.zip" -d /usr/local/www/apache24/data/; then
    echo "SuiteCRM extracted successfully"
else
    echo "Error: Failed to extract SuiteCRM"
    exit 1
fi
rm "/tmp/SuiteCRM-${SUITECRM_VERSION}.zip"
check_exit_status "SuiteCRM extraction"

# Change permissions on /tmp
chmod 1777 /tmp

# Enable and start MariaDB
echo "Enabling and starting MariaDB..."
sysrc mysql_enable="YES"
service mysql-server start
check_exit_status "MariaDB startup"

# Set root password and secure MariaDB installation
echo "Setting root password and securing MariaDB installation..."
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 12)
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
check_exit_status "MariaDB secure installation"

echo "MySQL root password has been set to: ${MYSQL_ROOT_PASSWORD}"
echo "Please save this password securely."

# Secure MariaDB installation
echo "Securing MariaDB installation..."
mysql_secure_installation
check_exit_status "MariaDB secure installation"

# Create database and user for SuiteCRM
echo "Creating database and user for SuiteCRM..."
mysql -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE DATABASE ${MYSQL_DATABASE};
CREATE USER '${MYSQL_USERNAME}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER '${MYSQL_USERNAME}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USERNAME}'@'localhost';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USERNAME}'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF
check_exit_status "Database creation"

# Enable and start Apache
echo "Enabling and starting Apache..."
sysrc apache24_enable="YES"
service apache24 start
check_exit_status "Apache startup"

# Configure PHP (/usr/local/etc/php.ini)
echo "Configuring PHP..."
cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
sed -i '' 's/;date.timezone =/date.timezone = America\/Creston/' /usr/local/etc/php.ini
sed -i '' 's/memory_limit = 128M/memory_limit = 256M/' /usr/local/etc/php.ini
sed -i '' 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /usr/local/etc/php.ini
sed -i '' 's/post_max_size = 8M/post_max_size = 64M/' /usr/local/etc/php.ini
sed -i '' 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT \& ~E_NOTICE \& ~E_WARNING/' /usr/local/etc/php.ini
sed -i '' 's/display_errors = Off/display_errors = On/' /usr/local/etc/php.ini
sed -i '' 's|^;mysqli.default_socket =.*|mysqli.default_socket = /var/run/mysql/mysql.sock|' /usr/local/etc/php.ini
sed -i '' 's|^mysqli.default_socket =.*|mysqli.default_socket = /var/run/mysql/mysql.sock|' /usr/local/etc/php.ini
check_exit_status "PHP configuration"

# Configure Apache (/usr/local/etc/apache24/httpd.conf)
echo "Configuring Apache..."
sed -i '' 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' /usr/local/etc/apache24/httpd.conf
sed -i '' 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /usr/local/etc/apache24/httpd.conf
sed -i '' 's|DocumentRoot "/usr/local/www/apache24/data"|DocumentRoot "/usr/local/www/apache24/data/public"|' /usr/local/etc/apache24/httpd.conf
sed -i '' 's|<Directory "/usr/local/www/apache24/data">|<Directory "/usr/local/www/apache24/data/public">|' /usr/local/etc/apache24/httpd.conf
sed -i '' 's/AllowOverride None/AllowOverride All/' /usr/local/etc/apache24/httpd.conf
sed -i '' "s/^#ServerName www.example.com:80/ServerName ${SERVER_NAME}:80/" /usr/local/etc/apache24/httpd.conf
# Load PHP module if not already present
if ! grep -q 'LoadModule php_module' /usr/local/etc/apache24/httpd.conf; then
    echo 'LoadModule php_module libexec/apache24/libphp.so' >> /usr/local/etc/apache24/httpd.conf
fi

# Add PHP handler configuration if not already present
if ! grep -q '<FilesMatch "\.php$">' /usr/local/etc/apache24/httpd.conf; then
    cat << EOF >> /usr/local/etc/apache24/httpd.conf

<FilesMatch "\.php$">
    SetHandler application/x-httpd-php
</FilesMatch>
EOF
fi
check_exit_status "Apache configuration"

# Add VirtualHost configuration
echo "Adding VirtualHost configuration..."
cat << EOF >> /usr/local/etc/apache24/httpd.conf

<VirtualHost *:80>
    ServerName ${SERVER_NAME}
    DocumentRoot /usr/local/www/apache24/data/public
    <Directory /usr/local/www/apache24/data/public>
        AllowOverride All
        Order Allow,Deny
        Allow from All
    </Directory>
</VirtualHost>
EOF
check_exit_status "VirtualHost configuration"

# Configure the .env file
echo "Configuring .env file..."
sed -i '' "s|DATABASE_URL=\"\"|DATABASE_URL=\"mysql://${MYSQL_USERNAME}:${MYSQL_PASSWORD}@127.0.0.1:3306/${MYSQL_DATABASE}\"|" /usr/local/www/apache24/data/.env
check_exit_status ".env configuration"

# Update .env.local file
echo "Updating .env.local file..."
cat << EOF > /usr/local/www/apache24/data/.env.local
DATABASE_URL="mysql://${MYSQL_USERNAME}:${MYSQL_PASSWORD}@127.0.0.1:3306/${MYSQL_DATABASE}"
APP_SECRET=$(openssl rand -hex 16)
EOF
check_exit_status ".env.local configuration"

# Set correct permissions
echo "Setting correct permissions..."
chown -R www:www /usr/local/www/apache24/data
chmod -R 755 /usr/local/www/apache24/data
check_exit_status "Permission setting"

# Set directory permissions to 2755
echo "Setting directory permissions..."
cd /usr/local/www/apache24/data
find . -type d -not -perm 2755 -exec chmod 2755 {} \;
# Set file permissions to 0644
find . -type f -not -perm 0644 -exec chmod 0644 {} \;
# Set ownership to www:www for all files and directories
find . ! -user www -exec chown www:www {} \;
# Make the console script executable
chmod +x bin/console
check_exit_status "Final permission setting"

# Clear PHP cache
echo "Clearing cache..."
php bin/console cache:clear
check_exit_status "Cache clearing"

# Restart Apache
echo "Restarting Apache..."
service apache24 restart
check_exit_status "Apache restart"
echo "Verifying DocumentRoot..."
grep DocumentRoot /usr/local/etc/apache24/httpd.conf

echo "Installation complete. Please navigate to ${SERVER_URL} to complete the SuiteCRM setup."
