#!/bin/bash

# Open SWE Docker Setup Script
set -e

echo "🐳 Open SWE Docker Setup"
echo "========================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed and set the command variable
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_success "Docker and Docker Compose are installed (using: $DOCKER_COMPOSE_CMD)"

# Ensure we're in the project root directory
print_status "Verifying project root directory..."

# Try to find the git repository root
if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
    if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT" ]; then
        cd "$REPO_ROOT"
        print_status "Changed to repository root: $REPO_ROOT"
    fi
fi

# Verify we're in the correct directory by checking for required files
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in current directory: $(pwd)"
    print_error "Please run this script from the Open SWE project root directory"
    exit 1
fi

if [ ! -f "docker-compose.dev.yml" ]; then
    print_error "docker-compose.dev.yml not found in current directory: $(pwd)"
    print_error "Please ensure all Docker configuration files are present"
    exit 1
fi

# Verify the apps directories exist
if [ ! -d "apps/web" ]; then
    print_error "apps/web directory not found. Are you in the correct project directory?"
    exit 1
fi

if [ ! -d "apps/open-swe" ]; then
    print_error "apps/open-swe directory not found. Are you in the correct project directory?"
    exit 1
fi

print_success "Project structure verified"

# Function to setup environment files
setup_env_files() {
    print_status "Setting up environment files..."
    
    # Web app environment
    if [ ! -f "apps/web/.env" ]; then
        if [ -f "apps/web/.env.example" ]; then
            cp apps/web/.env.example apps/web/.env
            print_success "Created apps/web/.env from example"
            print_warning "Please edit apps/web/.env with your configuration"
        else
            print_error "apps/web/.env.example not found"
        fi
    else
        print_status "apps/web/.env already exists"
    fi
    
    # Agent environment
    if [ ! -f "apps/open-swe/.env" ]; then
        if [ -f "apps/open-swe/.env.example" ]; then
            cp apps/open-swe/.env.example apps/open-swe/.env
            print_success "Created apps/open-swe/.env from example"
            print_warning "Please edit apps/open-swe/.env with your configuration"
        else
            print_error "apps/open-swe/.env.example not found"
        fi
    else
        print_status "apps/open-swe/.env already exists"
    fi
}

# Function to build and start services
start_production() {
    print_status "Building and starting production services..."
    $DOCKER_COMPOSE_CMD down --remove-orphans
    $DOCKER_COMPOSE_CMD build --no-cache
    $DOCKER_COMPOSE_CMD up -d
    print_success "Production services started"
    print_status "Web app: http://localhost:3000"
    print_status "Agent API: http://localhost:2024"
}

# Function to start development environment
start_development() {
    print_status "Building and starting development environment..."
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml down --remove-orphans
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml build --no-cache
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml up -d
    print_success "Development environment started"
    print_status "Web app: http://localhost:3000"
    print_status "Agent API: http://localhost:2024"
    print_status "Use '$DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs -f' to view logs"
}

# Function to stop services
stop_services() {
    print_status "Stopping all services..."
    $DOCKER_COMPOSE_CMD down --remove-orphans
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml down --remove-orphans
    print_success "All services stopped"
}

# Function to clean up Docker resources
cleanup() {
    print_status "Cleaning up Docker resources..."
    $DOCKER_COMPOSE_CMD down --remove-orphans --volumes
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml down --remove-orphans --volumes
    docker system prune -f
    print_success "Cleanup completed"
}

# Function to show logs
show_logs() {
    local service=${1:-""}
    if [ -n "$service" ]; then
        # Verify service exists
        if ! $DOCKER_COMPOSE_CMD ps "$service" &> /dev/null; then
            print_error "Service '$service' not found or not running"
            print_status "Available services:"
            $DOCKER_COMPOSE_CMD ps --services
            return 1
        fi
        print_status "Showing logs for $service..."
        $DOCKER_COMPOSE_CMD logs -f "$service"
    else
        print_status "Showing logs for all services..."
        $DOCKER_COMPOSE_CMD logs -f
    fi
}

# Main menu
case "${1:-}" in
    "setup")
        setup_env_files
        ;;
    "prod"|"production")
        setup_env_files
        start_production
        ;;
    "dev"|"development")
        setup_env_files
        start_development
        ;;
    "stop")
        stop_services
        ;;
    "logs")
        show_logs "${2:-}"
        ;;
    "cleanup")
        cleanup
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup       Setup environment files"
        echo "  prod        Start production environment"
        echo "  dev         Start development environment"
        echo "  stop        Stop all services"
        echo "  logs [svc]  Show logs (optionally for specific service)"
        echo "  cleanup     Clean up Docker resources"
        echo "  help        Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 setup"
        echo "  $0 dev"
        echo "  $0 logs web"
        echo "  $0 stop"
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        print_status "Use '$0 help' for usage information"
        exit 1
        ;;
esac