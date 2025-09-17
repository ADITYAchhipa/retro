import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import Layout from '@/components/Layout'
import LoginPage from '@/pages/LoginPage'
import Dashboard from '@/pages/Dashboard'
import UsersPage from '@/pages/UsersPage'
import PropertiesPage from '@/pages/PropertiesPage'
import BookingsPage from '@/pages/BookingsPage'
import AnalyticsPage from '@/pages/AnalyticsPage'
import SettingsPage from '@/pages/SettingsPage'
import ReviewsPage from '@/pages/ReviewsPage'
import ContentModerationPage from '@/pages/ContentModerationPage'
import PaymentsPage from '@/pages/PaymentsPage'
import LogsPage from '@/pages/LogsPage'
import SupportPage from '@/pages/SupportPage'

function App() {
  const { isAuthenticated } = useAuthStore()

  return (
    <Router>
      <Routes>
        <Route 
          path="/login" 
          element={
            isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />
          } 
        />
        <Route
          path="/*"
          element={
            isAuthenticated ? (
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/users" element={<UsersPage />} />
                  <Route path="/properties" element={<PropertiesPage />} />
                  <Route path="/bookings" element={<BookingsPage />} />
                  <Route path="/reviews" element={<ReviewsPage />} />
                  <Route path="/content" element={<ContentModerationPage />} />
                  <Route path="/payments" element={<PaymentsPage />} />
                  <Route path="/logs" element={<LogsPage />} />
                  <Route path="/analytics" element={<AnalyticsPage />} />
                  <Route path="/settings" element={<SettingsPage />} />
                  <Route path="/support" element={<SupportPage />} />
                </Routes>
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>
    </Router>
  )
}

export default App
