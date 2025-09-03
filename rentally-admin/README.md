# Rentaly Admin Panel

A modern React + TypeScript admin panel for managing the Rentaly rental marketplace platform.

## Features

- **Dashboard**: Overview of key metrics, revenue trends, and recent activity
- **User Management**: View, search, and manage platform users (seekers, owners, admins)
- **Property Management**: Manage all properties including houses, apartments, vehicles, and equipment
- **Booking Management**: Track and manage all bookings with status updates
- **Analytics**: Comprehensive analytics with charts and performance metrics
- **Settings**: Platform configuration and admin account settings
- **Authentication**: Secure JWT-based authentication with role-based access control

## Tech Stack

- **Frontend**: React 18 + TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Data Fetching**: React Query (TanStack Query)
- **Forms**: React Hook Form + Zod validation
- **Charts**: Recharts
- **Icons**: Heroicons
- **Notifications**: React Hot Toast
- **Routing**: React Router DOM

## Prerequisites

Before running the admin panel, ensure you have:

- Node.js (v18 or higher)
- npm or yarn package manager
- Rentaly backend server running (for API integration)

## Installation

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Environment Setup**:
   Create a `.env` file in the root directory:
   ```env
   VITE_API_URL=http://localhost:5000/api
   VITE_APP_NAME=Rentaly Admin
   ```

3. **Start development server**:
   ```bash
   npm run dev
   ```

4. **Build for production**:
   ```bash
   npm run build
   ```

## Project Structure

```
src/
├── components/          # Reusable UI components
│   └── Layout.tsx      # Main layout with sidebar and navigation
├── pages/              # Page components
│   ├── Dashboard.tsx   # Main dashboard
│   ├── UsersPage.tsx   # User management
│   ├── PropertiesPage.tsx # Property management
│   ├── BookingsPage.tsx   # Booking management
│   ├── AnalyticsPage.tsx  # Analytics and reports
│   ├── SettingsPage.tsx   # Settings and configuration
│   └── LoginPage.tsx      # Authentication
├── stores/             # State management
│   └── authStore.ts    # Authentication state
├── lib/                # Utilities and configurations
│   └── api.ts          # API client setup
├── App.tsx             # Main app component with routing
├── main.tsx            # App entry point
└── index.css           # Global styles and Tailwind imports
```

## Default Login Credentials

For development and testing:
- **Email**: admin@rentaly.com
- **Password**: admin123

## API Integration

The admin panel is designed to work with the Rentaly Node.js + Express.js backend. Key API endpoints:

- `POST /api/auth/login` - Admin authentication
- `GET /api/users` - Fetch users with filtering
- `GET /api/properties` - Fetch properties with filtering
- `GET /api/bookings` - Fetch bookings with filtering
- `GET /api/analytics` - Fetch analytics data

## Features Overview

### Dashboard
- Key performance metrics (revenue, bookings, users, properties)
- Revenue trend charts
- Property distribution analytics
- Recent bookings overview

### User Management
- View all platform users
- Filter by role (Seeker, Owner, Admin)
- Filter by status (Active, Inactive)
- Search functionality
- User actions (view, edit, delete)

### Property Management
- Grid view of all properties
- Filter by type (House, Apartment, Vehicle, Equipment)
- Filter by status (Active, Inactive)
- Property details with ratings and booking counts
- Property actions (view, edit, delete)

### Booking Management
- Comprehensive booking overview
- Status tracking (Pending, Confirmed, Completed, Cancelled)
- Revenue calculations
- Booking approval/rejection for pending bookings
- Filter by property type and status

### Analytics
- Revenue and booking trends
- User growth analytics
- Property type distribution
- Top performing properties
- Interactive charts and visualizations

### Settings
- Profile management
- Notification preferences
- Security settings (2FA, session timeout)
- Platform configuration (commission rates, currency, etc.)

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript type checking

### Code Style

The project uses:
- ESLint for code linting
- Prettier for code formatting
- TypeScript for type safety
- Tailwind CSS for consistent styling

### Adding New Pages

1. Create page component in `src/pages/`
2. Add route in `src/App.tsx`
3. Add navigation link in `src/components/Layout.tsx`
4. Update this README if needed

## Deployment

### Production Build

```bash
npm run build
```

The build artifacts will be stored in the `dist/` directory.

### Environment Variables

For production deployment, set:
- `VITE_API_URL` - Backend API URL
- `VITE_APP_NAME` - Application name

### Deployment Options

The admin panel can be deployed to:
- Netlify
- Vercel
- AWS S3 + CloudFront
- Any static hosting service

## Security Considerations

- JWT tokens are stored securely with automatic expiration
- API requests include authentication headers
- Role-based access control (admin only)
- CORS configuration required on backend
- Environment variables for sensitive configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is part of the Rentaly platform and follows the same licensing terms.

## Support

For issues and questions:
- Check the backend API documentation
- Review the component documentation
- Contact the development team

---

**Note**: This admin panel requires the Rentaly backend server to be running for full functionality. Mock data is used for development when the backend is not available.
