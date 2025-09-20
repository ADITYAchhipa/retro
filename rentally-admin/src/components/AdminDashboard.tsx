import { useState } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { navigationItems } from '@/config/navigation'
import { Bars3Icon, XMarkIcon } from '@heroicons/react/24/outline'
import CountrySelector from './CountrySelector'

// Import page components
import Dashboard from '../pages/Dashboard'
import AdvancedUsersPage from '../pages/AdvancedUsersPage'
import AdvancedPropertiesPage from '../pages/AdvancedPropertiesPage'
import AdvancedBookingsPage from '../pages/AdvancedBookingsPage'
import AdvancedAnalyticsPage from '../pages/AdvancedAnalyticsPage'
import VehicleManagementPage from '../pages/VehicleManagementPage'
import SystemOperationsPage from '../pages/SystemOperationsPage'
import FinancialOperationsPage from '../pages/FinancialOperationsPage'
import AdvancedContentModerationPage from '../pages/AdvancedContentModerationPage'
import PaymentsPage from '../pages/PaymentsPage'
import ReviewsPage from '../pages/ReviewsPage'
import LogsPage from '../pages/LogsPage'
import SettingsPage from '../pages/SettingsPage'
import CustomerSupportPage from '../pages/CustomerSupportPage'
import ComprehensiveFinancialTrackingPage from '../pages/ComprehensiveFinancialTrackingPage'

export default function AdminDashboard() {
  const [activeSection, setActiveSection] = useState('dashboard')
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { logout } = useAuthStore()

  const renderContent = () => {
    switch (activeSection) {
      case 'dashboard':
        return <Dashboard />
      case 'users':
        return <AdvancedUsersPage />
      case 'properties':
        return <AdvancedPropertiesPage />
      case 'vehicles':
        return <VehicleManagementPage />
      case 'bookings':
        return <AdvancedBookingsPage />
      case 'financials':
        return <FinancialOperationsPage />
      case 'comprehensive-tracking':
        return <ComprehensiveFinancialTrackingPage />
      case 'payments':
        return <PaymentsPage />
      case 'reviews':
        return <ReviewsPage />
      case 'moderation':
        return <AdvancedContentModerationPage />
      case 'support':
        return <CustomerSupportPage />
      case 'analytics':
        return <AdvancedAnalyticsPage />
      case 'operations':
        return <SystemOperationsPage />
      case 'logs':
        return <LogsPage />
      case 'settings':
        return <SettingsPage />
      case 'fraud':
        return <AdvancedContentModerationPage />
      default:
        return <div className="p-8">Section not found</div>
    }
  }
  
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hamburger Menu Button */}
      <button
        onClick={() => setSidebarOpen(!sidebarOpen)}
        className="fixed top-4 left-4 z-50 p-2 rounded-md bg-white shadow-lg hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        {sidebarOpen ? (
          <XMarkIcon className="h-6 w-6 text-gray-600" />
        ) : (
          <Bars3Icon className="h-6 w-6 text-gray-600" />
        )}
      </button>

      {/* Fixed Sidebar */}
      <div className={`fixed left-0 top-0 w-64 h-screen bg-white shadow-lg z-40 transition-transform duration-300 ease-in-out ${
        sidebarOpen ? 'translate-x-0' : '-translate-x-full'
      }`}>
        <div className="flex items-center justify-center h-16 border-b border-gray-200">
          <h1 className="text-xl font-bold text-gray-900">Rentally Admin</h1>
        </div>
        <nav className="mt-8 h-[calc(100vh-140px)] overflow-y-auto pb-20">
          {navigationItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveSection(item.id)}
              className={`w-full flex items-center px-6 py-3 text-left hover:bg-gray-50 ${
                activeSection === item.id 
                  ? 'bg-blue-50 border-r-2 border-blue-500 text-blue-700' 
                  : 'text-gray-700'
              }`}
            >
              <span className="mr-3 text-lg">{item.icon}</span>
              <span className="font-medium">{item.name}</span>
            </button>
          ))}
        </nav>
        
        <div className="absolute bottom-4 left-4 right-4 w-56">
          <button 
            onClick={logout}
            className="w-full bg-red-600 text-white py-2 px-4 rounded-md hover:bg-red-700 flex items-center justify-center"
          >
            <span className="mr-2">🚪</span>
            Logout
          </button>
        </div>
      </div>

      {/* Overlay for mobile */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Main Content */}
      <div className={`min-h-screen transition-all duration-300 ease-in-out ${
        sidebarOpen ? 'ml-64' : 'ml-0'
      }`}>
        {/* Top Header with Country Filter */}
        <div className="bg-white border-b border-gray-200 px-8 py-4 pt-16">
          <div className="flex justify-between items-center">
            <div>
              <h2 className="text-lg font-semibold text-gray-900 capitalize">
                {activeSection.replace('-', ' ')}
              </h2>
              <p className="text-sm text-gray-600">
                Global data filtered by region
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <div className="text-sm text-gray-500">
                Filter by Country:
              </div>
              <CountrySelector />
            </div>
          </div>
        </div>
        
        <div className="p-8">
          {renderContent()}
        </div>
      </div>
    </div>
  )
}
