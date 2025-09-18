# Multi-stage Dockerfile for Nginx Reverse Proxy Gateway
FROM nginx:1.28.0-alpine as base

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
    && mkdir -p /docker-entrypoint.d \
    && rm -f /etc/nginx/conf.d/default.conf

# Copy nginx configuration files
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/conf.d/*.template /etc/nginx/templates/

# Copy entrypoint scripts
COPY docker-entrypoint.d/ /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/*.sh

# Copy health check script
COPY scripts/healthcheck.sh /usr/local/bin/healthcheck.sh
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
    RATE_LIMIT_WEBSOCKET_RATE=5r/s \
    RATE_LIMIT_WEBSOCKET_BURST=3 \
    RATE_LIMIT_WEBSOCKET_MEMORY=10m \
    RATE_LIMIT_UPLOAD_RATE=2r/s \
    RATE_LIMIT_UPLOAD_BURST=1 \
    RATE_LIMIT_UPLOAD_MEMORY=10m \
    UPLOAD_MAX_SIZE=100M \
    INTERNAL_UPLOAD_HOST=host.docker.internal \
    INTERNAL_UPLOAD_PORT=8000

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
