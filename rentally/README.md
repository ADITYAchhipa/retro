# Rentaly Monorepo

Enterprise global property and vehicle rental platform.

## What’s included (Phase 0 scaffold)
- Django + DRF core service with health endpoint.
- FastAPI microservices (realtime, fx, ml) with health endpoints.
- Local infra via Docker Compose: Postgres+PostGIS, Redis, Elasticsearch+Kibana, MinIO, MailHog, stripe-mock.

## Quickstart (local)
1) Copy env file
```bash
cp infra/docker/.env.example infra/docker/.env
```

2) Build and start
```bash
docker compose -f infra/docker/docker-compose.yml up -d --build
```

3) Services
- Django: http://localhost:8000/health
- Realtime (FastAPI): http://localhost:8101/health
- FX (FastAPI): http://localhost:8102/health
- ML (FastAPI): http://localhost:8103/health
- Kibana: http://localhost:5601
- Elasticsearch: http://localhost:9200
- MinIO Console: http://localhost:9001 (S3 API on :9000)
- Mailhog: http://localhost:8025

## Structure
```
rentaly/
  apps/
    backend/
      django_core/
      fastapi-realtime/
      fastapi-fx/
      fastapi-ml/
    mobile/
      flutter/              # to be initialized later
    web/
      admin-nextjs/         # to be initialized later
  shared/
    contracts/
    libs/
    i18n/
  infra/
    docker/
    k8s/
  ci/
```

## Next
- Implement core domain models and APIs in Django.
- Flesh out FastAPI services (WebSockets, FX sources, ML stubs).
- Add OpenAPI contracts and CI/CD.
