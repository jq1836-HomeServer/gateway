# Multi-stage Dockerfile for Nginx Reverse Proxy Gateway
FROM nginx:alpine as base

# Install necessary packages for SSL and template processing
RUN apk add --no-cache \
    openssl \
    envsubst \
    curl \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /etc/nginx/ssl \
    && mkdir -p /etc/nginx/templates \
    && mkdir -p /var/log/nginx \
    && mkdir -p /docker-entrypoint.d

# Copy nginx configuration files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/*.template /etc/nginx/templates/

# Create a script to generate self-signed certificates if they don't exist
COPY <<EOF /docker-entrypoint.d/10-generate-ssl.sh
#!/bin/sh
set -e

# Only generate certificates if they don't exist
if [ ! -f "\${SSL_CERT_PATH:-/etc/nginx/ssl/server.crt}" ] || [ ! -f "\${SSL_KEY_PATH:-/etc/nginx/ssl/server.key}" ]; then
    echo "SSL certificates not found, generating self-signed certificates..."
    
    # Set default paths if not provided
    CERT_PATH=\${SSL_CERT_PATH:-/etc/nginx/ssl/server.crt}
    KEY_PATH=\${SSL_KEY_PATH:-/etc/nginx/ssl/server.key}
    DOMAIN_NAME=\${DOMAIN:-localhost}
    
    # Create SSL directory if it doesn't exist
    mkdir -p "\$(dirname "\$CERT_PATH")"
    mkdir -p "\$(dirname "\$KEY_PATH")"
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "\$KEY_PATH" \
        -out "\$CERT_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=\$DOMAIN_NAME"
    
    # Set appropriate permissions
    chmod 600 "\$KEY_PATH"
    chmod 644 "\$CERT_PATH"
    
    echo "Self-signed SSL certificate generated for \$DOMAIN_NAME"
else
    echo "SSL certificates found, skipping generation"
fi
EOF

# Make the SSL generation script executable
RUN chmod +x /docker-entrypoint.d/10-generate-ssl.sh

# Create a script to validate environment variables
COPY <<EOF /docker-entrypoint.d/20-validate-env.sh
#!/bin/sh
set -e

echo "Validating environment variables..."

# Check required variables
REQUIRED_VARS="DOMAIN INTERNAL_MAIN_HOST INTERNAL_MAIN_PORT"
for var in \$REQUIRED_VARS; do
    eval value=\\\$\$var
    if [ -z "\$value" ]; then
        echo "ERROR: Required environment variable \$var is not set"
        exit 1
    fi
done

# Validate rate limiting format
validate_rate() {
    local rate=\$1
    local name=\$2
    if [ -n "\$rate" ] && ! echo "\$rate" | grep -qE '^[0-9]+r/[smh]\$'; then
        echo "ERROR: Invalid rate format for \$name: \$rate (expected format: NUMBERr/s|m|h)"
        exit 1
    fi
}

# Validate rate limiting variables if set
validate_rate "\$RATE_LIMIT_GENERAL_RATE" "RATE_LIMIT_GENERAL_RATE"
validate_rate "\$RATE_LIMIT_API_RATE" "RATE_LIMIT_API_RATE"
validate_rate "\$RATE_LIMIT_LOGIN_RATE" "RATE_LIMIT_LOGIN_RATE"

echo "Environment validation completed successfully"
EOF

# Make the validation script executable
RUN chmod +x /docker-entrypoint.d/20-validate-env.sh

# Create a health check script
COPY <<EOF /usr/local/bin/healthcheck.sh
#!/bin/sh
set -e

# Check if nginx is running
if ! pgrep nginx > /dev/null; then
    echo "Nginx is not running"
    exit 1
fi

# Check if nginx configuration is valid
if ! nginx -t 2>/dev/null; then
    echo "Nginx configuration is invalid"
    exit 1
fi

# Check SSL certificate validity (if exists)
CERT_PATH=\${SSL_CERT_PATH:-/etc/nginx/ssl/server.crt}
if [ -f "\$CERT_PATH" ]; then
    if ! openssl x509 -in "\$CERT_PATH" -noout -checkend 86400 2>/dev/null; then
        echo "SSL certificate expires within 24 hours"
        exit 1
    fi
fi

# Test HTTP redirect (port 80 should redirect to HTTPS)
if ! curl -sf -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "301"; then
    echo "HTTP to HTTPS redirect not working"
    exit 1
fi

echo "Health check passed"
exit 0
EOF

# Make the health check script executable
RUN chmod +x /usr/local/bin/healthcheck.sh

# Set default environment variables
ENV DOMAIN=localhost \
    API_DOMAIN=api.localhost \
    HTTP_PORT=80 \
    HTTPS_PORT=443 \
    INTERNAL_MAIN_HOST=host.docker.internal \
    INTERNAL_MAIN_PORT=8000 \
    INTERNAL_APP_HOST=host.docker.internal \
    INTERNAL_APP_PORT=8080 \
    INTERNAL_API_HOST=host.docker.internal \
    INTERNAL_API_PORT=3000 \
    INTERNAL_AUTH_HOST=host.docker.internal \
    INTERNAL_AUTH_PORT=8081 \
    INTERNAL_WEBSOCKET_HOST=host.docker.internal \
    INTERNAL_WEBSOCKET_PORT=8082 \
    SSL_CERT_PATH=/etc/nginx/ssl/server.crt \
    SSL_KEY_PATH=/etc/nginx/ssl/server.key \
    RATE_LIMIT_GENERAL_RATE=10r/s \
    RATE_LIMIT_GENERAL_BURST=20 \
    RATE_LIMIT_GENERAL_MEMORY=10m \
    RATE_LIMIT_API_RATE=50r/s \
    RATE_LIMIT_API_BURST=50 \
    RATE_LIMIT_API_MEMORY=10m \
    RATE_LIMIT_LOGIN_RATE=5r/m \
    RATE_LIMIT_LOGIN_BURST=5 \
    RATE_LIMIT_LOGIN_MEMORY=10m \
    RATE_LIMIT_API_HEAVY_RATE=20r/s \
    RATE_LIMIT_API_HEAVY_BURST=10 \
    RATE_LIMIT_API_HEAVY_MEMORY=10m \
    RATE_LIMIT_WEBSOCKET_RATE=5r/s \
    RATE_LIMIT_WEBSOCKET_BURST=3 \
    RATE_LIMIT_WEBSOCKET_MEMORY=10m \
    RATE_LIMIT_UPLOAD_RATE=2r/s \
    RATE_LIMIT_UPLOAD_BURST=1 \
    RATE_LIMIT_UPLOAD_MEMORY=10m \
    UPLOAD_MAX_SIZE=100M

# Expose ports
EXPOSE 80 443

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh

# Use the default nginx entrypoint which handles template substitution
CMD ["nginx", "-g", "daemon off;"]

# Labels for better container management
LABEL org.opencontainers.image.title="Nginx Reverse Proxy Gateway" \
      org.opencontainers.image.description="HTTPS-to-HTTP reverse proxy with configurable rate limiting" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.vendor="Custom" \
      org.opencontainers.image.licenses="MIT"
