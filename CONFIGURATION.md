# Nginx Gateway Configuration Reference

This document provides a comprehensive reference for all configuration fields available in the nginx reverse proxy gateway.

## Overview

The nginx gateway uses environment variable substitution in template files to generate the final configuration. All settings can be customized through environment variables without modifying the nginx configuration files directly.

## Environment Variables Reference

### Core Domain Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DOMAIN` | Primary domain name for the gateway | `localhost` | `example.com` |
| `API_DOMAIN` | Subdomain for API endpoints | `api.localhost` | `api.example.com` |

### Network Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `HTTP_PORT` | External HTTP port (redirect only) | `80` | `8080` |
| `HTTPS_PORT` | External HTTPS port | `443` | `8443` |

### SSL/TLS Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `SSL_CERT_PATH` | Path to SSL certificate file | `/etc/nginx/ssl/server.crt` | `/etc/ssl/certs/domain.crt` |
| `SSL_KEY_PATH` | Path to SSL private key file | `/etc/nginx/ssl/server.key` | `/etc/ssl/private/domain.key` |

### Internal Service Configuration

#### Main Application Service
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_MAIN_HOST` | Hostname for main application | `internal-main` | `app-server` |
| `INTERNAL_MAIN_PORT` | Port for main application | `8000` | `3000` |

#### Web Application Service
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_APP_HOST` | Hostname for web application | `internal-app` | `web-app` |
| `INTERNAL_APP_PORT` | Port for web application | `8080` | `8080` |

#### API Service
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_API_HOST` | Hostname for API service | `internal-api` | `api-backend` |
| `INTERNAL_API_PORT` | Port for API service | `3000` | `3001` |

#### Authentication Service
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_AUTH_HOST` | Hostname for auth service | `internal-auth` | `auth-service` |
| `INTERNAL_AUTH_PORT` | Port for auth service | `8081` | `8081` |

#### WebSocket Service
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_WEBSOCKET_HOST` | Hostname for WebSocket service | `internal-websocket` | `ws-server` |
| `INTERNAL_WEBSOCKET_PORT` | Port for WebSocket service | `8082` | `8082` |

#### Upload Service (Optional)
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `INTERNAL_UPLOAD_HOST` | Hostname for upload service | Uses main service | `upload-server` |
| `INTERNAL_UPLOAD_PORT` | Port for upload service | Uses main service | `3002` |

### Rate Limiting Configuration

#### General Web Traffic
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_GENERAL_RATE` | Requests per second for general traffic | `10r/s` | `50r/s` |
| `RATE_LIMIT_GENERAL_BURST` | Burst capacity for general traffic | `20` | `100` |
| `RATE_LIMIT_GENERAL_MEMORY` | Memory allocation for tracking | `10m` | `50m` |

#### API Endpoints
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_API_RATE` | Requests per second for API calls | `50r/s` | `200r/s` |
| `RATE_LIMIT_API_BURST` | Burst capacity for API calls | `50` | `200` |
| `RATE_LIMIT_API_MEMORY` | Memory allocation for API tracking | `10m` | `100m` |

#### Authentication Endpoints
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_LOGIN_RATE` | Requests per minute for auth | `5r/m` | `10r/m` |
| `RATE_LIMIT_LOGIN_BURST` | Burst capacity for auth | `5` | `10` |
| `RATE_LIMIT_LOGIN_MEMORY` | Memory allocation for auth tracking | `10m` | `20m` |

#### Heavy API Operations
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_API_HEAVY_RATE` | Rate for resource-intensive operations | `20r/s` | `50r/s` |
| `RATE_LIMIT_API_HEAVY_BURST` | Burst for heavy operations | `10` | `25` |
| `RATE_LIMIT_API_HEAVY_MEMORY` | Memory for heavy operation tracking | `10m` | `50m` |

#### WebSocket Connections
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_WEBSOCKET_RATE` | WebSocket connection rate | `5r/s` | `20r/s` |
| `RATE_LIMIT_WEBSOCKET_BURST` | WebSocket burst capacity | `3` | `10` |
| `RATE_LIMIT_WEBSOCKET_MEMORY` | Memory for WebSocket tracking | `10m` | `20m` |

#### File Upload Endpoints
| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `RATE_LIMIT_UPLOAD_RATE` | Upload requests per second | `2r/s` | `10r/s` |
| `RATE_LIMIT_UPLOAD_BURST` | Upload burst capacity | `1` | `5` |
| `RATE_LIMIT_UPLOAD_MEMORY` | Memory for upload tracking | `10m` | `20m` |

### Upload Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `UPLOAD_MAX_SIZE` | Maximum file upload size | `100M` | `500M` |

## Rate Limiting Units

### Rate Units
- `r/s` - Requests per second
- `r/m` - Requests per minute  
- `r/h` - Requests per hour

### Memory Units
- `k` - Kilobytes
- `m` - Megabytes
- `g` - Gigabytes

### Examples
```bash
RATE_LIMIT_API_RATE=100r/s    # 100 requests per second
RATE_LIMIT_LOGIN_RATE=5r/m    # 5 requests per minute
RATE_LIMIT_MEMORY=50m         # 50 megabytes of memory
```

## Configuration Templates

### Development Environment
```bash
# Domain Configuration
DOMAIN=localhost
API_DOMAIN=api.localhost

# Ports (default)
HTTP_PORT=80
HTTPS_PORT=443

# Internal Services (using host.docker.internal for local development)
INTERNAL_MAIN_HOST=host.docker.internal
INTERNAL_MAIN_PORT=3000
INTERNAL_API_HOST=host.docker.internal
INTERNAL_API_PORT=3001

# Rate Limiting (relaxed for development)
RATE_LIMIT_GENERAL_RATE=20r/s
RATE_LIMIT_API_RATE=100r/s
RATE_LIMIT_LOGIN_RATE=10r/m
```

### Production Environment
```bash
# Domain Configuration
DOMAIN=example.com
API_DOMAIN=api.example.com

# Ports (standard)
HTTP_PORT=80
HTTPS_PORT=443

# Internal Services (container names or IPs)
INTERNAL_MAIN_HOST=app-server
INTERNAL_MAIN_PORT=8000
INTERNAL_API_HOST=api-server
INTERNAL_API_PORT=3000

# Rate Limiting (production values)
RATE_LIMIT_GENERAL_RATE=100r/s
RATE_LIMIT_API_RATE=500r/s
RATE_LIMIT_LOGIN_RATE=10r/m
```

### High-Traffic Environment
```bash
# Domain Configuration
DOMAIN=example.com
API_DOMAIN=api.example.com

# Internal Services
INTERNAL_MAIN_HOST=main-service
INTERNAL_MAIN_PORT=8000
INTERNAL_API_HOST=api-service
INTERNAL_API_PORT=3000

# Rate Limiting (high-volume)
RATE_LIMIT_GENERAL_RATE=1000r/s
RATE_LIMIT_GENERAL_BURST=2000
RATE_LIMIT_GENERAL_MEMORY=100m
RATE_LIMIT_API_RATE=5000r/s
RATE_LIMIT_API_BURST=10000
RATE_LIMIT_API_MEMORY=200m
RATE_LIMIT_LOGIN_RATE=50r/m
```

## Use Case Examples

### E-commerce Platform
```bash
# Optimized for product browsing and API usage
RATE_LIMIT_GENERAL_RATE=200r/s      # Product pages, search
RATE_LIMIT_API_RATE=1000r/s         # Cart, inventory API
RATE_LIMIT_LOGIN_RATE=15r/m         # Customer login
RATE_LIMIT_UPLOAD_RATE=10r/s        # Product images
UPLOAD_MAX_SIZE=50M                 # Product image size
```

### Content Management System
```bash
# Optimized for content delivery
RATE_LIMIT_GENERAL_RATE=500r/s      # Page views
RATE_LIMIT_API_RATE=100r/s          # Admin API
RATE_LIMIT_LOGIN_RATE=5r/m          # Admin login (strict)
RATE_LIMIT_UPLOAD_RATE=5r/s         # Content uploads
UPLOAD_MAX_SIZE=200M                # Media files
```

### API-First Application
```bash
# Optimized for API usage
RATE_LIMIT_GENERAL_RATE=50r/s       # Web interface
RATE_LIMIT_API_RATE=2000r/s         # Main API traffic
RATE_LIMIT_API_HEAVY_RATE=100r/s    # Database operations
RATE_LIMIT_LOGIN_RATE=20r/m         # API authentication
```

### Real-time Application
```bash
# Optimized for WebSocket usage
RATE_LIMIT_GENERAL_RATE=100r/s      # Web interface
RATE_LIMIT_API_RATE=500r/s          # REST API
RATE_LIMIT_WEBSOCKET_RATE=50r/s     # WebSocket connections
RATE_LIMIT_WEBSOCKET_BURST=100      # Connection spikes
```

## Configuration Best Practices

### Security Considerations
1. **Authentication Rate Limiting**: Always keep login rates low (5-20 requests per minute)
2. **Upload Restrictions**: Limit upload rates and file sizes appropriately
3. **Memory Allocation**: Allocate sufficient memory for tracking legitimate users
4. **Burst Values**: Set burst values to handle legitimate traffic spikes

### Performance Optimization
1. **Rate Granularity**: Use appropriate time units (seconds for high-traffic, minutes for auth)
2. **Memory Sizing**: Allocate more memory for high-traffic sites
3. **Zone Separation**: Use different zones for different endpoint types
4. **Monitoring**: Monitor rate limit hits to tune values

### Scaling Guidelines
1. **Start Conservative**: Begin with lower limits and increase based on monitoring
2. **Peak Traffic**: Set limits based on peak traffic patterns
3. **Geographic Distribution**: Consider global user distribution
4. **Service Capacity**: Ensure backend services can handle the allowed traffic

## Environment File Structure

### Recommended .env file organization:
```bash
# ===================
# DOMAIN CONFIGURATION
# ===================
DOMAIN=example.com
API_DOMAIN=api.example.com

# ===================
# NETWORK CONFIGURATION
# ===================
HTTP_PORT=80
HTTPS_PORT=443

# ===================
# SSL/TLS CONFIGURATION
# ===================
SSL_CERT_PATH=/etc/nginx/ssl/server.crt
SSL_KEY_PATH=/etc/nginx/ssl/server.key

# ===================
# INTERNAL SERVICES
# ===================
INTERNAL_MAIN_HOST=app-server
INTERNAL_MAIN_PORT=8000

INTERNAL_API_HOST=api-server
INTERNAL_API_PORT=3000

# ... continue for other services

# ===================
# RATE LIMITING
# ===================
RATE_LIMIT_GENERAL_RATE=100r/s
RATE_LIMIT_GENERAL_BURST=200
RATE_LIMIT_GENERAL_MEMORY=50m

# ... continue for other rate limits

# ===================
# UPLOAD CONFIGURATION
# ===================
UPLOAD_MAX_SIZE=100M
```

## Validation and Testing

### Environment Variable Validation
Before deployment, ensure all required variables are set:

```bash
# Required variables
DOMAIN
SSL_CERT_PATH
SSL_KEY_PATH
INTERNAL_MAIN_HOST
INTERNAL_MAIN_PORT

# Validate rate limiting values
# Ensure rates are reasonable for your traffic
# Ensure memory allocations are sufficient
```

### Testing Rate Limits
Use tools like `ab` (Apache Bench) or `wrk` to test rate limiting:

```bash
# Test general rate limiting
ab -n 1000 -c 50 https://yourdomain.com/

# Test API rate limiting  
ab -n 1000 -c 100 https://api.yourdomain.com/endpoint
```

## Troubleshooting

### Common Issues
1. **429 Too Many Requests**: Rate limits too restrictive
2. **Configuration Not Applied**: Template variables not substituted
3. **Memory Errors**: Insufficient memory allocation for rate limiting
4. **SSL Errors**: Incorrect certificate paths

### Debug Steps
1. Check environment variable values
2. Verify template substitution in generated configs
3. Monitor nginx error logs
4. Test with curl or similar tools
