# Production gateway: TLS termination and host-based routing in front of the app containers
FROM nginx:1.29-alpine

# openssl creates the self-signed placeholder used until Let's Encrypt issues the real certificate
RUN apk add --no-cache openssl \
    && mkdir -p /var/www/certbot /etc/nginx/ssl

COPY templates/ /etc/nginx/templates/
COPY tls.conf /etc/nginx/tls.conf
# Keeps its executable bit from git; COPY --chmod would require BuildKit
COPY 40-certs.sh /docker-entrypoint.d/40-certs.sh

EXPOSE 80 443
