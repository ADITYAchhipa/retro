import { useQuery } from '@tanstack/react-query'
import { 
  UsersIcon, 
  BuildingOfficeIcon, 
  CalendarDaysIcon, 
  CurrencyDollarIcon,
  ArrowUpIcon,
  ArrowDownIcon
} from '@heroicons/react/24/outline'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from 'recharts'
import { useCountryStore } from '@/stores/countryStore'
// import api from '@/lib/api'

const stats = [
  { name: 'Total Users', value: '2,847', change: '+12%', changeType: 'increase', icon: UsersIcon },
  { name: 'Active Properties', value: '1,234', change: '+8%', changeType: 'increase', icon: BuildingOfficeIcon },
  { name: 'Total Bookings', value: '5,678', change: '+23%', changeType: 'increase', icon: CalendarDaysIcon },
  { name: 'Revenue', value: '$89,432', change: '-2%', changeType: 'decrease', icon: CurrencyDollarIcon },
]

const revenueData = [
  { name: 'Jan', revenue: 12000, bookings: 45 },
  { name: 'Feb', revenue: 19000, bookings: 67 },
  { name: 'Mar', revenue: 15000, bookings: 52 },
  { name: 'Apr', revenue: 25000, bookings: 89 },
  { name: 'May', revenue: 22000, bookings: 78 },
  { name: 'Jun', revenue: 30000, bookings: 95 },
]

const propertyTypeData = [
  { name: 'Houses', value: 45, color: '#3B82F6' },
  { name: 'Apartments', value: 35, color: '#10B981' },
  { name: 'Vehicles', value: 15, color: '#F59E0B' },
  { name: 'Equipment', value: 5, color: '#EF4444' },
]

const recentBookings = [
  { id: 1, property: 'Modern Apartment Downtown', user: 'John Smith', amount: '$340', status: 'confirmed' },
  { id: 2, property: 'Tesla Model 3', user: 'Sarah Wilson', amount: '$85', status: 'pending' },
  { id: 3, property: 'Beach House Villa', user: 'Mike Johnson', amount: '$520', status: 'confirmed' }
]

export default function Dashboard() {
  const { selectedCountry } = useCountryStore()
  
  const { isLoading } = useQuery({
    queryKey: ['analytics', selectedCountry.code],
    queryFn: async () => {
      // Mock data that varies by country
      const baseData = {
        users: 2847,
        properties: 1234,
        bookings: 5678,
        revenue: 89432
      }
      
      // Simulate country-specific data
      if (selectedCountry.code === 'ALL') {
        return baseData
      }
      
      const countryMultipliers: Record<string, number> = {
        'US': 1.0,
        'GB': 0.3,
        'DE': 0.25,
        'CA': 0.2,
        'AU': 0.15,
        'IN': 0.4,
        'JP': 0.2,
        'FR': 0.18,
        'BR': 0.12,
        'MX': 0.08
      }
      
      const multiplier = countryMultipliers[selectedCountry.code] || 0.05
      
      return {
        users: Math.floor(baseData.users * multiplier),
        properties: Math.floor(baseData.properties * multiplier),
        bookings: Math.floor(baseData.bookings * multiplier),
        revenue: Math.floor(baseData.revenue * multiplier)
      }
    }
  })

  if (isLoading) {
    return (
      <div className="animate-pulse">
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="bg-white overflow-hidden shadow rounded-lg h-24"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Welcome back! Here's what's happening with your rental marketplace.
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((item) => (
          <div key={item.name} className="card p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <item.icon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">{item.name}</dt>
                  <dd className="flex items-baseline">
                    <div className="text-2xl font-semibold text-gray-900">{item.value}</div>
                    <div className={`ml-2 flex items-baseline text-sm font-semibold ${
                      item.changeType === 'increase' ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {item.changeType === 'increase' ? (
                        <ArrowUpIcon className="self-center flex-shrink-0 h-4 w-4" />
                      ) : (
                        <ArrowDownIcon className="self-center flex-shrink-0 h-4 w-4" />
                      )}
                      <span className="sr-only">{item.changeType === 'increase' ? 'Increased' : 'Decreased'} by</span>
                      {item.change}
                    </div>
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Chart */}
        <div className="card p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Revenue Overview</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${value}`, 'Revenue']} />
              <Bar dataKey="revenue" fill="#3B82F6" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Property Types */}
        <div className="card p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Property Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={propertyTypeData}
                cx="50%"
                cy="50%"
                outerRadius={80}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {propertyTypeData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Bookings */}
        <div className="card">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Recent Bookings</h3>
          </div>
          <div className="divide-y divide-gray-200">
            {recentBookings.map((booking: any) => (
              <div key={booking.id} className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{booking.property}</p>
                    <p className="text-sm text-gray-500">{booking.user}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-900">{booking.amount}</p>
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                      booking.status === 'confirmed' 
                        ? 'bg-green-100 text-green-800'
                        : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {booking.status}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Bookings Trend */}
        <div className="card p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Bookings Trend</h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={revenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="bookings" stroke="#10B981" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
