# DENTAPRO

DENTAPRO is a multi-tenant dental SaaS backend built with Django REST Framework and PostgreSQL.

## Project layout

- `backend/` — Django project, core domain, authentication, API, and requirements.
- `infra/` — PostgreSQL initialization, row-level security policies, and Dockerfile.
- `mobile/` — reserved for a future Flutter client.
- `admin-web/` — reserved for a future React admin client.
- `docker-compose.yml` — PostgreSQL 16, Redis, and Django services.

## Local setup

Copy `.env.example` to `.env`, set non-empty random values for `SECRET_KEY`, `POSTGRES_PASSWORD`, and `APP_DB_PASSWORD`, then run:

```sh
docker compose up --build
```

The API will be available at `http://localhost:8000`. See `README.md` for endpoint and test commands.

Docker is not available inside this Replit environment. The Compose setup is intended for a local machine or a Docker-capable host.
