#!/bin/sh
set -e

# Health check for nginx gateway
DOMAIN=${DOMAIN:-localhost}

# Check if nginx is running
if ! pgrep nginx > /dev/null; then
    echo "ERROR: nginx process not found"
    exit 1
fi

# Check if nginx is responding on port 80 (HTTP redirect)
if ! curl -f -s -o /dev/null http://localhost:80/ 2>/dev/null; then
    echo "ERROR: nginx not responding on port 80"
    exit 1
fi

# Check if nginx is responding on port 443 (HTTPS)
if ! curl -f -s -k -o /dev/null https://localhost:443/ 2>/dev/null; then
    echo "ERROR: nginx not responding on port 443"
    exit 1
fi

echo "Health check passed: nginx is running and responsive"
exit 0
