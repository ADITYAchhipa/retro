# Rentally Backend API

A comprehensive Node.js + Express.js backend for the Rentally rental marketplace application.

## 🚀 Features

- **Authentication & Authorization**
  - JWT-based authentication
  - OAuth2 integration (Google, Facebook)
  - Role-based access control (Seeker, Owner, Admin)
  - Password hashing with bcrypt

- **Security**
  - Helmet.js for security headers
  - CORS protection
  - Rate limiting
  - Input validation

- **Database**
  - MongoDB with Mongoose ODM
  - User management with comprehensive profiles
  - Referral system integration

## 📦 Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

3. **Start MongoDB:**
   ```bash
   # Make sure MongoDB is running on your system
   mongod
   ```

4. **Run the server:**
   ```bash
   # Development mode
   npm run dev

   # Production mode
   npm start
   ```

## 🔧 Environment Variables

Create a `.env` file with the following variables:

```env
# Database
MONGODB_URI=mongodb://localhost:27017/rentally

# JWT
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d

# OAuth2 - Google
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# OAuth2 - Facebook
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret

# Server
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
```

## 🛠 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/google` - Google OAuth login
- `GET /api/auth/facebook` - Facebook OAuth login
- `GET /api/auth/me` - Get current user profile
- `POST /api/auth/logout` - Logout user
- `POST /api/auth/refresh` - Refresh JWT token

### Health Check
- `GET /api/health` - Server health status

## 🏗 Project Structure

```
src/
├── config/
│   └── passport.js          # Passport OAuth strategies
├── middleware/
│   └── auth.js              # Authentication middleware
├── models/
│   └── User.js              # User data model
├── routes/
│   ├── auth.js              # Authentication routes
│   ├── users.js             # User management routes
│   ├── properties.js        # Property routes (placeholder)
│   └── bookings.js          # Booking routes (placeholder)
└── server.js                # Main application entry point
```

## 🔐 Authentication Flow

### Local Authentication
1. User registers with email/password
2. Password is hashed using bcrypt
3. JWT token is generated and returned
4. Client stores token and sends it in Authorization header

### OAuth2 Authentication
1. User clicks "Login with Google/Facebook"
2. User is redirected to OAuth provider
3. After authorization, user is redirected back with code
4. Backend exchanges code for user profile
5. User is created/updated in database
6. JWT token is generated and returned to frontend

## 🧪 Testing

```bash
# Run tests (when implemented)
npm test

# Health check
curl http://localhost:5000/api/health
```

## 🚀 Deployment

1. Set up production environment variables
2. Install dependencies: `npm install --production`
3. Start with PM2 or similar process manager
4. Set up reverse proxy (Nginx) if needed

## 📝 Next Steps

- [ ] Implement Property model and routes
- [ ] Implement Booking model and routes
- [ ] Add image upload functionality
- [ ] Implement real-time features with Socket.io
- [ ] Add email verification
- [ ] Implement payment integration
- [ ] Add comprehensive testing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
