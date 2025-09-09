#!/bin/bash
# Apache Guacamole Database Initialization Script
# ==============================================
# 
# This script downloads and prepares the Guacamole database initialization files.
# Run this script after creating the directory structure but before starting Docker Compose.

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

INITDB_DIR="$WORKING_DIR/guacamole/postgres/initdb"

echo "Initializing Guacamole database setup..."

# Create initdb directory if it doesn't exist
mkdir -p "$INITDB_DIR"

# Download the latest Guacamole version info
echo "Checking latest Guacamole version..."
GUACAMOLE_VERSION=$(curl -s https://api.github.com/repos/apache/guacamole-client/releases/latest | grep tag_name | cut -d '"' -f 4)
echo "Latest version: $GUACAMOLE_VERSION"

# Create a temporary container to extract SQL files
echo "Creating temporary Guacamole container to extract SQL files..."
TEMP_CONTAINER_ID=$(docker create guacamole/guacamole:latest)

# Extract the PostgreSQL schema
docker cp "$TEMP_CONTAINER_ID:/opt/guacamole/postgresql/schema/" "$INITDB_DIR/"

# Clean up temporary container
docker rm "$TEMP_CONTAINER_ID"

# Rename schema files with proper ordering
if [ -d "$INITDB_DIR/schema" ]; then
    mv "$INITDB_DIR/schema"/*.sql "$INITDB_DIR/"
    rmdir "$INITDB_DIR/schema"
    
    # Ensure proper file ordering for initialization
    cd "$INITDB_DIR"
    counter=1
    for file in *.sql; do
        if [ "$file" != "*.sql" ]; then  # Check if files exist
            mv "$file" "$(printf "%02d" $counter)-$file"
            ((counter++))
        fi
    done
fi

echo "Database initialization files prepared in: $INITDB_DIR"
echo ""
echo "Files in initdb directory:"
ls -la "$INITDB_DIR"
echo ""
echo "Next step: Start the services with: docker compose up -d"