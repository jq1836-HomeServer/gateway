# Nginx Reverse Proxy Gateway

This directory contains an nginx reverse proxy configuration that accepts HTTPS connections and downgrades to HTTP when proxying to internal services.

## Features

- **HTTPS Only**: All HTTP traffic is redirected to HTTPS
- **HTTP Downgrade**: Accepts HTTPS from clients but proxies to internal services over HTTP
- **Configurable Rate Limiting**: Environment-variable driven rate limiting with multiple zones
- **Security Headers**: Modern security headers including HSTS
- **Multiple Services**: Support for multiple internal services with different routing rules
- **WebSocket Support**: Includes WebSocket proxy configuration
- **Health Checks**: Built-in health check endpoint
- **Auto-SSL Generation**: Automatic self-signed SSL certificate generation for development
- **Container Optimized**: Ready-to-use Docker image with validation and health checks
- **CI/CD Ready**: GitHub Actions workflows for automated building and deployment

## Structure

```
gateway/
├── .github/workflows/               # GitHub Actions workflows
│   ├── docker-build.yml            # Build and push Docker images
│   └── release.yml                 # Release automation
├── nginx/
│   ├── nginx.conf                   # Main nginx configuration
│   └── conf.d/
│       ├── default.conf.template    # Server block configurations
│       └── rate-limits.conf.template # Rate limiting configuration
├── ssl/                             # SSL certificates directory
├── Dockerfile                       # Container build configuration
├── .dockerignore                    # Docker build context exclusions
├── docker-compose.example.yml       # Example Docker Compose setup
├── .env                             # Environment variables (create from .env.example)
├── .env.example                     # Development environment template
├── .env.production                  # Production environment template
├── CONFIGURATION.md                 # Complete configuration reference
├── RATE_LIMITING.md                 # Rate limiting configuration guide
└── GITHUB_ACTIONS.md                # GitHub Actions setup guide
```

## Quick Start

### 1. Configure Environment Variables

Copy the example environment file and customize it:

```bash
# Copy appropriate template
cp .env.example .env           # For development
# OR
cp .env.production .env        # For production

# Edit the .env file to configure your services
```

**Key variables to configure:**
```bash
# Domain configuration
DOMAIN=your-domain.com
API_DOMAIN=api.your-domain.com

# Internal service configuration
INTERNAL_MAIN_HOST=your-go-service
INTERNAL_MAIN_PORT=8000

INTERNAL_API_HOST=your-api-service
INTERNAL_API_PORT=3000
```

See `CONFIGURATION.md` for complete reference of all available variables.

### 2. SSL Certificates

**For development**, generate self-signed certificates:
```bash
# Create SSL directory
mkdir -p ssl

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/server.key \
    -out ssl/server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"
```

**For production**, use certificates from a trusted CA (Let's Encrypt recommended).

### 3. Deploy with Container Platform

#### Using the Dockerfile

**Build locally for testing:**
```bash
# Build the image
docker build -t nginx-gateway .

# Or use GitHub Actions for automated builds
# See GITHUB_ACTIONS.md for setup instructions
```

**Pull from Docker Hub (after CI/CD setup):**
```bash
# Pull your published image
docker pull yourusername/nginx-gateway:latest
```

**Run the container:**
```bash
# Using your published image from Docker Hub
docker run -d \
  --name nginx-gateway \
  -p 80:80 -p 443:443 \
  -e DOMAIN=your-domain.com \
  -e INTERNAL_MAIN_HOST=your-app-host \
  -e INTERNAL_MAIN_PORT=8000 \
  yourusername/nginx-gateway:latest

# Using locally built image
docker run -d \
  --name nginx-gateway \
  -p 80:80 -p 443:443 \
  -v /path/to/ssl:/etc/nginx/ssl:ro \
  --env-file .env \
  nginx-gateway
```

#### Using Docker Compose

```bash
# Copy example and customize
cp docker-compose.example.yml docker-compose.yml
# Edit docker-compose.yml with your settings
docker-compose up -d
```

#### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-gateway
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-gateway
  template:
    metadata:
      labels:
        app: nginx-gateway
    spec:
      containers:
      - name: nginx
        image: nginx-gateway:latest
        ports:
        - containerPort: 80
        - containerPort: 443
        env:
        - name: DOMAIN
          value: "your-domain.com"
        - name: INTERNAL_MAIN_HOST
          value: "backend-service"
        - name: INTERNAL_MAIN_PORT
          value: "8000"
        envFrom:
        - configMapRef:
            name: nginx-gateway-config
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/nginx/ssl
          readOnly: true
        livenessProbe:
          httpGet:
            path: /health
            port: 443
            scheme: HTTPS
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 443
            scheme: HTTPS
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: ssl-certs
        secret:
          secretName: nginx-ssl-certs
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-gateway-service
spec:
  selector:
    app: nginx-gateway
  ports:
  - name: http
    port: 80
    targetPort: 80
  - name: https
    port: 443
    targetPort: 443
  type: LoadBalancer
```

## Docker Features

### Automatic SSL Certificate Generation
- **Development**: Auto-generates self-signed certificates if none provided
- **Production**: Mount your own certificates or use init containers
- **Validation**: Checks certificate validity and expiration

### Environment Validation
- **Required Variables**: Validates essential configuration on startup
- **Rate Limit Format**: Validates rate limiting syntax
- **Graceful Failure**: Clear error messages for misconfigurations

### Health Checks
- **Built-in Endpoint**: `/health` endpoint for load balancer health checks
- **Container Health**: Docker health check validates nginx status
- **SSL Monitoring**: Alerts on certificate expiration within 24 hours

### Build Options
```bash
# GitHub Actions automated builds
# See GITHUB_ACTIONS.md for complete setup guide

# Local development build
docker build -t nginx-gateway .

# Multi-platform build (requires Docker Buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t nginx-gateway .
```

## Configuration

## Configuration

All configuration is managed through environment variables. See `CONFIGURATION.md` for complete reference.

### Essential Variables
```bash
# Domains
DOMAIN=your-domain.com
API_DOMAIN=api.your-domain.com

# SSL
SSL_CERT_PATH=/etc/nginx/ssl/server.crt
SSL_KEY_PATH=/etc/nginx/ssl/server.key

# Services
INTERNAL_MAIN_HOST=app-server
INTERNAL_MAIN_PORT=8000
```

### Rate Limiting
```bash
# Customize rate limits per endpoint type
RATE_LIMIT_GENERAL_RATE=100r/s     # Web traffic
RATE_LIMIT_API_RATE=500r/s         # API calls
RATE_LIMIT_LOGIN_RATE=10r/m        # Authentication
```

### Environment Profiles

**Development** (`.env.example`):
- Relaxed rate limits
- Local service hostnames
- Self-signed certificates

**Production** (`.env.production`):
- Stricter security
- Production service names
- Higher rate limits for scale

## Adding New Services

1. **Add environment variables** to your `.env` file:
```bash
INTERNAL_NEWSERVICE_HOST=new-service
INTERNAL_NEWSERVICE_PORT=9000
```

2. **Add location block** in `nginx/conf.d/default.conf.template`:
```nginx
location /newservice/ {
    limit_req zone=general burst=${RATE_LIMIT_GENERAL_BURST:-20} nodelay;
    proxy_pass http://${INTERNAL_NEWSERVICE_HOST}:${INTERNAL_NEWSERVICE_PORT}/;
}
```

## Security Features

### Rate Limiting
- **Multiple Zones**: Different limits for web, API, auth, uploads
- **Configurable**: All limits adjustable via environment variables
- **Burst Handling**: Allows temporary traffic spikes
- **Memory Efficient**: Configurable memory allocation

### Security Headers
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- X-XSS-Protection: enabled
- Strict-Transport-Security: HSTS enabled
- Referrer-Policy: strict-origin-when-cross-origin

### SSL Configuration
- TLS 1.2 and 1.3 only
- Modern cipher suites
- Session caching for performance
- HSTS enabled

## Production Deployment

### SSL Certificates
**Let's Encrypt** (recommended):
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Generate certificate
sudo certbot --nginx -d your-domain.com
```

### Container Orchestration
The configuration works with any container platform:
- Docker / Docker Compose
- Kubernetes
- OpenShift
- HashiCorp Nomad
- Docker Swarm

### Environment Variables
Use your platform's secret management for sensitive values:
- Kubernetes: ConfigMaps and Secrets
- Docker Swarm: Docker Secrets
- HashiCorp Nomad: Vault integration

### Monitoring
Set up monitoring for:
- Rate limit violations (429 responses)
- SSL certificate expiration
- Backend service health
- Response times and error rates

## Troubleshooting

### Common Issues

1. **Template Variables Not Substituted**:
   - Ensure environment variables are set
   - Check container logs for template errors
   - Verify template file mounting

2. **SSL Certificate Errors**:
   - Check certificate file paths and permissions
   - Verify domain names match certificate
   - Ensure certificates are properly mounted

3. **Rate Limiting Too Strict**:
   - Monitor 429 error responses
   - Adjust rate limits in environment variables
   - Increase burst values for traffic spikes

4. **Backend Connection Errors**:
   - Verify internal service hostnames and ports
   - Check network connectivity between containers
   - Review nginx error logs

### Debug Commands

```bash
# Check template substitution
docker logs nginx-container-name

# Test nginx configuration
docker exec nginx-container nginx -t

# View rate limit status
docker exec nginx-container nginx -s reload

# Monitor real-time logs
docker logs -f nginx-container-name
```

## Documentation

- `CONFIGURATION.md` - Complete environment variable reference
- `RATE_LIMITING.md` - Detailed rate limiting guide
- `README.md` - This overview and quick start guide
