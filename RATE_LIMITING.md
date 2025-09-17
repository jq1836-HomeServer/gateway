# Rate Limiting Configuration Guide

This guide explains how to configure rate limiting for your nginx reverse proxy gateway using environment variables.

## Overview

Rate limiting helps protect your services from abuse, DDoS attacks, and excessive load. The gateway supports multiple rate limiting zones with different configurations for different types of endpoints.

## Rate Limiting Zones

### 1. General Zone (`general`)
- **Purpose**: Most web traffic, static content, regular pages
- **Default**: `10r/s` with burst of `20`
- **Used by**: Main application endpoints, static files

### 2. API Zone (`api`)
- **Purpose**: API endpoints with higher throughput needs
- **Default**: `50r/s` with burst of `50`
- **Used by**: REST API calls, data endpoints

### 3. Login Zone (`login`)
- **Purpose**: Authentication endpoints (strict security)
- **Default**: `5r/m` with burst of `5`
- **Used by**: Login, password reset, registration

### 4. Heavy API Zone (`api_heavy`)
- **Purpose**: Resource-intensive API operations
- **Default**: `20r/s` with burst of `10`
- **Used by**: Database queries, file processing, reports

### 5. WebSocket Zone (`websocket`)
- **Purpose**: WebSocket connection establishment
- **Default**: `5r/s` with burst of `3`
- **Used by**: WebSocket upgrade requests

### 6. Upload Zone (`upload`)
- **Purpose**: File upload endpoints (very strict)
- **Default**: `2r/s` with burst of `1`
- **Used by**: File upload, image upload, document upload

## Configuration Variables

### Rate Configuration
```bash
# Format: <number>r/<time_unit>
# time_unit: s (second), m (minute), h (hour)
RATE_LIMIT_GENERAL_RATE=10r/s
RATE_LIMIT_API_RATE=50r/s
RATE_LIMIT_LOGIN_RATE=5r/m
```

### Burst Configuration
```bash
# Number of requests that can exceed the rate temporarily
RATE_LIMIT_GENERAL_BURST=20
RATE_LIMIT_API_BURST=50
RATE_LIMIT_LOGIN_BURST=5
```

### Memory Configuration
```bash
# Memory allocated for tracking clients
# Format: <number><unit> where unit is k, m, g
RATE_LIMIT_GENERAL_MEMORY=10m
RATE_LIMIT_API_MEMORY=10m
RATE_LIMIT_LOGIN_MEMORY=10m
```

## Environment Profiles

### Development Profile
```bash
# Relaxed limits for development
RATE_LIMIT_GENERAL_RATE=10r/s
RATE_LIMIT_API_RATE=50r/s
RATE_LIMIT_LOGIN_RATE=5r/m
```

### Production Profile
```bash
# Higher limits for production traffic
RATE_LIMIT_GENERAL_RATE=100r/s
RATE_LIMIT_API_RATE=500r/s
RATE_LIMIT_LOGIN_RATE=10r/m
```

### High-Traffic Profile
```bash
# Very high limits for enterprise usage
RATE_LIMIT_GENERAL_RATE=1000r/s
RATE_LIMIT_API_RATE=5000r/s
RATE_LIMIT_LOGIN_RATE=50r/m
```

## Usage Examples

### Basic Configuration
```bash
# Copy appropriate template
cp .env.example .env

# Edit the rate limiting section
RATE_LIMIT_GENERAL_RATE=20r/s
RATE_LIMIT_GENERAL_BURST=40
RATE_LIMIT_API_RATE=100r/s
RATE_LIMIT_API_BURST=200
```

### Using Configuration Script
```powershell
# Development setup
.\configure.ps1 -Profile development -Domain "dev.example.com"

# Production setup  
.\configure.ps1 -Profile production -Domain "example.com" -Interactive
```

### Custom Rate Limits
```bash
# E-commerce site example
RATE_LIMIT_GENERAL_RATE=50r/s      # Product pages
RATE_LIMIT_API_RATE=200r/s         # Search, cart API
RATE_LIMIT_LOGIN_RATE=3r/m         # Strict login protection
RATE_LIMIT_UPLOAD_RATE=1r/s        # Product image uploads
```

## Advanced Configuration

### Per-Location Rate Limiting
Add custom rate limiting to specific locations in `default.conf.template`:

```nginx
# Heavy API operations
location /api/reports/ {
    limit_req zone=api_heavy burst=${RATE_LIMIT_API_HEAVY_BURST:-10} nodelay;
    proxy_pass http://${INTERNAL_API_HOST}:${INTERNAL_API_PORT}/reports/;
}

# Public API (more restrictive)
location /api/public/ {
    limit_req zone=general burst=5 nodelay;
    proxy_pass http://${INTERNAL_API_HOST}:${INTERNAL_API_PORT}/public/;
}
```

### Multiple Rate Limits
Apply multiple rate limiting zones to the same location:

```nginx
location /api/sensitive/ {
    # Apply both general and login rate limits
    limit_req zone=general burst=10 nodelay;
    limit_req zone=login burst=3 nodelay;
    proxy_pass http://${INTERNAL_API_HOST}:${INTERNAL_API_PORT}/sensitive/;
}
```

### Custom Memory Allocation
Adjust memory based on expected traffic:

```bash
# High-traffic site with many unique IPs
RATE_LIMIT_GENERAL_MEMORY=100m
RATE_LIMIT_API_MEMORY=200m

# Small site with limited traffic
RATE_LIMIT_GENERAL_MEMORY=5m
RATE_LIMIT_API_MEMORY=5m
```

## Monitoring and Tuning

### Log Analysis
Check nginx logs for rate limiting events:
```bash
# View rate limit denials
docker-compose logs nginx | grep "limiting requests"

# Monitor specific endpoints
docker-compose logs nginx | grep "/api/" | grep "limiting"
```

### Tuning Guidelines

1. **Start Conservative**: Begin with lower limits and increase as needed
2. **Monitor Legitimate Traffic**: Ensure real users aren't being blocked
3. **Adjust Burst Values**: Allow for natural traffic spikes
4. **Consider Peak Hours**: Set limits based on peak traffic patterns

### Common Patterns

```bash
# Blog/Content Site
RATE_LIMIT_GENERAL_RATE=30r/s
RATE_LIMIT_API_RATE=10r/s
RATE_LIMIT_LOGIN_RATE=2r/m

# API-Heavy Application
RATE_LIMIT_GENERAL_RATE=20r/s
RATE_LIMIT_API_RATE=200r/s
RATE_LIMIT_LOGIN_RATE=5r/m

# E-commerce Platform
RATE_LIMIT_GENERAL_RATE=100r/s
RATE_LIMIT_API_RATE=500r/s
RATE_LIMIT_LOGIN_RATE=10r/m
RATE_LIMIT_UPLOAD_RATE=5r/s
```

## Troubleshooting

### Rate Limit Errors (429 Too Many Requests)
1. Check if limits are too restrictive
2. Increase burst values for traffic spikes
3. Consider separating different endpoint types
4. Monitor for legitimate vs. malicious traffic

### Memory Issues
1. Reduce memory allocation if nginx fails to start
2. Increase memory for high-traffic sites
3. Monitor memory usage: `docker stats gateway-nginx`

### Configuration Not Applied
1. Ensure environment variables are set correctly
2. Restart the container: `docker-compose restart nginx`
3. Check template generation: `docker-compose logs nginx`
