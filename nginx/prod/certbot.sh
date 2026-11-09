#!/bin/sh
# Issues one certificate for both hosts over the HTTP-01 webroot served by the nginx gateway,
# then keeps it renewed. nginx picks up new files on its own (see 40-certs.sh).
set -u

: "${CERT_NAME:?}" "${LANDING_HOST:?}" "${DASHBOARD_HOST:?}" "${LETSENCRYPT_EMAIL:?set LETSENCRYPT_EMAIL in the root .env}"

staging=""
# Test the setup without hitting Let's Encrypt production rate limits
[ "${LETSENCRYPT_STAGING:-0}" = "1" ] && staging="--staging"

while :; do
    # Issues when missing, renews when close to expiry, and updates the names if the hosts changed
    if certbot certonly --webroot -w /var/www/certbot \
        --cert-name "$CERT_NAME" -d "$LANDING_HOST" -d "$DASHBOARD_HOST" \
        --email "$LETSENCRYPT_EMAIL" --agree-tos --no-eff-email \
        --non-interactive --keep-until-expiring $staging; then
        sleep 43200
    else
        # Usually DNS or port 80 not reachable yet; retry slowly to stay under rate limits
        sleep 900
    fi
done
