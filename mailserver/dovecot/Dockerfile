# ==============================================================================
# DOVECOT DOCKERFILE - Best Practice untuk Production Mail Server
# ==============================================================================
# Base: Debian (stable & well-supported)
# Features:
# - LMTP delivery integration dengan Postfix
# - MySQL virtual users
# - Maildir storage format
# - Quota support untuk ISPConfig
# - SASL authentication untuk Postfix
# - Sieve filtering support
# ==============================================================================

FROM debian:bookworm-slim

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

ENV DEBIAN_FRONTEND=noninteractive \
    DOVECOT_VERSION=2.3 \
    VMAIL_UID=5000 \
    VMAIL_GID=5000 \
    POSTFIX_UID=100 \
    POSTFIX_GID=101

# ==============================================================================
# INSTALL PACKAGES
# ==============================================================================

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Core Dovecot packages
        dovecot-core \
        dovecot-imapd \
        dovecot-pop3d \
        dovecot-lmtpd \
        dovecot-managesieved \
        dovecot-sieve \
        \
        # MySQL support (CRITICAL untuk virtual users)
        dovecot-mysql \
        \
        # Additional utilities
        dovecot-antispam \
        ca-certificates \
        openssl \
        netcat-openbsd \
        procps \
        telnet \
        iputils-ping \
        net-tools \
        \
        # MySQL client untuk testing
        default-mysql-client \
    && \
    # Cleanup untuk minimize image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ==============================================================================
# CREATE USERS & GROUPS
# ==============================================================================

# Create vmail user untuk virtual mailbox ownership
# UID/GID 5000 adalah standar untuk virtual mail users
RUN groupadd -g ${VMAIL_GID} vmail && \
    useradd -u ${VMAIL_UID} -g vmail -s /usr/sbin/nologin -d /var/vmail -m vmail

# Create dovenull user (Dovecot internal unprivileged user)
RUN groupadd -g 65534 dovenull 2>/dev/null || true && \
    useradd -u 65534 -g dovenull -s /usr/sbin/nologin -d /nonexistent dovenull 2>/dev/null || true

RUN groupadd --non-unique -g ${POSTFIX_GID} postfix || true && \
    useradd  --non-unique -u ${POSTFIX_UID} -g postfix -s /usr/sbin/nologin -d /nonexistent postfix || true


# ==============================================================================
# CREATE DIRECTORY STRUCTURE
# ==============================================================================

# Virtual mail storage directory
RUN mkdir -p /var/vmail && \
    chown -R vmail:vmail /var/vmail && \
    chmod 770 /var/vmail

# Dovecot runtime directories
RUN mkdir -p /var/run/dovecot && \
    chown dovecot:dovecot /var/run/dovecot && \
    chmod 755 /var/run/dovecot

# Sieve scripts directory
RUN mkdir -p /var/lib/dovecot/sieve && \
    chown -R vmail:vmail /var/lib/dovecot/sieve && \
    chmod 755 /var/lib/dovecot/sieve

# Log directory
RUN mkdir -p /var/log/dovecot && \
    chown dovecot:dovecot /var/log/dovecot && \
    chmod 755 /var/log/dovecot

# Postfix integration directory (untuk SASL auth socket)
# CRITICAL: Permission harus match dengan Postfix container
RUN mkdir -p /var/spool/postfix/private && \
    chown ${POSTFIX_UID}:${POSTFIX_GID} /var/spool/postfix/private && \
    chmod 750 /var/spool/postfix/private

# Config directory
RUN mkdir -p /etc/dovecot/conf.d /etc/dovecot/mysql

# ==============================================================================
# DOVECOT CONFIGURATION FILES
# ==============================================================================

# Main configuration (akan di-override via volume mount)
# Ini adalah default fallback jika tidak ada external config
COPY ./dovecot.conf /etc/dovecot/dovecot.conf
#COPY conf.d/* /etc/dovecot/conf.d/
COPY mysql/* /etc/dovecot/mysql/
COPY protocols.d/* /etc/dovecot/protocols.d/

# Set permissions untuk config files
RUN chown -R root:root /etc/dovecot && \
    chmod 644 /etc/dovecot/dovecot.conf && \
    chmod 644 /etc/dovecot/conf.d/* && \
    chmod 755 /etc/dovecot/protocols.d && \
    chmod 644 /etc/dovecot/protocols.d/* && \
    chmod 640 /etc/dovecot/mysql/* && \
    chown dovecot:dovecot /etc/dovecot/mysql/*

# ==============================================================================
# SSL/TLS CERTIFICATES
# ==============================================================================

# SSL directory (akan di-mount dari Let's Encrypt via volume)
RUN mkdir -p /etc/dovecot/ssl && \
    chmod 755 /etc/dovecot/ssl

# Generate self-signed certificate sebagai fallback
# Production akan pakai Let's Encrypt via volume mount
RUN openssl req -new -x509 -days 3650 -nodes \
    -out /etc/dovecot/ssl/dovecot.pem \
    -keyout /etc/dovecot/ssl/dovecot.key \
    -subj "/C=ID/ST=EastKalimantan/L=Balikpapan/O=Tamvan/CN=mx0.tamvan.net" && \
    chmod 644 /etc/dovecot/ssl/dovecot.pem && \
    chmod 600 /etc/dovecot/ssl/dovecot.key

# ==============================================================================
# HEALTHCHECK
# ==============================================================================

# Healthcheck untuk Docker
# Check jika Dovecot masih responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD nc -z localhost 143 || exit 1

# ==============================================================================
# VOLUMES
# ==============================================================================

# Expose volumes untuk external mounting
VOLUME ["/var/vmail", "/var/spool/postfix/private", "/etc/dovecot", "/var/log/dovecot"]

# ==============================================================================
# EXPOSE PORTS
# ==============================================================================

# IMAP (143), IMAPS (993), POP3 (110), POP3S (995)
# LMTP (24), ManageSieve (4190)
EXPOSE 143 993 110 995 24 4190

# ==============================================================================
# ENTRYPOINT SCRIPT
# ==============================================================================

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command: Start Dovecot in foreground
CMD ["/usr/sbin/dovecot", "-F"]
