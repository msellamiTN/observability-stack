#!/bin/bash

# ============================================================================
# Observability Stack Management Script
# Manage Grafana, Prometheus, Loki, Tempo, InfluxDB, MS SQL Server
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
BACKUP_DIR="./backups/$(date +%Y-%m-%d_%H-%M-%S)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  $1${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ============================================================================
# Service Management
# ============================================================================

start_all() {
    print_header "Starting All Services"
    docker-compose up -d
    print_success "All services started"
    echo ""
    show_status
}

stop_all() {
    print_header "Stopping All Services"
    docker-compose down
    print_success "All services stopped"
}

restart_all() {
    print_header "Restarting All Services"
    docker-compose restart
    print_success "All services restarted"
    echo ""
    show_status
}

start_service() {
    local service=$1
    print_info "Starting $service..."
    docker-compose up -d "$service"
    print_success "$service started"
}

stop_service() {
    local service=$1
    print_info "Stopping $service..."
    docker-compose stop "$service"
    print_success "$service stopped"
}

restart_service() {
    local service=$1
    print_info "Restarting $service..."
    docker-compose restart "$service"
    print_success "$service restarted"
}

rebuild_service() {
    local service=$1
    print_header "Rebuilding $service"
    docker-compose build "$service"
    docker-compose up -d "$service"
    print_success "$service rebuilt and started"
}

# ============================================================================
# Status & Health Checks
# ============================================================================

show_status() {
    print_header "Services Status"
    docker-compose ps
    echo ""
}

check_health() {
    print_header "Health Check"
    
    # Grafana
    echo -n "Grafana (3000): "
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        print_success "Healthy"
    else
        print_error "Not responding"
    fi
    
    # Prometheus
    echo -n "Prometheus (9090): "
    if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
        print_success "Healthy"
    else
        print_error "Not responding"
    fi
    
    # Loki
    echo -n "Loki (3100): "
    if curl -s http://localhost:3100/ready > /dev/null 2>&1; then
        print_success "Ready"
    else
        print_error "Not responding"
    fi
    
    # Tempo
    echo -n "Tempo (3200): "
    if curl -s http://localhost:3200/status > /dev/null 2>&1; then
        print_success "Ready"
    else
        print_error "Not responding"
    fi
    
    # InfluxDB
    echo -n "InfluxDB (8086): "
    if curl -s http://localhost:8086/health > /dev/null 2>&1; then
        print_success "Healthy"
    else
        print_error "Not responding"
    fi
    
    # Payment API
    echo -n "Payment API (8888): "
    if curl -s http://localhost:8888/health > /dev/null 2>&1; then
        print_success "Healthy"
    else
        print_error "Not responding"
    fi
    
    echo ""
}

show_logs() {
    local service=$1
    local lines=${2:-100}
    
    if [ -z "$service" ]; then
        print_error "Please specify a service"
        echo "Available services: grafana, prometheus, loki, tempo, influxdb, mssql, payment-api_instrumented"
        return 1
    fi
    
    print_header "Logs for $service (last $lines lines)"
    docker-compose logs --tail="$lines" "$service"
}

follow_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        print_error "Please specify a service"
        return 1
    fi
    
    print_header "Following logs for $service (Ctrl+C to stop)"
    docker-compose logs -f "$service"
}

# ============================================================================
# Backup & Restore
# ============================================================================

backup_all() {
    print_header "Creating Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup Grafana
    print_info "Backing up Grafana..."
    docker cp grafana:/var/lib/grafana/grafana.db "$BACKUP_DIR/grafana.db" 2>/dev/null || print_warning "Grafana backup failed"
    
    # Backup Prometheus config
    print_info "Backing up Prometheus configuration..."
    cp -r ./prometheus "$BACKUP_DIR/prometheus" 2>/dev/null || print_warning "Prometheus config backup failed"
    
    # Backup Alertmanager config
    print_info "Backing up Alertmanager configuration..."
    cp -r ./alertmanager "$BACKUP_DIR/alertmanager" 2>/dev/null || print_warning "Alertmanager config backup failed"
    
    # Backup Loki config
    print_info "Backing up Loki configuration..."
    cp -r ./loki "$BACKUP_DIR/loki" 2>/dev/null || print_warning "Loki config backup failed"
    
    # Create metadata
    cat > "$BACKUP_DIR/metadata.txt" << EOF
Backup Date: $(date)
Hostname: $(hostname)
Docker Compose Version: $(docker-compose version --short)
EOF
    
    print_success "Backup completed: $BACKUP_DIR"
    echo ""
    ls -lh "$BACKUP_DIR"
}

restore_backup() {
    local backup_path=$1
    
    if [ -z "$backup_path" ]; then
        print_error "Please specify backup directory"
        return 1
    fi
    
    if [ ! -d "$backup_path" ]; then
        print_error "Backup directory not found: $backup_path"
        return 1
    fi
    
    print_header "Restoring from Backup"
    print_warning "This will overwrite current configuration!"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Restore cancelled"
        return 0
    fi
    
    # Stop services
    print_info "Stopping services..."
    docker-compose stop
    
    # Restore Grafana
    if [ -f "$backup_path/grafana.db" ]; then
        print_info "Restoring Grafana..."
        docker cp "$backup_path/grafana.db" grafana:/var/lib/grafana/grafana.db
    fi
    
    # Restore configs
    if [ -d "$backup_path/prometheus" ]; then
        print_info "Restoring Prometheus configuration..."
        cp -r "$backup_path/prometheus"/* ./prometheus/
    fi
    
    if [ -d "$backup_path/alertmanager" ]; then
        print_info "Restoring Alertmanager configuration..."
        cp -r "$backup_path/alertmanager"/* ./alertmanager/
    fi
    
    # Restart services
    print_info "Restarting services..."
    docker-compose up -d
    
    print_success "Restore completed"
}

# ============================================================================
# Testing & Monitoring
# ============================================================================

test_observability() {
    print_header "Testing Observability Stack"
    
    if [ -f "./payment-api-instrumented/test-observability.ps1" ]; then
        print_info "Running observability test..."
        cd payment-api-instrumented
        pwsh -File test-observability.ps1
        cd ..
    else
        print_error "Test script not found"
    fi
}

generate_traffic() {
    local count=${1:-50}
    print_header "Generating Test Traffic ($count requests)"
    
    for i in $(seq 1 "$count"); do
        curl -s -X POST http://localhost:8888/api/payments \
            -H "Content-Type: application/json" \
            -d "{
                \"amount\": $((RANDOM % 1000 + 10)),
                \"currency\": \"EUR\",
                \"paymentMethod\": \"card\",
                \"cardBrand\": \"VISA\",
                \"userId\": \"U$RANDOM\",
                \"region\": \"EU_WEST\"
            }" > /dev/null
        
        echo -ne "Progress: [$i/$count]\r"
        sleep 0.1
    done
    
    echo ""
    print_success "Generated $count transactions"
}

# ============================================================================
# Cleanup
# ============================================================================

cleanup() {
    print_header "Cleanup"
    
    print_warning "This will remove stopped containers, unused networks, and dangling images"
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Cleanup cancelled"
        return 0
    fi
    
    print_info "Removing stopped containers..."
    docker container prune -f
    
    print_info "Removing unused networks..."
    docker network prune -f
    
    print_info "Removing dangling images..."
    docker image prune -f
    
    print_success "Cleanup completed"
}

deep_clean() {
    print_header "Deep Clean"
    
    print_error "WARNING: This will remove ALL containers, volumes, and images!"
    print_error "All data will be lost!"
    read -p "Are you absolutely sure? (type 'yes' to confirm): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_info "Deep clean cancelled"
        return 0
    fi
    
    print_info "Stopping all services..."
    docker-compose down -v
    
    print_info "Removing all containers..."
    docker container prune -a -f
    
    print_info "Removing all volumes..."
    docker volume prune -a -f
    
    print_info "Removing all images..."
    docker image prune -a -f
    
    print_success "Deep clean completed"
}

# ============================================================================
# Information
# ============================================================================

show_urls() {
    print_header "Service URLs"
    echo -e "${CYAN}Grafana:${NC}         http://localhost:3000"
    echo -e "${CYAN}Prometheus:${NC}      http://localhost:9090"
    echo -e "${CYAN}Loki:${NC}            http://localhost:3100"
    echo -e "${CYAN}Tempo:${NC}           http://localhost:3200"
    echo -e "${CYAN}InfluxDB:${NC}        http://localhost:8086"
    echo -e "${CYAN}Alertmanager:${NC}    http://localhost:9093"
    echo -e "${CYAN}Payment API:${NC}     http://localhost:8888"
    echo ""
    echo -e "${YELLOW}Credentials:${NC}"
    echo -e "  Grafana:  admin / GrafanaSecure123!Change@Me"
    echo -e "  InfluxDB: admin / InfluxSecure123!Change@Me"
    echo ""
}

show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗
║  Observability Stack Management Script                    ║
╚════════════════════════════════════════════════════════════╝${NC}

${YELLOW}Usage:${NC} $0 [command] [options]

${YELLOW}Service Management:${NC}
  start               Start all services
  stop                Stop all services
  restart             Restart all services
  start <service>     Start specific service
  stop <service>      Stop specific service
  restart <service>   Restart specific service
  rebuild <service>   Rebuild and restart service

${YELLOW}Monitoring:${NC}
  status              Show services status
  health              Check health of all services
  logs <service>      Show logs (last 100 lines)
  follow <service>    Follow logs in real-time
  urls                Show service URLs and credentials

${YELLOW}Testing:${NC}
  test                Run observability tests
  traffic [count]     Generate test traffic (default: 50)

${YELLOW}Backup & Restore:${NC}
  backup              Create backup of all configurations
  restore <path>      Restore from backup

${YELLOW}Maintenance:${NC}
  cleanup             Remove stopped containers and unused resources
  deep-clean          Remove ALL containers, volumes, and images (DANGEROUS!)

${YELLOW}Available Services:${NC}
  grafana, prometheus, loki, tempo, influxdb, mssql,
  alertmanager, node_exporter, payment-api_instrumented,
  ebanking_metrics_exporter

${YELLOW}Examples:${NC}
  $0 start
  $0 restart grafana
  $0 logs prometheus
  $0 follow loki
  $0 traffic 100
  $0 backup
  $0 health

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    local command=$1
    shift
    
    case "$command" in
        start)
            if [ -z "$1" ]; then
                start_all
            else
                start_service "$1"
            fi
            ;;
        stop)
            if [ -z "$1" ]; then
                stop_all
            else
                stop_service "$1"
            fi
            ;;
        restart)
            if [ -z "$1" ]; then
                restart_all
            else
                restart_service "$1"
            fi
            ;;
        rebuild)
            rebuild_service "$1"
            ;;
        status)
            show_status
            ;;
        health)
            check_health
            ;;
        logs)
            show_logs "$1" "$2"
            ;;
        follow)
            follow_logs "$1"
            ;;
        backup)
            backup_all
            ;;
        restore)
            restore_backup "$1"
            ;;
        test)
            test_observability
            ;;
        traffic)
            generate_traffic "$1"
            ;;
        cleanup)
            cleanup
            ;;
        deep-clean)
            deep_clean
            ;;
        urls)
            show_urls
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
if [ $# -eq 0 ]; then
    show_help
else
    main "$@"
fi
