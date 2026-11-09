# Construx Deployment

Docker Compose setup for the Construx stack. It runs four containers:

| Service    | Description                 |
| ---------- | --------------------------- |
| `db`       | PostgreSQL 17 (Alpine)      |
| `backend`  | Spring Boot API             |
| `dashboard`| SPA frontend (Vite)         |
| `landing`  | Marketing/landing site      |

The stack is split into a shared base file plus per-environment overlays:

- `docker-compose.yml` — base services (builds, volumes, healthchecks)
- `docker-compose.dev.yml` — development (source mounts, hot reload)
- `docker-compose.prod.yml` — production (optimized images, hardened)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the Compose plugin
- The service submodules cloned (`construx`, `construx-dashboard`, `construx-landing-page`)

```sh
git submodule update --init --recursive
```

## Configuration

Create the secrets file used by the containers (it is never baked into images):

```sh
cp docker.env.example docker.env
```

Then edit `docker.env` and fill in at least `POSTGRES_PASSWORD`, `DB_PASSWORD`, `JWT_SECRET`, and your Google OAuth credentials.

Optional build-time / port variables live in the root `.env` (`DASHBOARD_PORT`, `LANDING_PORT`, `VITE_OAUTH2_AUTHORIZATION_URL`, …).

## Development

```sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

| Service   | URL                          |
| --------- | ---------------------------- |
| Dashboard | http://app.localhost         |
| API       | http://app.localhost/api     |
| Landing   | http://localhost             |
| DB        | localhost:5433               |

nginx is the only web entry point; hosts, upstreams and its port are set in the root `.env` (see `.env.example`).

Source directories are bind-mounted, so frontend changes hot-reload. After a backend (Java) change, restart just that service:

```sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml restart backend
```

## Production

```sh
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

Before the first start, in the root `.env` (see `.env.example`):

- `LANDING_HOST` and `DASHBOARD_HOST`: your domains (e.g. `construx.app`, `app.construx.app`), with DNS records pointing at the server.
- `LETSENCRYPT_EMAIL`: account email for Let's Encrypt. Set `LETSENCRYPT_STAGING=1` for a first test run to avoid rate limits.
- Ports 80 and 443 open to the internet.

| Service   | URL                           |
| --------- | ----------------------------- |
| Dashboard | https://`DASHBOARD_HOST`      |
| API       | https://`DASHBOARD_HOST`/api  |
| Landing   | https://`LANDING_HOST`        |

The `nginx` gateway (`nginx/prod/`) is the only published service: it terminates HTTPS, redirects HTTP to HTTPS and routes by host. The `certbot` service issues one certificate for both hosts and renews it; until it is issued the gateway serves a self-signed placeholder, and it switches to the real certificate within five minutes without a restart. Register `https://DASHBOARD_HOST/login/oauth2/code/google` as an authorized redirect URI in the Google OAuth client.

## Common commands

```sh
# Stop everything
docker compose -f docker-compose.yml -f docker-compose.dev.yml down

# Rebuild a single service
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build backend

# View logs
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f

# View logs for one service
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f backend

# Remove containers and the database volume
docker compose -f docker-compose.yml -f docker-compose.dev.yml down -v
```
