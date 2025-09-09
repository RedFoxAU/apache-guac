# Quick Reference

This repository contains a production-ready Apache Guacamole Docker Compose setup.

## 🚀 Quick Start

```bash
cd guacamole/
cp env.example .env
# Edit .env - change WORKING_DIR from /home/$USER/docker to /home/yourusername/docker
./manage.sh setup
./manage.sh start
```

Access: http://localhost:8080/ (login: guacadmin/guacadmin)

## 📁 Files

- **[/guacamole/](./guacamole/)** - Complete Docker setup
- **[README.md](./README.md)** - Main documentation  
- **[guacamole/README.md](./guacamole/README.md)** - Detailed setup guide

## 🛠️ Management

```bash
./manage.sh status    # Check services
./manage.sh logs      # View logs  
./manage.sh backup    # Backup data
./manage.sh health    # Health check
```
