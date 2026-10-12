#!/bin/bash
# ==============================================================================
# Dovecot Docker Entrypoint Script
# ==============================================================================
# Purpose:
# - Setup permissions untuk shared socket dengan Postfix
# - Verify MySQL connectivity
# - Initialize directories
# - Start Dovecot dengan proper configuration
# ==============================================================================

set -e

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Dovecot Mail Server - Starting...${NC}"
echo -e "${GREEN}=================================================${NC}"

# ==============================================================================
# FUNCTION: Log message
# ==============================================================================
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

# ==============================================================================
# STEP 1: Verify Environment Variables
# ==============================================================================
log "Step 1: Verifying environment variables..."

# Set defaults jika tidak ada
: ${VMAIL_UID:=5000}
: ${VMAIL_GID:=5000}
: ${POSTFIX_UID:=100}
: ${POSTFIX_GID:=101}
: ${MYSQL_HOST:=mariadb}
: ${MYSQL_PORT:=3306}
: ${MYSQL_DATABASE:=mx}
: ${MYSQL_USER:=dovecot}

if [ -z "$MYSQL_PASSWORD" ]; then
    warning "MYSQL_PASSWORD not set! Using default (not recommended for production)"
    MYSQL_PASSWORD="dovecot"
fi

log "vmail UID/GID: ${VMAIL_UID}:${VMAIL_GID}"
log "postfix UID/GID: ${POSTFIX_UID}:${POSTFIX_GID}"
log "MySQL: ${MYSQL_USER}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"

# ==============================================================================
# STEP 2: Create/Verify Users
# ==============================================================================
log "Step 2: Verifying user accounts..."

# Check if vmail user exists, create if not
if ! id -u vmail > /dev/null 2>&1; then
    log "Creating vmail user (UID: ${VMAIL_UID}, GID: ${VMAIL_GID})"
    groupadd -g ${VMAIL_GID} vmail || true
    useradd -u ${VMAIL_UID} -g vmail -s /usr/sbin/nologin -d /var/vmail -m vmail
else
    log "vmail user already exists"
fi

# ==============================================================================
# STEP 3: Setup Directories & Permissions
# ==============================================================================
log "Step 3: Setting up directories and permissions..."

# Virtual mail storage
if [ ! -d "/var/vmail" ]; then
    mkdir -p /var/vmail
fi
chown -R vmail:vmail /var/vmail
chmod 770 /var/vmail
log "✓ /var/vmail ready (owner: vmail:vmail, mode: 770)"

# Postfix socket directory (CRITICAL untuk SASL auth)
if [ ! -d "/var/spool/postfix/private" ]; then
    mkdir -p /var/spool/postfix/private
fi
chown ${POSTFIX_UID}:${POSTFIX_GID} /var/spool/postfix/private
chmod 750 /var/spool/postfix/private
log "✓ /var/spool/postfix/private ready (owner: ${POSTFIX_UID}:${POSTFIX_GID}, mode: 750)"

# Dovecot runtime directory
if [ ! -d "/var/run/dovecot" ]; then
    mkdir -p /var/run/dovecot
fi
chown dovecot:dovecot /var/run/dovecot
chmod 755 /var/run/dovecot

# Sieve directory
if [ ! -d "/var/lib/dovecot/sieve" ]; then
    mkdir -p /var/lib/dovecot/sieve
fi
chown -R vmail:vmail /var/lib/dovecot/sieve
chmod 755 /var/lib/dovecot/sieve

# Log directory
if [ ! -d "/var/log/dovecot" ]; then
    mkdir -p /var/log/dovecot
fi
chown dovecot:dovecot /var/log/dovecot
chmod 755 /var/log/dovecot

# ==============================================================================
# STEP 4: Test MySQL Connectivity
# ==============================================================================
log "Step 4: Testing MySQL connectivity..."

MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if mysql -h"${MYSQL_HOST}" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "USE ${MYSQL_DATABASE}; SELECT 1;" > /dev/null 2>&1; then
        log "✓ MySQL connection successful"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            error "Failed to connect to MySQL after ${MAX_RETRIES} attempts"
            error "Host: ${MYSQL_HOST}:${MYSQL_PORT}, Database: ${MYSQL_DATABASE}, User: ${MYSQL_USER}"
            exit 1
        fi
        warning "MySQL not ready yet, waiting... (attempt ${RETRY_COUNT}/${MAX_RETRIES})"
        sleep 2
    fi
done

# ==============================================================================
# STEP 5: Update MySQL Connection Config (if using env vars)
# ==============================================================================
log "Step 5: Updating MySQL configuration..."

if [ -f "/etc/dovecot/mysql/dovecot-mysql.conf" ]; then
    # Update connection parameters dari environment variables
    sed -i "s/^connect = .*/connect = host=${MYSQL_HOST} port=${MYSQL_PORT} dbname=${MYSQL_DATABASE} user=${MYSQL_USER} password=${MYSQL_PASSWORD}/" \
        /etc/dovecot/mysql/dovecot-mysql.conf 2>/dev/null || true
    
    log "✓ MySQL config updated"
else
    warning "MySQL config file not found at /etc/dovecot/mysql/dovecot-mysql.conf"
fi

# ==============================================================================
# STEP 6: Verify Dovecot Configuration
# ==============================================================================
log "Step 6: Verifying Dovecot configuration..."

if doveconf > /dev/null 2>&1; then
    log "✓ Dovecot configuration is valid"
else
    error "Dovecot configuration has errors!"
    error "Running: doveconf to show errors..."
    doveconf
    exit 1
fi

# ==============================================================================
# STEP 7: Display Important Information
# ==============================================================================
log "Step 7: Configuration summary..."

echo ""
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}  Dovecot Configuration Summary${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e "Mail Storage:      ${GREEN}/var/vmail${NC}"
echo -e "Postfix Socket:    ${GREEN}/var/spool/postfix/private/auth${NC}"
echo -e "MySQL Database:    ${GREEN}${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}${NC}"
echo -e "vmail User:        ${GREEN}${VMAIL_UID}:${VMAIL_GID}${NC}"
echo -e "Protocols:         ${GREEN}IMAP, POP3, LMTP, ManageSieve${NC}"
echo -e "Ports:             ${GREEN}143 (IMAP), 993 (IMAPS), 110 (POP3), 995 (POP3S), 24 (LMTP), 4190 (Sieve)${NC}"
echo -e "${GREEN}=================================================${NC}"
echo ""

# ==============================================================================
# STEP 8: Start Dovecot
# ==============================================================================
log "Step 8: Starting Dovecot..."

# Execute the CMD (dovecot -F)
exec "$@"
