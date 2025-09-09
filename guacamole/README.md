# Apache Guacamole Docker Compose Setup for Debian 13

A comprehensive Docker Compose setup for Apache Guacamole with bind mounts, environment variables, secrets management, and optional Nginx reverse proxy.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)

## Features

- 🐳 **Docker Compose** setup with proper service orchestration
- 📁 **Bind Mounts** for persistent data and easy configuration
- 🔐 **Secrets Management** using Docker secrets
- 🌐 **Nginx Reverse Proxy** with SSL/TLS support (optional)
- 🏥 **Health Checks** for all services
- 📊 **Logging** with proper log rotation
- 🔒 **Security Hardening** with non-root containers and proper permissions
- 🔄 **Easy Backup/Restore** with bind mounts
- 📈 **Production Ready** configuration

## Prerequisites

### System Requirements

- **Debian 13** (or compatible Linux distribution)
- **Docker Engine** 20.10.0 or later
- **Docker Compose** 2.0.0 or later
- **Minimum 2GB RAM** (4GB recommended)
- **Minimum 10GB disk space**

### Install Docker on Debian 13

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Log out and back in for group changes to take effect
```

## Quick Start

### 1. Clone and Setup

```bash
# Navigate to your home directory
cd ~

# Clone the repository (if not already cloned)
git clone https://github.com/RedFoxAU/apache-guac.git
cd apache-guac/guacamole

# Copy environment file and customize
cp env.example .env
nano .env  # Edit WORKING_DIR and other settings
```

### 2. Configure Environment

Edit the `.env` file and replace `$USER` with your actual username:

```bash
# Example: if your username is 'john'
WORKING_DIR=/home/john/docker
```

### 3. Create Directory Structure

```bash
# Run the setup script to create all necessary directories
./setup-directories.sh
```

### 4. Create Secrets

```bash
# Create a strong password for PostgreSQL (replace with your own strong password)
echo "MyStr0ngP@ssw0rd!2024" > ~/docker/guacamole/secrets/postgres_password.txt

# Set proper permissions
chmod 600 ~/docker/guacamole/secrets/postgres_password.txt
```

### 5. Initialize Database

```bash
# Download and prepare database initialization files
./init-database.sh
```

### 6. Start Services

```bash
# Start all services (without nginx)
docker compose up -d

# OR start with nginx reverse proxy
docker compose --profile nginx up -d
```

### 7. Access Guacamole

- **Direct Access**: http://localhost:8080/guacamole
- **With Nginx**: http://localhost (redirects to HTTPS if configured)

**Default Login**: `guacadmin` / `guacadmin`

> ⚠️ **Important**: Change the default password immediately after first login!

## Detailed Setup

### Directory Structure

After running `setup-directories.sh`, your directory structure will look like:

```
~/docker/guacamole/
├── postgres/
│   ├── data/           # PostgreSQL data directory
│   ├── initdb/         # Database initialization SQL files
│   └── config/         # PostgreSQL configuration files
├── guacd/
│   ├── config/         # Guacd configuration
│   ├── logs/           # Guacd logs
│   ├── drive/          # File transfer storage
│   └── recordings/     # Session recordings
├── webapp/
│   ├── config/         # Guacamole configuration
│   ├── extensions/     # Guacamole extensions (.jar files)
│   ├── lib/            # Additional libraries
│   └── logs/           # Web application logs
├── nginx/              # Nginx reverse proxy (optional)
│   ├── conf.d/         # Nginx configuration files
│   ├── ssl/            # SSL certificates
│   ├── logs/           # Nginx logs
│   └── html/           # Static web content
├── secrets/            # Secret files (600 permissions)
│   └── postgres_password.txt
└── shared/             # Shared file storage
```

### Environment Configuration

#### Required Variables

- `WORKING_DIR`: Base directory for bind mounts (e.g., `/home/username/docker`)
- `POSTGRES_DB`: PostgreSQL database name
- `POSTGRES_USER`: PostgreSQL username

#### Optional Variables

- `GUACAMOLE_PORT`: Web interface port (default: 8080)
- `GUACD_LOG_LEVEL`: Log level (trace, debug, info, warn, error)
- `TZ`: Timezone (default: UTC)
- `NGINX_HTTP_PORT`: Nginx HTTP port (default: 80)
- `NGINX_HTTPS_PORT`: Nginx HTTPS port (default: 443)

### SSL/TLS Configuration (Nginx)

1. **Generate Self-Signed Certificate** (for testing):

```bash
cd ~/docker/guacamole/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem \
  -subj "/CN=guacamole.local"
```

2. **Use Let's Encrypt** (for production):

```bash
# Install certbot
sudo apt install -y certbot

# Generate certificate (replace with your domain)
sudo certbot certonly --standalone -d your-domain.com

# Copy certificates
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/docker/guacamole/nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/docker/guacamole/nginx/ssl/key.pem
sudo chown $USER:$USER ~/docker/guacamole/nginx/ssl/*.pem
```

3. **Copy Nginx Configuration**:

```bash
cp nginx-example.conf ~/docker/guacamole/nginx/conf.d/guacamole.conf
```

## Configuration

### Database Configuration

The PostgreSQL database is automatically configured with:
- **Data Persistence**: `~/docker/guacamole/postgres/data`
- **Initialization Scripts**: `~/docker/guacamole/postgres/initdb`
- **Health Checks**: Automatic container health monitoring

### Guacamole Extensions

Place extension `.jar` files in `~/docker/guacamole/webapp/extensions/`:

**Popular Extensions**:
- LDAP Authentication
- TOTP (Two-Factor Authentication)
- Quick Connect
- History Recording Storage

Example downloading TOTP extension:

```bash
cd ~/docker/guacamole/webapp/extensions
curl -L -o guacamole-auth-totp-1.5.4.jar \
  "https://archive.apache.org/dist/guacamole/1.5.4/binary/guacamole-auth-totp-1.5.4.jar"
```

### Custom Configuration

Create `~/docker/guacamole/webapp/config/guacamole.properties`:

```properties
# Basic database configuration is handled by environment variables
# Add custom properties here

# Enable LDAP (if using LDAP extension)
ldap-hostname: ldap.example.com
ldap-port: 389
ldap-user-base-dn: ou=users,dc=example,dc=com

# Enable TOTP (if using TOTP extension)
totp-issuer: Apache Guacamole
totp-digits: 6
totp-period: 30

# Recording storage
recording-search-path: /recordings
```

## Security

### Best Practices

1. **Change Default Passwords**:
   ```bash
   # Use strong, unique passwords in secrets files
   openssl rand -base64 32 > ~/docker/guacamole/secrets/postgres_password.txt
   ```

2. **Secure File Permissions**:
   ```bash
   # Secrets should only be readable by owner
   chmod 600 ~/docker/guacamole/secrets/*.txt
   
   # Configuration directories
   chmod 700 ~/docker/guacamole/secrets/
   ```

3. **Firewall Configuration**:
   ```bash
   # Example with ufw
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP (redirects to HTTPS)
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw --force enable
   ```

4. **Regular Updates**:
   ```bash
   # Update container images regularly
   docker compose pull
   docker compose up -d
   ```

### Network Security

- PostgreSQL is only accessible from localhost (127.0.0.1:5432)
- Services communicate through internal Docker network
- Nginx provides additional security headers and rate limiting

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

```bash
# Fix ownership of Docker directories
sudo chown -R $USER:$USER ~/docker/guacamole/

# Fix permissions
chmod 755 ~/docker/guacamole/
chmod 600 ~/docker/guacamole/secrets/*.txt
```

#### 2. Database Connection Issues

```bash
# Check if PostgreSQL is healthy
docker compose ps
docker compose logs postgres

# Verify password file exists and has correct permissions
ls -la ~/docker/guacamole/secrets/postgres_password.txt
```

#### 3. Guacamole Won't Start

```bash
# Check logs
docker compose logs guacamole

# Common issues:
# - Database not ready (wait for health check)
# - Missing initialization files (run init-database.sh)
# - Permission issues on bind mounts
```

#### 4. Nginx SSL Issues

```bash
# Check certificate files exist
ls -la ~/docker/guacamole/nginx/ssl/

# Test nginx configuration
docker compose exec nginx nginx -t

# Check nginx logs
docker compose logs nginx
```

### Useful Commands

```bash
# View service status
docker compose ps

# View logs for specific service
docker compose logs -f guacamole

# Restart specific service
docker compose restart guacamole

# View resource usage
docker compose top

# Access container shell
docker compose exec guacamole bash
```

## Maintenance

### Backup

```bash
#!/bin/bash
# Backup script example
BACKUP_DIR="/backup/guacamole/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Stop services
docker compose stop

# Backup data directories
cp -r ~/docker/guacamole/postgres/data "$BACKUP_DIR/"
cp -r ~/docker/guacamole/webapp/config "$BACKUP_DIR/"
cp -r ~/docker/guacamole/secrets "$BACKUP_DIR/"

# Backup database (alternative method)
docker compose start postgres
sleep 10
docker compose exec -T postgres pg_dump -U guacamole_user guacamole_db > "$BACKUP_DIR/database.sql"

# Restart services
docker compose start
```

### Updates

```bash
# Update to latest images
docker compose pull
docker compose down
docker compose up -d

# Check for Guacamole updates
./init-database.sh  # Updates SQL schema if needed
```

### Log Rotation

Add to `/etc/logrotate.d/guacamole`:

```
/home/*/docker/guacamole/*/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

### Monitoring

```bash
# Health check script
#!/bin/bash
services=("postgres" "guacd" "guacamole")

for service in "${services[@]}"; do
    health=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep $service | awk '{print $2}')
    if [[ $health == *"healthy"* ]]; then
        echo "✅ $service: healthy"
    else
        echo "❌ $service: $health"
    fi
done
```

## Support

For issues and questions:

1. Check the [Apache Guacamole Documentation](https://guacamole.apache.org/doc/gug/)
2. Review the troubleshooting section above
3. Check container logs: `docker compose logs [service_name]`
4. Open an issue in this repository

---

**Security Note**: This setup includes security best practices, but always review and adjust according to your specific security requirements and organizational policies.
