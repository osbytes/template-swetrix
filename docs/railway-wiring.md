# Railway template wiring

Publish this as a Railway template named `swetrix` (not `template-swetrix`).

Railway does not deploy `docker-compose.yml` directly. Recreate its topology in
the template composer with services named exactly `gateway`, `frontend`, `api`,
`redis`, and `clickhouse`.

Swetrix v5 routes API traffic through the web entrypoint (`/backend/`). **Only
`gateway` should be public** so the UI and API share one origin.

The wrappers track Swetrix `v5.3.1` (`swetrix/swetrix-fe` and
`swetrix/swetrix-api`).

## Application services

Use `https://github.com/osbytes/template-swetrix` as the **GitHub source only for
`gateway`, `frontend`, and `api`**. Do not point `redis` or `clickhouse` at the
repo — those are Docker Image services (see below). If a data service is wired
to the repo root, Railpack tries to build the whole monorepo and fails.

Set each app service's root directory as shown; its local `railway.toml` sets
the Dockerfile and healthcheck.

### gateway

- Root directory: `/services/gateway`
- Public networking: enabled (this is the only URL users open)
- Variables:

```text
PORT=8080
API_UPSTREAM=${{api.RAILWAY_PRIVATE_DOMAIN}}:5005
FRONTEND_UPSTREAM=${{frontend.RAILWAY_PRIVATE_DOMAIN}}:3000
```

Use `host:port` only (no `http://`). Keep the public domain target port at
`8080`.

### frontend

- Root directory: `/services/frontend`
- Public networking: **disabled** (reached only via gateway)
- Variables:

```text
PORT=3000
BASE_URL=https://${{gateway.RAILWAY_PUBLIC_DOMAIN}}
API_ORIGIN=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:5005
```

`BASE_URL` must be the public gateway URL (no trailing slash). Browser clients
call `${BASE_URL}/backend`. Server-side rendering uses `API_ORIGIN` over the
private network.

### api

- Root directory: `/services/api`
- Public networking: **disabled** (reached only via gateway)
- Recommended memory: at least 2 GB
- Variables:

```text
PORT=5005
SECRET_KEY_BASE=${{secret(64)}}
BASE_URL=https://${{gateway.RAILWAY_PUBLIC_DOMAIN}}
DISABLE_REGISTRATION=true
DEBUG_MODE=false
IP_GEOLOCATION_DB_PATH=
CLIENT_IP_HEADER=x-forwarded-for
IS_PRIMARY_NODE=true
REDIS_HOST=${{redis.RAILWAY_PRIVATE_DOMAIN}}
REDIS_PORT=6379
REDIS_USER=default
REDIS_PASSWORD=
CLICKHOUSE_HOST=http://${{clickhouse.RAILWAY_PRIVATE_DOMAIN}}
CLICKHOUSE_USER=default
CLICKHOUSE_PORT=8123
CLICKHOUSE_DATABASE=analytics
CLICKHOUSE_PASSWORD=${{clickhouse.CLICKHOUSE_PASSWORD}}
SMTP_MOCK=true
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASSWORD=
FROM_EMAIL=
OIDC_ENABLED=false
OIDC_ONLY_AUTH=false
OIDC_DISCOVERY_URL=
OIDC_CLIENT_ID=
OIDC_CLIENT_SECRET=
OIDC_PROMPT=select_account
```

Expose optional SMTP variables to deployers who want real transactional email
(password reset, project invites). Leave `SMTP_MOCK=true` until SMTP is
configured. Optional Google / OIDC integrations are documented upstream:
https://docs.swetrix.com/selfhosting/configuring

The wrapper entrypoint blocks on `${CLICKHOUSE_HOST}:${CLICKHOUSE_PORT}/ping`
before running Swetrix's `clickhouse:initialise`. Railway has no
`depends_on: service_healthy`, and upstream's init script swallows connection
errors and exits 0, so without the wait the API boots against an empty database.
Tune with optional `CLICKHOUSE_WAIT_ATTEMPTS` (default 60) and
`CLICKHOUSE_WAIT_INTERVAL` (default 5 seconds).

## Data services

### redis

- Image: `redis:8.6-alpine`
- Public networking: disabled
- No volume required for CE caching
- Variables: none required (matches upstream `configure.sh`, which leaves
  `REDIS_PASSWORD` empty)

### clickhouse

- **Source type: Docker Image** (not GitHub) —
  `clickhouse/clickhouse-server:25.8-alpine`
- Public networking: disabled
- Volume: mount at `/var/lib/clickhouse`
- Recommended memory: at least 2 GB
- Variables:

```text
PORT=8123
CLICKHOUSE_DB=analytics
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=${{secret(32, "abcdef0123456789")}}
```

The HTTP interface listens on `8123` (`/ping` healthcheck). Native protocol
port `9000` stays private inside the container.

Local Compose still builds `services/clickhouse` so the upstream Swetrix
RAM/log tuning XMLs are included. On Railway those tunings are optional; the
stock image is enough for the template.

## Auth notes

- Open the **gateway** URL only.
- With `DISABLE_REGISTRATION=true`, the first account can still register; later
  sign-ups are blocked.
- After creating your admin account you are done — no separate seed step.

## Deployment notes

- Keep all five services in one Railway environment so reference variables and
  private DNS resolve correctly.
- Gateway, frontend, and api must exist before their reference variables
  resolve.
- `BASE_URL` on both frontend and api must match the public gateway HTTPS URL
  exactly (needed for OAuth redirect URIs if you enable Google/OIDC later).
- ClickHouse migrations run inside the API image on startup for Community
  Edition; wait for `/ping` before expecting analytics writes to succeed.
- At least ~2 GB RAM is recommended for the whole stack (upstream self-hosting
  guidance).

## Troubleshooting

### `UNKNOWN_TABLE: Unknown table expression identifier 'user'`

Swetrix's schema was never created. `npm run start:prod` runs
`clickhouse:initialise` first, but `initialise_selfhosted.js` catches every
error and exits 0, so an API that boots before ClickHouse is listening starts
with an empty database and keeps failing every query.

Redeploy the `api` service once ClickHouse is up. Deployments from this repo's
current `services/api` wrapper wait for ClickHouse automatically.

### ClickHouse `Address already in use: 0.0.0.0:8123` warnings

Benign. The official image's `docker_related_config.xml` sets
`<listen_host>::</listen_host>`, which binds dual-stack, so the additional
IPv4 `0.0.0.0` binds from `config.xml` report the port as taken. The
entrypoint also runs a short-lived server to create the database before
handing off to the real one, which doubles the messages. As long as
`/ping` answers, ClickHouse is healthy.
