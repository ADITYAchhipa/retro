# Rentaly - Rental Marketplace Platform

A comprehensive rental marketplace platform built with Flutter, Node.js, and React.

## 🏗️ Project Structure

```
rentaly/
├── rentally/                 # Flutter mobile app (main user interface)
├── rentally-backend/         # Node.js + Express.js API server
├── rentally-admin/          # React + TypeScript admin panel
└── docs/                    # Documentation and guides
```

## 🚀 Quick Start for Team Collaboration

### Prerequisites
- Node.js v18+ with npm
- Flutter SDK
- PostgreSQL database
- Git

### Setup for New Team Member

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd rentaly
   ```

2. **Backend Setup**:
   ```bash
   cd rentally-backend
   npm install
   cp .env.example .env
   # Configure your database and API keys in .env
   npx prisma migrate dev
   npm run dev
   ```

3. **Admin Panel Setup**:
   ```bash
   cd rentally-admin
   npm install
   npm run dev
   ```

4. **Flutter App Setup**:
   ```bash
   cd rentally
   flutter pub get
   flutter run
   ```

## 🔧 Development Workflow

### Branch Strategy
- `main` - Production ready code
- `develop` - Integration branch for features
- `feature/[name]` - Individual feature development
- `hotfix/[name]` - Critical bug fixes

### Team Responsibilities
- **Backend Developer**: API development, database design, authentication
- **Admin Panel Developer**: React dashboard, analytics, user management
- **Mobile Developer**: Flutter app, UI/UX, mobile-specific features

## 📱 Components

### Flutter Mobile App (`/rentally`)
- User authentication and profiles
- Property browsing and search
- Booking management
- In-app messaging
- Payment integration

### Node.js Backend (`/rentally-backend`)
- RESTful API endpoints
- JWT authentication with OAuth2
- PostgreSQL with Prisma ORM
- File upload handling
- Payment processing

### Admin Panel (`/rentally-admin`)
- User management dashboard
- Property oversight
- Booking analytics
- Platform configuration
- Revenue tracking

## 🌐 Remote Collaboration Options

### Option 1: Git Repository (Recommended)
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "Add: feature description"

# Push and create pull request
git push origin feature/your-feature-name
```

### Option 2: Development Server Sharing
- Use ngrok for temporary backend sharing
- Deploy to staging environment for testing
- Use cloud development environments

### Option 3: Database Sharing
- Shared PostgreSQL instance on cloud
- Docker containers for consistent environments
- Environment-specific configurations

## 🔑 Environment Variables

### Backend (.env)
```env
DATABASE_URL="postgresql://username:password@localhost:5432/rentaly"
JWT_SECRET="your-jwt-secret"
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
FACEBOOK_APP_ID="your-facebook-app-id"
FACEBOOK_APP_SECRET="your-facebook-app-secret"
```

### Admin Panel (.env)
```env
VITE_API_URL=http://localhost:5000/api
VITE_APP_NAME=Rentaly Admin
```

## 🚀 Deployment

### Backend
- Node.js hosting (Railway, Render, Heroku)
- PostgreSQL database (Supabase, Railway, AWS RDS)
- Environment variables configuration

### Admin Panel
- Static hosting (Netlify, Vercel, AWS S3)
- Build command: `npm run build`
- Environment variables for production API

### Mobile App
- Flutter build for Android/iOS
- App store deployment
- Environment-specific builds

## 🤝 Collaboration Best Practices

1. **Communication**:
   - Daily standup calls
   - Slack/Discord for quick updates
   - GitHub issues for bug tracking

2. **Code Quality**:
   - Code reviews for all pull requests
   - Consistent coding standards
   - Automated testing where possible

3. **Development**:
   - Feature branches for all changes
   - Regular integration testing
   - Shared development database

4. **Documentation**:
   - Update README for new features
   - API documentation with examples
   - Code comments for complex logic

## 📞 Support

For setup issues or questions:
- Check component-specific README files
- Review API documentation
- Contact team leads for access credentials

## 🔒 Security Notes

- Never commit `.env` files
- Use environment variables for all secrets
- Regular dependency updates
- Secure API endpoints with proper authentication

---

**Team Setup Complete** ✅
Ready for distributed development across multiple locations.
