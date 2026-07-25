# Swetrix on Railway

Railway template scaffolding for [Swetrix](https://github.com/Swetrix/swetrix),
an open-source, privacy-first web analytics platform (cookieless Google
Analytics alternative with error tracking and performance monitoring). The
published Railway marketplace name is **swetrix**.

Based on the official
[Swetrix selfhosting](https://github.com/swetrix/selfhosting) Compose stack.

The template runs Swetrix Community Edition as five Railway services:

- `gateway` — public nginx entrypoint (UI + API on one origin)
- `frontend` — Swetrix web UI (private)
- `api` — analytics API (private)
- `redis` — caching
- `clickhouse` — analytics and transactional data

## Railway template

Follow [`docs/railway-wiring.md`](docs/railway-wiring.md) when creating or
updating the marketplace template. It contains the exact service names,
reference variables, generated secrets, ports, healthchecks, and volume mounts.

Only the **gateway** URL should be opened in a browser. Swetrix v5 routes API
requests through `/backend/` on the same public origin.

The wrappers currently track Swetrix `v5.3.1`.

## Run locally

1. Copy `.env.example` to `.env`.
2. Replace `SECRET_KEY_BASE` and `CLICKHOUSE_PASSWORD` with random values
   (`openssl rand -base64 48` and `openssl rand -hex 32`).
3. Start the stack:

```bash
docker compose up --build
```

Open `http://localhost:8080` (gateway). Register the first account, then
further registrations stay disabled when `DISABLE_REGISTRATION=true`.

## Updating Swetrix

1. Bump the image tags in `services/frontend/Dockerfile` and
   `services/api/Dockerfile` to the new Swetrix release.
2. Diff
   [swetrix/selfhosting](https://github.com/swetrix/selfhosting) for Compose,
   nginx, or ClickHouse config changes and port them here.
3. Run `docker compose config` and smoke-test registration, dashboard load, and
   a tracking event through the gateway URL.

## License

This repository contains deployment configuration only. Swetrix Community
Edition is distributed under AGPL-3.0; see the
[upstream license](https://github.com/Swetrix/swetrix/blob/main/LICENSE).
