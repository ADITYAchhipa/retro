# Rentally Backend (Express)

This is the Express.js backend for the Rentally monorepo.

## Requirements
- Node.js 18+ (LTS recommended)
- npm 9+ (bundled with Node 18)

## Quick Start (no database)
You can boot the API without a database to verify wiring and CORS.

1) Install dependencies
```
npm install
```

2) Copy env and keep DB disabled
```
cp .env.example .env
# Ensure DB_ENABLED=false in .env
```

3) Start the dev server
```
npm run dev
```

4) Test
- Health: http://localhost:5000/api/health
- Info (no DB mode): http://localhost:5000/api

## Enable Database (PostgreSQL + Prisma)
1) Run Postgres (example via Docker):
```
docker run --name rentaly-postgres -e POSTGRES_USER=rentally -e POSTGRES_PASSWORD=rentally -e POSTGRES_DB=rentally -p 5432:5432 -d postgres:16
```

2) Edit `.env`:
```
DB_ENABLED=true
DATABASE_URL=postgresql://rentally:rentally@localhost:5432/rentally
JWT_SECRET=change-me
FRONTEND_URL=http://localhost:3000
```

3) Initialize Prisma (if schema not created yet):
```
npx prisma init
# Edit prisma/schema.prisma and set datasource to env("DATABASE_URL")
# Add your models (User, Property, Booking, Review, etc.)
npx prisma migrate dev --name init
```

4) Start dev server with DB
```
npm run dev
```

## Environment Variables
See `.env.example` for the full list. Key ones:
- `PORT` (default 5000)
- `DB_ENABLED` (false for quick start; true to enable Prisma/Postgres)
- `DATABASE_URL` (Postgres connection string)
- `JWT_SECRET`, `JWT_EXPIRES_IN`
- `FRONTEND_URL` for CORS

## Endpoints
- `GET /api/health` – health check
- No DB mode only:
  - `GET /api` – informational
- With DB enabled (stubs/will expand):
  - `POST /api/auth/register`
  - `POST /api/auth/login`
  - `GET /api/users` (placeholder)
  - `GET /api/properties` (placeholder)
  - `GET /api/bookings` (placeholder)

## Scripts
- `npm run dev` – nodemon dev server
- `npm start` – production start

## Notes
- Passport strategies and Prisma are only initialized when `DB_ENABLED=true`.
- Routes that require DB are mounted only when DB is enabled; in no-DB mode you can still verify the server runs.
