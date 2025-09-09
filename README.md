# Apache Guacamole Docker Setup

🐳 **Production-ready Docker Compose setup for Apache Guacamole on Debian 13**

A comprehensive, secure, and easy-to-deploy Apache Guacamole setup with Docker Compose, featuring bind mounts, secrets management, and optional Nginx reverse proxy.

## Quick Links

- 📖 **[Complete Setup Guide](./guacamole/README.md)** - Detailed instructions and configuration
- 🚀 **[Quick Start](#quick-start)** - Get running in 5 minutes
- 🔧 **[Configuration Files](./guacamole/)** - All Docker Compose and configuration files

## Features

- ✅ **Docker Compose** orchestration with health checks
- ✅ **Bind Mounts** for easy data management and backups
- ✅ **Docker Secrets** for secure credential management
- ✅ **WORKING_DIR variable** configurable home directory (`/home/$USER/docker`)
- ✅ **Nginx Reverse Proxy** with SSL/TLS support (optional)
- ✅ **PostgreSQL 15** database with persistent storage
- ✅ **Production Security** hardening and best practices
- ✅ **Debian 13** optimized setup

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Nginx Proxy    │    │   Guacamole     │    │   PostgreSQL    │
│  (Optional)     │───▶│   WebApp        │───▶│   Database      │
│  Port 80/443    │    │   Port 8080     │    │   Port 5432     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │     Guacd       │
                       │    Daemon       │
                       │   Port 4822     │
                       └─────────────────┘
```

## Quick Start

### 1. Prerequisites (Debian 13)

```bash
# Install Docker and Docker Compose
sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl enable --now docker
# Log out and back in for group changes
```

### 2. Setup

```bash
# Clone repository
git clone https://github.com/RedFoxAU/apache-guac.git
cd apache-guac/guacamole

# Configure environment (edit WORKING_DIR)
cp env.example .env
nano .env  # Change WORKING_DIR=/home/$USER/docker to your actual username

# Create directories and secrets
./setup-directories.sh
echo "YourStrongPassword123!" > ~/docker/guacamole/secrets/postgres_password.txt
chmod 600 ~/docker/guacamole/secrets/postgres_password.txt

# Initialize database
./init-database.sh

# Start services
docker compose up -d
```

### 3. Access

- **Web Interface**: http://localhost:8080/
- **Default Login**: `guacadmin` / `guacadmin`

> ⚠️ **Change the default password immediately after first login!**

## Directory Structure

```
~/docker/guacamole/
├── postgres/           # PostgreSQL data and config
├── guacd/             # Guacamole daemon files
├── webapp/            # Web application config and logs
├── nginx/             # Reverse proxy config (optional)
├── secrets/           # Secure credential files
└── shared/            # Shared file storage
```

## Configuration

### Environment Variables (.env)

| Variable | Description | Default |
|----------|-------------|---------|
| `WORKING_DIR` | Base directory for Docker volumes | `/home/$USER/docker` |
| `POSTGRES_DB` | Database name | `guacamole_db` |
| `POSTGRES_USER` | Database user | `guacamole_user` |
| `GUACAMOLE_PORT` | Web interface port | `8080` |
| `TZ` | Timezone | `UTC` |

### Security Features

- 🔐 **Docker Secrets** for passwords
- 🛡️ **Network Isolation** with custom Docker network
- 🚫 **No hardcoded credentials** in configuration files
- 🔒 **Proper file permissions** (600 for secrets)
- 🌐 **Nginx security headers** and rate limiting

## Services Included

| Service | Image | Purpose | Health Check |
|---------|-------|---------|--------------|
| **postgres** | `postgres:15-alpine` | Database storage | ✅ pg_isready |
| **guacd** | `guacamole/guacd:latest` | Remote desktop daemon | ✅ Port check |
| **guacamole** | `guacamole/guacamole:latest` | Web application | ✅ HTTP check |
| **nginx** | `nginx:alpine` | Reverse proxy (optional) | Manual |

## Production Features

- 📊 **Health Checks** for all services
- 🔄 **Automatic Restarts** unless stopped
- 📝 **Centralized Logging** with bind mounts
- 💾 **Persistent Storage** for all data
- 🚀 **Easy Scaling** and maintenance
- 🔧 **Hot Configuration** reload support

## Optional Components

### Nginx Reverse Proxy

```bash
# Start with Nginx proxy
docker compose --profile nginx up -d

# Copy example configuration
cp nginx-example.conf ~/docker/guacamole/nginx/conf.d/guacamole.conf
```

### SSL/TLS Support

```bash
# Generate self-signed certificate (testing)
cd ~/docker/guacamole/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem

# Or use Let's Encrypt for production
sudo certbot certonly --standalone -d your-domain.com
```

## Management Commands

```bash
# View status
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Update images
docker compose pull && docker compose up -d

# Backup data
cp -r ~/docker/guacamole/postgres/data /backup/
```

## Support and Documentation

- 📚 **[Detailed Setup Guide](./guacamole/README.md)** - Complete instructions
- 🐛 **[Troubleshooting](./guacamole/README.md#troubleshooting)** - Common issues and solutions
- 📖 **[Apache Guacamole Docs](https://guacamole.apache.org/doc/gug/)** - Official documentation
- 💡 **Issues**: Open a GitHub issue for support

## License

This Docker Compose setup is released under the MIT License. Apache Guacamole is licensed under the Apache License 2.0.

---

**Ready to get started?** Follow the **[Complete Setup Guide](./guacamole/README.md)** for detailed instructions!