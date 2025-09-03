import { useQuery } from '@tanstack/react-query'
import {
  ChartBarIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  HomeIcon,
  TrendingUpIcon,
  TrendingDownIcon
} from '@heroicons/react/24/outline'
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts'

const mockRevenueData = [
  { month: 'Jan', revenue: 12000, bookings: 45 },
  { month: 'Feb', revenue: 15000, bookings: 52 },
  { month: 'Mar', revenue: 18000, bookings: 61 },
  { month: 'Apr', revenue: 22000, bookings: 73 },
  { month: 'May', revenue: 25000, bookings: 84 },
  { month: 'Jun', revenue: 28000, bookings: 92 },
]

const mockUserGrowth = [
  { month: 'Jan', users: 120, owners: 25 },
  { month: 'Feb', users: 145, owners: 32 },
  { month: 'Mar', users: 178, owners: 41 },
  { month: 'Apr', users: 210, owners: 48 },
  { month: 'May', users: 245, owners: 56 },
  { month: 'Jun', users: 280, owners: 65 },
]

const mockPropertyTypes = [
  { name: 'Apartments', value: 45, color: '#3B82F6' },
  { name: 'Houses', value: 30, color: '#10B981' },
  { name: 'Vehicles', value: 20, color: '#8B5CF6' },
  { name: 'Equipment', value: 5, color: '#F59E0B' },
]

const mockTopProperties = [
  { name: 'Downtown Apartment', bookings: 25, revenue: 3750 },
  { name: 'Tesla Model 3', bookings: 22, revenue: 1760 },
  { name: 'Beach House Villa', bookings: 18, revenue: 5400 },
  { name: 'Mountain Cabin', bookings: 15, revenue: 2250 },
  { name: 'City Bike', bookings: 12, revenue: 360 },
]

export default function AnalyticsPage() {
  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics'],
    queryFn: async () => {
      // Mock data - replace with actual API call
      return {
        totalRevenue: 120000,
        totalBookings: 407,
        totalUsers: 280,
        totalProperties: 156,
        revenueGrowth: 15.3,
        bookingGrowth: 8.7,
        userGrowth: 12.1,
        propertyGrowth: 5.2
      }
    }
  })

  if (isLoading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-8 bg-gray-200 rounded w-1/4"></div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-32 bg-gray-200 rounded"></div>
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="h-64 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
        <p className="mt-1 text-sm text-gray-500">Track your platform's performance and growth</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="card p-6">
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <CurrencyDollarIcon className="h-6 w-6 text-green-600" />
            </div>
            <div className="ml-4 flex-1">
              <p className="text-sm font-medium text-gray-500">Total Revenue</p>
              <p className="text-2xl font-semibold text-gray-900">
                ${analytics?.totalRevenue.toLocaleString()}
              </p>
            </div>
            <div className="flex items-center text-green-600">
              <TrendingUpIcon className="h-4 w-4 mr-1" />
              <span className="text-sm font-medium">{analytics?.revenueGrowth}%</span>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center">
            <div className="p-2 bg-blue-100 rounded-lg">
              <ChartBarIcon className="h-6 w-6 text-blue-600" />
            </div>
            <div className="ml-4 flex-1">
              <p className="text-sm font-medium text-gray-500">Total Bookings</p>
              <p className="text-2xl font-semibold text-gray-900">
                {analytics?.totalBookings.toLocaleString()}
              </p>
            </div>
            <div className="flex items-center text-green-600">
              <TrendingUpIcon className="h-4 w-4 mr-1" />
              <span className="text-sm font-medium">{analytics?.bookingGrowth}%</span>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center">
            <div className="p-2 bg-purple-100 rounded-lg">
              <UserGroupIcon className="h-6 w-6 text-purple-600" />
            </div>
            <div className="ml-4 flex-1">
              <p className="text-sm font-medium text-gray-500">Total Users</p>
              <p className="text-2xl font-semibold text-gray-900">
                {analytics?.totalUsers.toLocaleString()}
              </p>
            </div>
            <div className="flex items-center text-green-600">
              <TrendingUpIcon className="h-4 w-4 mr-1" />
              <span className="text-sm font-medium">{analytics?.userGrowth}%</span>
            </div>
          </div>
        </div>

        <div className="card p-6">
          <div className="flex items-center">
            <div className="p-2 bg-orange-100 rounded-lg">
              <HomeIcon className="h-6 w-6 text-orange-600" />
            </div>
            <div className="ml-4 flex-1">
              <p className="text-sm font-medium text-gray-500">Total Properties</p>
              <p className="text-2xl font-semibold text-gray-900">
                {analytics?.totalProperties.toLocaleString()}
              </p>
            </div>
            <div className="flex items-center text-green-600">
              <TrendingUpIcon className="h-4 w-4 mr-1" />
              <span className="text-sm font-medium">{analytics?.propertyGrowth}%</span>
            </div>
          </div>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Trend */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trend</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={mockRevenueData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${value.toLocaleString()}`, 'Revenue']} />
              <Area type="monotone" dataKey="revenue" stroke="#3B82F6" fill="#3B82F6" fillOpacity={0.1} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* User Growth */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">User Growth</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={mockUserGrowth}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="users" stroke="#3B82F6" strokeWidth={2} />
              <Line type="monotone" dataKey="owners" stroke="#10B981" strokeWidth={2} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Property Types Distribution */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Property Types</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={mockPropertyTypes}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {mockPropertyTypes.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Top Properties */}
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Properties</h3>
          <div className="space-y-4">
            {mockTopProperties.map((property, index) => (
              <div key={property.name} className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-semibold text-sm mr-3">
                    {index + 1}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900">{property.name}</p>
                    <p className="text-xs text-gray-500">{property.bookings} bookings</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-gray-900">${property.revenue.toLocaleString()}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Booking Trends */}
      <div className="card p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Monthly Bookings</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={mockRevenueData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="bookings" fill="#3B82F6" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )
}
