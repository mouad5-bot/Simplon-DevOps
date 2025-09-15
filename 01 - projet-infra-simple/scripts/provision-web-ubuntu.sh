#!/bin/bash
# provision-web-ubuntu.sh - Web Server Setup Script

echo "=== Starting Web Server Provisioning ==="

# Update system
apt-get update -y

# Install Nginx and Git
apt-get install -y nginx git curl

# Start and enable Nginx
systemctl start nginx
systemctl enable nginx

# Configure firewall to allow HTTP, HTTPS and SSH
ufw allow 'Nginx Full'
ufw allow ssh
echo "y" | ufw enable

# Create a non-root user with sudo privileges for security
useradd -m web-admin
usermod -aG sudo web-admin
echo "web-admin:WebAdminPass123!" | chpasswd

# Clone your GitHub repository
echo "=== Cloning GitHub Repository ==="
cd /tmp
git clone https://github.com/mouad5-bot/Sprint-2.git

# Copy website files to web directory
if [ -d "/tmp/Sprint-2" ]; then
    cp -r /tmp/Sprint-2/* /var/www/html/
    # Remove default nginx index.html if it exists
    rm -f /var/www/html/index.nginx-debian.html
else
    echo "Failed to clone repository"
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Create a simple nginx configuration
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# Test nginx configuration and restart
nginx -t
systemctl restart nginx

# Install additional tools that might be useful
apt-get install -y htop tree

echo "=== Web Server Setup Complete ==="
echo "Website accessible at: http://192.168.56.10"
echo "You can also access it via the public IP assigned by your network"