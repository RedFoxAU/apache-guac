#!/bin/bash
# Apache Guacamole Management Script
# =================================
# 
# Provides easy management commands for the Guacamole Docker Compose setup.

set -e

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found. Please create it from env.example first."
    exit 1
fi

# Expand $USER in WORKING_DIR
WORKING_DIR=$(eval echo "$WORKING_DIR")

show_usage() {
    echo "Apache Guacamole Management Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  setup          - Complete initial setup (directories, secrets, database)"
    echo "  start          - Start all services"
    echo "  start-nginx    - Start all services including Nginx"
    echo "  stop           - Stop all services"
    echo "  restart        - Restart all services"
    echo "  status         - Show service status"
    echo "  logs [service] - Show logs (all services or specific service)"
    echo "  update         - Update container images"
    echo "  backup         - Create backup of data"
    echo "  health         - Check service health"
    echo "  reset          - Reset and regenerate secrets"
    echo "  clean          - Remove all containers and data (DESTRUCTIVE)"
    echo ""
    echo "Examples:"
    echo "  $0 setup                 # Complete setup"
    echo "  $0 logs guacamole       # Show Guacamole logs"
    echo "  $0 backup               # Backup all data"
}

setup_complete() {
    echo "🚀 Setting up Apache Guacamole..."
    
    # Create directories
    echo "📁 Creating directory structure..."
    ./setup-directories.sh
    
    # Generate strong password if doesn't exist
    if [ ! -f "$WORKING_DIR/guacamole/secrets/postgres_password.txt" ]; then
        echo "🔐 Generating secure database password..."
        openssl rand -base64 32 > "$WORKING_DIR/guacamole/secrets/postgres_password.txt"
        chmod 600 "$WORKING_DIR/guacamole/secrets/postgres_password.txt"
    fi
    
    # Initialize database
    echo "🗄️ Initializing database..."
    ./init-database.sh
    
    echo "✅ Setup complete! You can now start services with:"
    echo "   $0 start"
}

start_services() {
    local profile=""
    if [ "$1" = "nginx" ]; then
        profile="--profile nginx"
        echo "🌐 Starting all services with Nginx..."
    else
        echo "🚀 Starting core services..."
    fi
    
    docker compose $profile up -d
    echo "✅ Services started successfully!"
    
    echo ""
    echo "Access Guacamole at:"
    if [ "$1" = "nginx" ]; then
        echo "  🌐 https://localhost (with Nginx proxy)"
    fi
    echo "  🌐 http://localhost:${GUACAMOLE_PORT:-8080}/ (direct access)"
    echo ""
    echo "Default login: guacadmin / guacadmin"
    echo "⚠️  Change the default password after first login!"
}

stop_services() {
    echo "🛑 Stopping all services..."
    docker compose down
    echo "✅ Services stopped successfully!"
}

restart_services() {
    echo "🔄 Restarting services..."
    docker compose restart
    echo "✅ Services restarted successfully!"
}

show_status() {
    echo "📊 Service Status:"
    echo "=================="
    docker compose ps
}

show_logs() {
    if [ -n "$1" ]; then
        echo "📝 Logs for service: $1"
        docker compose logs -f "$1"
    else
        echo "📝 Logs for all services:"
        docker compose logs -f
    fi
}

update_images() {
    echo "⬇️ Updating container images..."
    docker compose pull
    echo "🔄 Recreating containers with new images..."
    docker compose up -d
    echo "✅ Update complete!"
}

backup_data() {
    local backup_dir="/tmp/guacamole-backup-$(date +%Y%m%d_%H%M%S)"
    echo "💾 Creating backup in: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Stop services for consistent backup
    echo "🛑 Stopping services for backup..."
    docker compose stop
    
    # Backup important directories
    echo "📁 Backing up data directories..."
    cp -r "$WORKING_DIR/guacamole/postgres/data" "$backup_dir/" 2>/dev/null || echo "⚠️  No postgres data found"
    cp -r "$WORKING_DIR/guacamole/webapp/config" "$backup_dir/" 2>/dev/null || echo "⚠️  No webapp config found"
    cp -r "$WORKING_DIR/guacamole/secrets" "$backup_dir/" 2>/dev/null || echo "⚠️  No secrets found"
    
    # Backup configuration files
    cp .env "$backup_dir/" 2>/dev/null || echo "⚠️  No .env file found"
    cp docker-compose.yaml "$backup_dir/" 2>/dev/null || echo "⚠️  No docker-compose.yaml found"
    
    # Restart services
    echo "🚀 Restarting services..."
    docker compose start
    
    # Create archive
    tar -czf "${backup_dir}.tar.gz" -C "/tmp" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    echo "✅ Backup created: ${backup_dir}.tar.gz"
}

check_health() {
    echo "🏥 Service Health Check:"
    echo "======================="
    
    services=("postgres" "guacd" "guacamole")
    
    for service in "${services[@]}"; do
        if docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -q "$service.*healthy"; then
            echo "✅ $service: healthy"
        elif docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -q "$service.*running"; then
            echo "⚠️  $service: running (no health check or starting up)"
        else
            echo "❌ $service: not running or unhealthy"
        fi
    done
}

reset_secrets() {
    echo "🔐 Resetting secrets..."
    
    read -p "This will generate new passwords. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 1
    fi
    
    # Generate new password
    openssl rand -base64 32 > "$WORKING_DIR/guacamole/secrets/postgres_password.txt"
    chmod 600 "$WORKING_DIR/guacamole/secrets/postgres_password.txt"
    
    echo "✅ New secrets generated!"
    echo "⚠️  You will need to restart services and may need to recreate the database."
}

clean_all() {
    echo "🧹 This will PERMANENTLY DELETE all Guacamole data and containers!"
    read -p "Are you absolutely sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo "Cancelled."
        exit 1
    fi
    
    echo "🛑 Stopping and removing containers..."
    docker compose down -v
    
    echo "🗑️ Removing data directories..."
    rm -rf "$WORKING_DIR/guacamole/"
    
    echo "🧹 Removing Docker images..."
    docker image prune -f
    
    echo "✅ Complete cleanup finished!"
}

# Main command handling
case "$1" in
    setup)
        setup_complete
        ;;
    start)
        start_services
        ;;
    start-nginx)
        start_services nginx
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    update)
        update_images
        ;;
    backup)
        backup_data
        ;;
    health)
        check_health
        ;;
    reset)
        reset_secrets
        ;;
    clean)
        clean_all
        ;;
    *)
        show_usage
        exit 1
        ;;
esac