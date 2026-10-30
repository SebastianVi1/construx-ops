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
| Dashboard | http://localhost:5173        |
| Landing   | http://localhost:4321        |
| API       | http://localhost:8080        |
| DB        | localhost:5433               |

Source directories are bind-mounted, so frontend changes hot-reload. After a backend (Java) change, restart just that service:

```sh
docker compose -f docker-compose.yml -f docker-compose.dev.yml restart backend
```

## Production

```sh
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

| Service   | URL                          |
| --------- | ---------------------------- |
| Dashboard | http://localhost:8081        |
| Landing   | http://localhost:8082        |

The `db` and `backend` services are not published to the host — the dashboard proxies `/api` and OAuth routes internally. Put a TLS-terminating reverse proxy in front of the published ports (auth cookies require HTTPS outside localhost).

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
