#!/bin/bash
# Apache Guacamole Directory Setup Script
# =======================================
# 
# This script creates the necessary directory structure for Apache Guacamole
# Docker Compose setup with proper bind mounts.

set -e  # Exit on any error

# Load environment variables
if [ -f .env ]; then
    set -a  # Automatically export variables
    source .env
    set +a
else
    echo "Error: .env file not found. Please create it from env.example first."
    exit 1
fi

# Check if WORKING_DIR is set
if [ -z "$WORKING_DIR" ]; then
    echo "Error: WORKING_DIR not set in .env file"
    exit 1
fi

# Expand $USER in WORKING_DIR
WORKING_DIR=$(eval echo "$WORKING_DIR")

echo "Creating Guacamole directory structure at: $WORKING_DIR"

# Create base directories
mkdir -p "$WORKING_DIR/guacamole"

# PostgreSQL directories
mkdir -p "$WORKING_DIR/guacamole/postgres/data"
mkdir -p "$WORKING_DIR/guacamole/postgres/initdb"
mkdir -p "$WORKING_DIR/guacamole/postgres/config"

# Guacd directories  
mkdir -p "$WORKING_DIR/guacamole/guacd/config"
mkdir -p "$WORKING_DIR/guacamole/guacd/logs"
mkdir -p "$WORKING_DIR/guacamole/guacd/drive"
mkdir -p "$WORKING_DIR/guacamole/guacd/recordings"

# Guacamole webapp directories
mkdir -p "$WORKING_DIR/guacamole/webapp/config"
mkdir -p "$WORKING_DIR/guacamole/webapp/extensions"
mkdir -p "$WORKING_DIR/guacamole/webapp/lib"
mkdir -p "$WORKING_DIR/guacamole/webapp/logs"

# Shared directories
mkdir -p "$WORKING_DIR/guacamole/shared"

# Nginx directories (optional)
mkdir -p "$WORKING_DIR/guacamole/nginx/conf.d"
mkdir -p "$WORKING_DIR/guacamole/nginx/ssl"
mkdir -p "$WORKING_DIR/guacamole/nginx/logs"
mkdir -p "$WORKING_DIR/guacamole/nginx/html"

# Secrets directory
mkdir -p "$WORKING_DIR/guacamole/secrets"

# Set proper permissions for secrets directory
chmod 700 "$WORKING_DIR/guacamole/secrets"

echo "Directory structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Create secret files in $WORKING_DIR/guacamole/secrets/"
echo "2. Download and place database initialization SQL files"
echo "3. Configure nginx (if using reverse proxy)"
echo "4. Start the services with: docker compose up -d"