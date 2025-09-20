import { useAuthStore } from './stores/authStore'
import LoginPage from './pages/LoginPage'
import AdminDashboard from './components/AdminDashboard'

function App() {
  const { isAuthenticated } = useAuthStore()

  if (isAuthenticated) {
    return <AdminDashboard />
  }

  return <LoginPage />
}

export default App
