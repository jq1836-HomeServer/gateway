#!/bin/sh
set -e

# Only generate certificates if they don't exist
if [ ! -f "${SSL_CERT_PATH:-/etc/nginx/ssl/server.crt}" ] || [ ! -f "${SSL_KEY_PATH:-/etc/nginx/ssl/server.key}" ]; then
    echo "SSL certificates not found, generating self-signed certificates..."
    
    # Set default paths if not provided
    CERT_PATH=${SSL_CERT_PATH:-/etc/nginx/ssl/server.crt}
    KEY_PATH=${SSL_KEY_PATH:-/etc/nginx/ssl/server.key}
    DOMAIN_NAME=${DOMAIN:-localhost}
    
    # Create SSL directory if it doesn't exist
    mkdir -p "$(dirname "$CERT_PATH")"
    mkdir -p "$(dirname "$KEY_PATH")"
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN_NAME"
    
    # Set appropriate permissions
    chmod 600 "$KEY_PATH"
    chmod 644 "$CERT_PATH"
    
    echo "Self-signed SSL certificate generated for $DOMAIN_NAME"
else
    echo "SSL certificates found, skipping generation"
fi
