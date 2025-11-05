# Docker Setup for Open SWE

This document provides comprehensive instructions for running Open SWE using Docker.

## Overview

Open SWE consists of multiple services that can be containerized:
- **Web Application**: Next.js frontend (port 3000)
- **LangGraph Agent**: Core AI agent service (port 2024)
- **Optional Services**: Redis for caching, PostgreSQL for development

## Quick Start

### Prerequisites

- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)
- At least 4GB of available RAM
- 10GB of free disk space

### 1. Setup Environment Files

```bash
# Run the setup script
./scripts/docker-setup.sh setup

# Or manually copy environment files
cp apps/web/.env.example apps/web/.env
cp apps/open-swe/.env.example apps/open-swe/.env
```

**Important**: Edit the `.env` files with your actual configuration:
- API keys (Anthropic, OpenAI, etc.)
- GitHub App credentials
- LangSmith configuration
- Other service credentials

### 2. Choose Your Setup

#### Production Setup (Recommended)
```bash
# Using the setup script
./scripts/docker-setup.sh prod

# Or manually
docker-compose up -d
```

#### Development Setup (with hot reloading)
```bash
# Using the setup script
./scripts/docker-setup.sh dev

# Or manually
docker-compose -f docker-compose.dev.yml up -d
```

### 3. Access the Application

- **Web Interface**: http://localhost:3000
- **Agent API**: http://localhost:2024
- **API Documentation**: http://localhost:2024/docs (when available)

## Docker Files Explained

### Production Dockerfiles

#### `Dockerfile.web`
- Multi-stage build for the Next.js web application
- Optimized for production with minimal image size
- Includes standalone output for better performance

#### `Dockerfile.agent`
- Containerizes the LangGraph agent service
- Includes Python dependencies for AI/ML libraries
- Configured for production deployment

### Development Setup

#### `Dockerfile.dev`
- Single container running both services
- Uses PM2 for process management
- Includes development tools and hot reloading

#### `docker-compose.dev.yml`
- Volume mounts for live code reloading
- Includes development databases
- Optimized for development workflow

## Configuration

### Environment Variables

#### Web Application (`apps/web/.env`)
```env
# GitHub OAuth
NEXT_PUBLIC_GITHUB_APP_CLIENT_ID=your_client_id
GITHUB_APP_CLIENT_SECRET=your_client_secret

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:3000/api
LANGGRAPH_API_URL=http://agent:2024

# Security
SECRETS_ENCRYPTION_KEY=your_32_byte_hex_key
```

#### Agent Service (`apps/open-swe/.env`)
```env
# LLM Providers
ANTHROPIC_API_KEY=your_anthropic_key
OPENAI_API_KEY=your_openai_key

# LangSmith
LANGCHAIN_API_KEY=your_langsmith_key
LANGCHAIN_PROJECT=your_project_name

# GitHub App
GITHUB_APP_ID=your_app_id
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----..."

# Infrastructure
DAYTONA_API_KEY=your_daytona_key
```

### Port Configuration

| Service | Port | Description |
|---------|------|-------------|
| Web App | 3000 | Next.js frontend |
| Agent API | 2024 | LangGraph agent service |
| Redis | 6379 | Caching (optional) |
| PostgreSQL | 5432 | Database (dev only) |

## Management Commands

### Using the Setup Script

```bash
# Setup environment files
./scripts/docker-setup.sh setup

# Start production environment
./scripts/docker-setup.sh prod

# Start development environment
./scripts/docker-setup.sh dev

# View logs
./scripts/docker-setup.sh logs
./scripts/docker-setup.sh logs web  # specific service

# Stop all services
./scripts/docker-setup.sh stop

# Clean up resources
./scripts/docker-setup.sh cleanup
```

### Manual Docker Commands

```bash
# Build and start production
docker-compose build
docker-compose up -d

# Build and start development
docker-compose -f docker-compose.dev.yml build
docker-compose -f docker-compose.dev.yml up -d

# View logs
docker-compose logs -f
docker-compose logs -f web

# Stop services
docker-compose down

# Clean up
docker-compose down --volumes --remove-orphans
docker system prune -f
```

## Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Clear Docker cache and rebuild
docker system prune -a
docker-compose build --no-cache
```

#### 2. Port Conflicts
```bash
# Check what's using the ports
lsof -i :3000
lsof -i :2024

# Stop conflicting services or change ports in docker-compose.yml
```

#### 3. Environment Variables Not Loading
- Ensure `.env` files exist in the correct locations
- Check file permissions: `chmod 644 apps/*/.env`
- Verify no trailing spaces in environment values

#### 4. Yarn Version Mismatch
If you see errors like "This project's package.json defines packageManager: yarn@3.5.1":
```bash
# The Dockerfiles now use Corepack to handle this automatically
# If you encounter this error, ensure you're using the latest Docker images

# For local development, enable Corepack:
corepack enable
corepack prepare yarn@3.5.1 --activate
```

#### 5. Memory Issues
```bash
# Increase Docker memory limit (Docker Desktop)
# Or add swap space on Linux systems

# Monitor container resource usage
docker stats
```

### Debugging

#### View Container Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f web
docker-compose logs -f agent

# Last 100 lines
docker-compose logs --tail=100 web
```

#### Execute Commands in Containers
```bash
# Access web container
docker-compose exec web sh

# Access agent container
docker-compose exec agent sh

# Run commands
docker-compose exec web yarn build
docker-compose exec agent yarn test
```

#### Health Checks
```bash
# Check service status
docker-compose ps

# Test web app
curl http://localhost:3000

# Test agent API
curl http://localhost:2024/health
```

## Performance Optimization

### Production Optimizations

1. **Multi-stage Builds**: Reduces image size by excluding development dependencies
2. **Layer Caching**: Optimized Dockerfile layer ordering for better caching
3. **Resource Limits**: Configure memory and CPU limits in docker-compose.yml

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
```

### Development Optimizations

1. **Volume Mounts**: Enable hot reloading without rebuilding containers
2. **Bind Mounts**: Mount source code for immediate changes
3. **Development Tools**: Include debugging and profiling tools

## Security Considerations

### Environment Security
- Never commit `.env` files to version control
- Use Docker secrets for sensitive data in production
- Regularly rotate API keys and tokens

### Network Security
- Use internal Docker networks for service communication
- Expose only necessary ports to the host
- Consider using a reverse proxy (nginx) for production

### Container Security
- Run containers as non-root users
- Keep base images updated
- Scan images for vulnerabilities

```bash
# Scan for vulnerabilities
docker scan openswe_web:latest
```

## Deployment

### Production Deployment

1. **Environment Setup**
   ```bash
   # Copy and configure production environment
   cp apps/web/.env.example apps/web/.env.production
   cp apps/open-swe/.env.example apps/open-swe/.env.production
   ```

2. **Build and Deploy**
   ```bash
   # Build production images
   docker-compose -f docker-compose.yml build

   # Deploy with production environment
   docker-compose -f docker-compose.yml up -d
   ```

3. **Health Monitoring**
   ```bash
   # Monitor services
   docker-compose ps
   docker-compose logs -f
   ```

### Cloud Deployment

For cloud deployment, consider:
- Using managed databases (RDS, Cloud SQL)
- Container orchestration (Kubernetes, ECS)
- Load balancing and auto-scaling
- Monitoring and logging solutions

## Maintenance

### Regular Tasks

```bash
# Update images
docker-compose pull
docker-compose up -d

# Clean up unused resources
docker system prune -f

# Backup volumes
docker run --rm -v openswe_agent-data:/data -v $(pwd):/backup alpine tar czf /backup/agent-data.tar.gz -C /data .
```

### Monitoring

```bash
# Resource usage
docker stats

# Disk usage
docker system df

# Container health
docker-compose ps
```

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review container logs for error messages
3. Consult the main Open SWE documentation
4. Open an issue on the GitHub repository

## Contributing

When contributing Docker-related changes:
1. Test both development and production setups
2. Update this documentation
3. Ensure backward compatibility
4. Follow Docker best practices