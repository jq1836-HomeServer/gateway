#!/bin/sh
set -e

echo "Validating environment variables..."

# Check required variables
REQUIRED_VARS="DOMAIN INTERNAL_MAIN_HOST INTERNAL_MAIN_PORT"
for var in $REQUIRED_VARS; do
    eval value=\$$var
    if [ -z "$value" ]; then
        echo "ERROR: Required environment variable $var is not set"
        exit 1
    fi
done

# Validate rate limiting format
validate_rate() {
    local rate=$1
    local name=$2
    echo "Checking rate limiting variable $name: '$rate'"
    if [ -n "$rate" ] && ! echo "$rate" | grep -qE '^[0-9]+r/[smh]$'; then
        echo "ERROR: Invalid rate format for $name: $rate (expected format: NUMBERr/s|m|h)"
        exit 1
    fi
}

# Validate rate limiting variables if set
validate_rate "$RATE_LIMIT_GENERAL_RATE" "RATE_LIMIT_GENERAL_RATE"
validate_rate "$RATE_LIMIT_API_RATE" "RATE_LIMIT_API_RATE"
validate_rate "$RATE_LIMIT_LOGIN_RATE" "RATE_LIMIT_LOGIN_RATE"

echo "Environment validation completed successfully"
