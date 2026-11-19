# Runtime y despliegue

↑ [[INDEX]]

## Dev
`docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build`
- nginx es la única entrada web (:80): `app.localhost` → dashboard + `/api` + `/oauth2`; `localhost` → landing.
- Postgres en `127.0.0.1:5433`. Tras cambios Java: `restart backend`.
- Plantilla nginx: `nginx/dev/`.

## Prod
`docker-compose.prod.yml`: nginx en :80/:443 con HTTPS de Let's Encrypt (servicio `certbot`), plantilla `nginx/prod/`.
Requiere `LANDING_HOST`, `DASHBOARD_HOST`, `LETSENCRYPT_EMAIL` en `.env`.

## Configuración
- `.env` (puertos, hosts, vars de build) ← `.env.example`
- `docker.env` (secretos) ← `docker.env.example`
