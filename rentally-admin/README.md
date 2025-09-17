# Rentally Admin Panel (Web)

A modern admin dashboard for managing the Rentally marketplace.

## Features
- Dashboard with key stats and charts
- Users management (search, filters, actions)
- Properties management (placeholder)
- Bookings management (placeholder)
- Reviews moderation (approve/reject/delete)
- Content moderation (flags on listings/reviews/users)
- Payments (transactions, payouts, refunds summary)
- System logs (levels/sources, auto-refresh)
- Analytics (placeholder charts)
- Support tickets (filters by status/category)
- Settings

## Tech stack
- React + Vite + TypeScript
- Tailwind CSS
- React Router v6
- React Query (@tanstack/react-query)
- Zustand (auth store)
- Axios with auth interceptor

## Quick start
1) Install deps
```
npm install
```

2) Run dev server
```
npm run dev
```

Open http://localhost:3001

## Backend API
- By default, API base is `VITE_API_URL` if provided, else `http://localhost:5000/api`.
- During development, `vite.config.ts` also proxies `/api` to `http://localhost:5000`.

To point directly to a custom backend, create `.env` in this folder:
```
VITE_API_URL=http://localhost:5000/api
```

## Routes
- `/dashboard`
- `/users`
- `/properties`
- `/bookings`
- `/reviews`
- `/content`
- `/payments`
- `/logs`
- `/analytics`
- `/support`
- `/settings`

## Auth
The login page expects backend endpoints like `/api/auth/login` and JWT token in responses.
Set up the backend with `DB_ENABLED=true` for auth to function.
