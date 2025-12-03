# Rentaly - Rental Marketplace Platform

Monorepo for the Rentaly marketplace, consisting of:

- Flutter app (web + mobile) in `rentally/`
- Node.js + Express backend in `backend/`
- React + Vite admin panel in `rentally-admin/`

The current stack uses **MongoDB + Mongoose** on the backend, **JWT auth**, and a **Flutter** client with GoRouter and Riverpod.

## 🏗️ Project Structure

```text
rentaly/
├── backend/          # Node.js + Express API (MongoDB, JWT, SendGrid, etc.)
├── rentally/         # Flutter app (End-user marketplace UI)
├── rentally-admin/   # React admin dashboard
└── docs/             # (Optional) extra documentation
```

## 🚀 Quick Start

### 1. Backend API (Node + Express)

```bash
cd backend
npm install
npm run dev         # runs server.js, defaults to http://localhost:4000
```

Backend configuration is controlled by a `.env` file (not committed). Typical variables:

- `MONGO_URI` – MongoDB connection string
- `JWT_SECRET` – secret key for signing JWTs
- `SENDGRID_API_KEY` – for email/OTP sending
- `FROM_EMAIL` – sender address for transactional emails

### 2. Flutter App (rentally)

```bash
cd rentally
flutter pub get
flutter run -d chrome        # or: flutter run -d web-server / mobile device
```

The app talks to the backend using URLs defined in:

- `lib/core/constants/api_constants.dart`

By default these point to:

- `baseUrl    = http://localhost:4000/api`
- `authBaseUrl = http://localhost:4000/api/user`

Make sure the backend is running on port **4000** when developing locally.

### 3. Admin Panel (rentally-admin)

```bash
cd rentally-admin
npm install
npm run dev
```

Then open the URL printed by Vite (typically `http://localhost:3001`).

The admin panel expects an API base like `http://localhost:4000/api` (configurable via `VITE_API_URL` in a local `.env` inside `rentally-admin/`).

## 🔄 Development Workflow

- `main` – primary branch used for production/stable code.
- Create feature branches for changes (e.g. `feature/auth-ux`).
- Always pull latest before starting work:

```bash
git checkout main
git pull origin main
git checkout -b feature/your-feature-name
```

When ready to share work:

```bash
git add .
git commit -m "Describe your change"
git push origin feature/your-feature-name
```

Open a Pull Request on GitHub and review/merge into `main`.

## 📚 Component-Specific Docs

- Flutter app details: `rentally/README.md`
- Admin panel quickstart: `rentally-admin/README.md`
- Backend feature designs (optional, if implemented):
  - `backend/DISPUTE_SYSTEM.md`
  - `backend/NOTIFICATION_SYSTEM.md`

## 🔒 Security Notes

- Never commit `.env` or other secret files.
- Use environment variables for all secrets (JWT, email providers, DB credentials).
- Keep dependencies up to date.
- Protect API endpoints with proper authentication/authorization.

