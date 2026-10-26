# DENTAPRO-APP
SaaS odontológico — Fase 1: Fundación y seguridad

Backend SaaS odontológico con Django 5, Django REST Framework, JWT y PostgreSQL 16. Los directorios `mobile/` y `admin-web/` quedan como esqueletos vacíos para fases posteriores.

## Requisitos para ejecutar

- Docker Engine con Docker Compose
- Copiar `.env.example` a `.env` y configurar valores aleatorios para `SECRET_KEY`, `POSTGRES_PASSWORD` y `APP_DB_PASSWORD`

## Levantar el proyecto

Desde la raíz:

```sh
cp .env.example .env
# Edita .env y reemplaza los valores marcados como obligatorios.
docker compose up --build
```

Docker Compose levanta PostgreSQL 16, Redis y Django. Django aplica las migraciones y la política RLS antes de iniciar el servidor.

## Probar el endpoint público de branding

```sh
curl "http://localhost:8000/api/v1/tenant/branding/?slug=clinica-demo"
```

Si el slug no existe, devuelve el branding predeterminado. Para iniciar sesión y obtener JWT:

```sh
curl -X POST "http://localhost:8000/api/v1/auth/token/" \
  -H "Content-Type: application/json" \
  -d '{"email":"usuario@example.com","password":"tu-contrasena","tenant_id":"UUID-DE-TU-TENANT"}'
```

El access token vence en 15 minutos. Los mensajes de error de la API están en español.

## Seguridad de base de datos

- `infra/init.sql` habilita `uuid-ossp` y `pgcrypto`.
- La aplicación se conecta como un rol PostgreSQL sin privilegios de superusuario.
- `infra/rls_policies.sql` activa RLS y restringe `usuario` al tenant configurado en `app.current_tenant`.
- El middleware establece el tenant a partir del JWT firmado; el endpoint de inicio de sesión exige `tenant_id`.

## Replit

Replit no ejecuta Docker en este workspace. El Compose y Dockerfile están preparados para ejecutarse fuera de Replit; dentro de Replit se puede ejecutar `python manage.py check` cuando las dependencias estén instaladas.
