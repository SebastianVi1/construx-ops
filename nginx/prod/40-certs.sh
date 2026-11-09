#!/bin/sh
# Runs from the nginx image entrypoint before nginx starts.
# nginx refuses to start without a certificate, so until certbot has issued the real one
# it serves a self-signed placeholder. A background loop switches to the issued cert and
# reloads nginx whenever certbot issues or renews it.
set -eu

live="/etc/letsencrypt/live/${NGINX_CERT_NAME}"
self=/etc/nginx/ssl/selfsigned
current=/etc/nginx/ssl/current

mkdir -p "$self"
if [ ! -f "$self/fullchain.pem" ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 30 -subj "/CN=${NGINX_LANDING_HOST}" \
        -keyout "$self/privkey.pem" -out "$self/fullchain.pem" 2>/dev/null
fi

link_cert() {
    if [ -f "$live/fullchain.pem" ]; then target="$live"; else target="$self"; fi
    ln -sfn "$target" "$current"
}

# Changes when the link target switches or certbot writes a renewed cert
fingerprint() {
    echo "$(readlink "$current") $(stat -L -c %Y "$current/fullchain.pem")"
}

link_cert
echo "$0: serving certificate from $(readlink "$current")"

(
    # A failed check or reload must not end the loop
    set +e
    last="$(fingerprint)"
    while sleep 300; do
        link_cert
        now="$(fingerprint)"
        if [ "$now" != "$last" ]; then
            echo "$0: certificate changed, reloading nginx"
            nginx -s reload
            last="$now"
        fi
    done
) &
