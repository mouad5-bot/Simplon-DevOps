#!/bin/bash
# provision-db-centos.sh - Database Server Setup Script (Simplified)

echo "=== Starting Database Server Provisioning ==="

# Update system
dnf update -y

# Install MySQL Server
dnf install -y mysql-server

# Start and enable MySQL
systemctl start mysqld
systemctl enable mysqld

# Configure firewall to allow MySQL port
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload

# Create database and user (MySQL installed without root password by default)
mysql -u root << 'EOF'
-- Create database
CREATE DATABASE IF NOT EXISTS demo_db;

-- Create user for remote access
CREATE USER IF NOT EXISTS 'demo_user'@'%' IDENTIFIED BY 'DemoPassword123!';
GRANT ALL PRIVILEGES ON demo_db.* TO 'demo_user'@'%';

-- Allow root access from localhost without password (keep simple)
FLUSH PRIVILEGES;
EOF

# Configure MySQL to accept remote connections
cat >> /etc/my.cnf.d/mysql-server.cnf << 'EOF'

[mysqld]
bind-address = 0.0.0.0
port = 3306
EOF

# Restart MySQL to apply configuration
systemctl restart mysqld

# Install additional useful tools
dnf install -y htop tree

# Create a non-root user with sudo privileges for security
useradd -m vagrant-admin
usermod -aG wheel vagrant-admin
echo "vagrant-admin:AdminPass123!" | chpasswd

echo "=== Database Server Setup Complete ==="
echo "Database accessible at: 192.168.56.20:3306"
echo "From host machine: localhost:3307"
echo "Database: demo_db"
echo "User: demo_user"
echo "Password: DemoPassword123!"
echo "Root access: mysql -u root (no password)"
echo ""
echo "To connect from host machine:"
echo "mysql -h localhost -P 3307 -u demo_user -p demo_db"