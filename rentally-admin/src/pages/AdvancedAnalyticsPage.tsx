import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import {
  ChartBarIcon,
  CurrencyDollarIcon,
  CalendarIcon,
  UsersIcon,
  HomeIcon,
  MapIcon,
  DocumentArrowDownIcon,
  PresentationChartLineIcon,
  ArrowTrendingUpIcon
} from '@heroicons/react/24/outline'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell
} from 'recharts'

interface AnalyticsData {
  revenue: {
    total: number
    monthly: number
    growth: number
    trend: 'up' | 'down'
    byMonth: { month: string; amount: number }[]
  }
  bookings: {
    total: number
    confirmed: number
    cancelled: number
    avgValue: number
    conversionRate: number
    byCategory: { category: string; count: number; percentage: number }[]
  }
  users: {
    totalUsers: number
    activeUsers: number
    newUsers: number
    retention: number
    demographics: { segment: string; count: number; percentage: number }[]
  }
  properties: {
    totalProperties: number
    activeListings: number
    averageRating: number
    occupancyRate: number
    topPerforming: { id: string; name: string; revenue: number; bookings: number }[]
  }
  geography: {
    topCities: { city: string; revenue: number; bookings: number; growth: number }[]
    marketPenetration: { region: string; percentage: number; potential: number }[]
  }
  performance: {
    avgResponseTime: string
    customerSatisfaction: number
    hostSatisfaction: number
    platformUptime: number
  }
}

const mockAnalyticsData: AnalyticsData = {
  revenue: {
    total: 2456789,
    monthly: 345678,
    growth: 23.5,
    trend: 'up',
    byMonth: [
      { month: 'Jan', amount: 234567 },
      { month: 'Feb', amount: 267890 },
      { month: 'Mar', amount: 298765 },
      { month: 'Apr', amount: 323456 },
      { month: 'May', amount: 345678 }
    ]
  },
  bookings: {
    total: 8934,
    confirmed: 7654,
    cancelled: 567,
    avgValue: 275.50,
    conversionRate: 85.7,
    byCategory: [
      { category: 'Apartment', count: 4523, percentage: 50.6 },
      { category: 'House', count: 2876, percentage: 32.2 },
      { category: 'Villa', count: 987, percentage: 11.0 },
      { category: 'Studio', count: 548, percentage: 6.1 }
    ]
  },
  users: {
    totalUsers: 45678,
    activeUsers: 32456,
    newUsers: 2345,
    retention: 78.9,
    demographics: [
      { segment: '18-25', count: 9876, percentage: 21.6 },
      { segment: '26-35', count: 15432, percentage: 33.8 },
      { segment: '36-45', count: 12345, percentage: 27.0 },
      { segment: '46+', count: 8025, percentage: 17.6 }
    ]
  },
  properties: {
    totalProperties: 12567,
    activeListings: 9876,
    averageRating: 4.7,
    occupancyRate: 72.3,
    topPerforming: [
      { id: 'PR_001', name: 'Luxury Manhattan Apartment', revenue: 45678, bookings: 187 },
      { id: 'PR_002', name: 'Miami Beach Villa', revenue: 38765, bookings: 156 },
      { id: 'PR_003', name: 'Downtown Loft', revenue: 34567, bookings: 142 }
    ]
  },
  geography: {
    topCities: [
      { city: 'New York', revenue: 567890, bookings: 2345, growth: 18.7 },
      { city: 'Los Angeles', revenue: 456789, bookings: 1987, growth: 23.4 },
      { city: 'Miami', revenue: 345678, bookings: 1654, growth: 15.2 },
      { city: 'San Francisco', revenue: 298765, bookings: 1234, growth: 12.8 }
    ],
    marketPenetration: [
      { region: 'North America', percentage: 67.8, potential: 85.2 },
      { region: 'Europe', percentage: 23.4, potential: 65.7 },
      { region: 'Asia Pacific', percentage: 8.8, potential: 78.9 }
    ]
  },
  performance: {
    avgResponseTime: '2.3 minutes',
    customerSatisfaction: 4.6,
    hostSatisfaction: 4.4,
    platformUptime: 99.8
  }
}

// interface CustomReport {
//   id: string
//   name: string
//   description: string
//   lastGenerated: string
//   frequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
//   status: 'scheduled' | 'generating' | 'ready' | 'failed'
// }

/*
const mockReports: CustomReport[] = [
  {
    id: 'RPT_001',
    name: 'Monthly Revenue Report',
    description: 'Detailed breakdown of monthly revenue by category, location, and trends',
    lastGenerated: '2024-01-20T09:00:00Z',
    frequency: 'monthly',
    status: 'ready'
  },
  {
    id: 'RPT_002',
    name: 'Host Performance Analysis',
    description: 'Individual host performance metrics, earnings, and improvement recommendations',
    lastGenerated: '2024-01-19T14:30:00Z',
    frequency: 'weekly',
    status: 'ready'
  },
  {
    id: 'RPT_003',
    name: 'Market Trends Analysis',
    description: 'Competitive analysis, pricing trends, and market opportunity insights',
    lastGenerated: '2024-01-18T08:15:00Z',
    frequency: 'quarterly',
    status: 'generating'
  }
]
*/

export default function AdvancedAnalyticsPage() {
  const { selectedCountry, formatCurrency } = useCountryStore()
  const [activeTab, setActiveTab] = useState<'overview' | 'revenue' | 'bookings' | 'users' | 'properties' | 'geography' | 'reports' | 'insights'>('overview')
  const [dateRange, setDateRange] = useState('30d')
  const [data] = useState<AnalyticsData>(mockAnalyticsData)
  // const [reports] = useState<CustomReport[]>(mockReports)
  
  // Apply country-specific multipliers to data
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const localizedData = {
    ...data,
    revenue: {
      ...data.revenue,
      total: Math.floor(data.revenue.total * multiplier),
      monthly: Math.floor(data.revenue.monthly * multiplier)
    },
    users: {
      ...data.users,
      totalUsers: Math.floor(data.users.totalUsers * multiplier),
      activeUsers: Math.floor(data.users.activeUsers * multiplier),
      newUsers: Math.floor(data.users.newUsers * multiplier)
    },
    bookings: {
      ...data.bookings,
      total: Math.floor(data.bookings.total * multiplier),
      confirmed: Math.floor(data.bookings.confirmed * multiplier),
      avgValue: Math.floor(data.bookings.avgValue * multiplier)
    },
    properties: {
      ...data.properties,
      totalProperties: Math.floor(data.properties.totalProperties * multiplier),
      activeListings: Math.floor(data.properties.activeListings * multiplier)
    }
  }

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-US').format(num)
  }

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Key Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-gray-900">{formatCurrency(data.revenue.total)}</p>
              <div className="flex items-center mt-1">
                <ArrowTrendingUpIcon className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">+{data.revenue.growth}% vs last month</span>
              </div>
            </div>
            <CurrencyDollarIcon className="w-12 h-12 text-blue-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Bookings</p>
              <p className="text-2xl font-bold text-gray-900">{formatNumber(data.bookings.total)}</p>
              <p className="text-sm text-gray-500">{data.bookings.conversionRate}% conversion rate</p>
            </div>
            <CalendarIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active Users</p>
              <p className="text-2xl font-bold text-gray-900">{formatNumber(data.users.activeUsers)}</p>
              <p className="text-sm text-gray-500">{data.users.retention}% retention rate</p>
            </div>
            <UsersIcon className="w-12 h-12 text-purple-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active Properties</p>
              <p className="text-2xl font-bold text-gray-900">{formatNumber(data.properties.activeListings)}</p>
              <p className="text-sm text-gray-500">{data.properties.occupancyRate}% occupancy rate</p>
            </div>
            <HomeIcon className="w-12 h-12 text-orange-500" />
          </div>
        </div>
      </div>

      {/* Revenue Trend Chart */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-semibold text-gray-900">Revenue Trends</h3>
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="px-3 py-1 border border-gray-300 rounded-md text-sm"
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
            <option value="90d">Last 90 days</option>
            <option value="1y">Last year</option>
          </select>
        </div>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data.revenue.byMonth}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${value?.toLocaleString()}`, 'Revenue']} />
              <Legend />
              <Line
                type="monotone"
                dataKey="amount"
                stroke="#3b82f6"
                strokeWidth={3}
                dot={{ r: 4 }}
                name="Revenue Trend"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Performance Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Platform Performance</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Average Response Time</span>
              <span className="font-medium">{data.performance.avgResponseTime}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Customer Satisfaction</span>
              <div className="flex items-center">
                <span className="font-medium mr-2">{data.performance.customerSatisfaction}/5.0</span>
                <div className="flex text-yellow-400">
                  {'★'.repeat(Math.floor(data.performance.customerSatisfaction))}
                </div>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Platform Uptime</span>
              <span className="font-medium text-green-600">{data.performance.platformUptime}%</span>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Performing Properties</h3>
          <div className="space-y-3">
            {data.properties.topPerforming.map((property, index) => (
              <div key={property.id} className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-900">{property.name}</p>
                  <p className="text-xs text-gray-500">{property.bookings} bookings</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-gray-900">{formatCurrency(property.revenue)}</p>
                  <p className="text-xs text-gray-500">#{index + 1}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )

  const renderRevenue = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-3xl font-bold text-gray-900">{formatCurrency(data.revenue.total)}</p>
            </div>
            <ArrowTrendingUpIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Monthly Revenue</p>
              <p className="text-3xl font-bold text-blue-900">{formatCurrency(data.revenue.monthly)}</p>
            </div>
            <CalendarIcon className="w-12 h-12 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Growth Rate</p>
              <p className="text-3xl font-bold text-green-900">+{data.revenue.growth}%</p>
            </div>
            <ArrowTrendingUpIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue by Month</h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={data.revenue.byMonth}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${value?.toLocaleString()}`, 'Revenue']} />
              <Legend />
              <Area
                type="monotone"
                dataKey="amount"
                stroke="#3b82f6"
                fill="#dbeafe"
                strokeWidth={2}
                name="Monthly Revenue"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )

  const renderGeography = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Market Penetration</h3>
          <div className="space-y-4">
            {localizedData.geography.marketPenetration.map((region) => (
              <div key={region.region} className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm font-medium text-gray-900">{region.region}</span>
                  <span className="text-sm text-gray-600">{region.percentage}%</span>
                </div>
                <div className="w-full bg-gray-200 rounded-full h-2">
                  <div 
                    className="bg-blue-600 h-2 rounded-full" 
                    style={{ width: `${region.percentage}%` }}
                  ></div>
                </div>
                <p className="text-xs text-gray-500">Potential: {region.potential}%</p>
              </div>
            ))}
          </div>
        </div>

        <div className="card p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Top Cities</h3>
          <div className="space-y-3">
            {localizedData.geography.topCities.map((city) => (
              <div key={city.city} className="flex justify-between items-center">
                <span className="text-sm font-medium text-gray-900">{city.city}</span>
                <div className="text-right">
                  <div className="text-sm font-semibold text-gray-900">{formatCurrency(city.revenue)}</div>
                  <div className="text-xs text-gray-500">{city.bookings} bookings</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Global Heat Map</h3>
        <div className="h-80 bg-gray-50 rounded-lg flex items-center justify-center">
          <div className="text-center">
            <MapIcon className="w-20 h-20 text-gray-400 mx-auto mb-2" />
            <p className="text-gray-500">Interactive world map showing booking density</p>
            <p className="text-xs text-gray-400 mt-2">Filtered for: {selectedCountry.name}</p>
          </div>
        </div>
      </div>
    </div>
  )

  const renderBookings = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Bookings</p>
              <p className="text-3xl font-bold text-gray-900">{formatNumber(localizedData.bookings.total)}</p>
            </div>
            <CalendarIcon className="w-12 h-12 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Conversion Rate</p>
              <p className="text-3xl font-bold text-green-900">{data.bookings.conversionRate}%</p>
            </div>
            <ArrowTrendingUpIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Avg Booking Value</p>
              <p className="text-3xl font-bold text-purple-900">{formatCurrency(data.bookings.avgValue)}</p>
            </div>
            <CurrencyDollarIcon className="w-12 h-12 text-purple-500" />
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Booking Trends Over Time</h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data.revenue.byMonth}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Bar dataKey="bookings" fill="#3b82f6" name="Bookings" />
              <Bar dataKey="revenue" fill="#10b981" name="Revenue" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )

  const renderUsers = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">User Growth Trend</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={[
              { name: 'Jan', users: 1200, activeUsers: 980 },
              { name: 'Feb', users: 1350, activeUsers: 1100 },
              { name: 'Mar', users: 1500, activeUsers: 1250 },
              { name: 'Apr', users: 1680, activeUsers: 1400 },
              { name: 'May', users: 1850, activeUsers: 1550 },
              { name: 'Jun', users: 2000, activeUsers: 1700 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="users" stroke="#3B82F6" strokeWidth={2} name="Total Users" />
              <Line type="monotone" dataKey="activeUsers" stroke="#10B981" strokeWidth={2} name="Active Users" />
            </LineChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">User Demographics</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Property Owners', value: 35, color: '#3B82F6' },
                  { name: 'Vehicle Owners', value: 25, color: '#10B981' },
                  { name: 'Renters Only', value: 40, color: '#F59E0B' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Property Owners', value: 35, color: '#3B82F6' },
                  { name: 'Vehicle Owners', value: 25, color: '#10B981' },
                  { name: 'Renters Only', value: 40, color: '#F59E0B' }
                ].map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )

  const renderProperties = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Property Performance</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={[
              { category: 'Houses', properties: 245, bookings: 1890, revenue: 125000 },
              { category: 'Apartments', properties: 180, bookings: 1650, revenue: 95000 },
              { category: 'Condos', properties: 120, bookings: 980, revenue: 75000 },
              { category: 'Villas', properties: 45, bookings: 450, revenue: 65000 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="category" />
              <YAxis />
              <Tooltip formatter={(value, name) => [
                name === 'revenue' ? `$${value}` : value,
                name === 'revenue' ? 'Revenue' : name === 'properties' ? 'Properties' : 'Bookings'
              ]} />
              <Legend />
              <Bar dataKey="properties" fill="#3B82F6" name="Properties" />
              <Bar dataKey="bookings" fill="#10B981" name="Bookings" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Vehicle Fleet Analytics</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Cars', value: 145, color: '#3B82F6' },
                  { name: 'Trucks', value: 65, color: '#10B981' },
                  { name: 'Vans', value: 45, color: '#F59E0B' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Cars', value: 145, color: '#3B82F6' },
                  { name: 'Trucks', value: 65, color: '#10B981' },
                  { name: 'Vans', value: 45, color: '#F59E0B' }
                ].map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )

  const renderReports = () => (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Report Templates</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            'Executive Summary',
            'Financial Performance',
            'User Engagement',
            'Property Analytics',
            'Market Analysis',
            'Operational Metrics'
          ].map((template) => (
            <button
              key={template}
              className="p-4 border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 text-left transition-colors"
            >
              <DocumentArrowDownIcon className="w-6 h-6 text-gray-400 mb-2" />
              <p className="text-sm font-medium text-gray-900">{template}</p>
            </button>
          ))}
        </div>
      </div>
    </div>
  )

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Business Intelligence & Analytics</h1>
        <p className="text-gray-600">Advanced analytics, custom reports, and data-driven insights</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8 overflow-x-auto">
          {[
            { id: 'overview', name: 'Overview', icon: ChartBarIcon },
            { id: 'revenue', name: 'Revenue', icon: CurrencyDollarIcon },
            { id: 'bookings', name: 'Bookings', icon: CalendarIcon },
            { id: 'users', name: 'Users', icon: UsersIcon },
            { id: 'properties', name: 'Properties', icon: HomeIcon },
            { id: 'geography', name: 'Geography', icon: MapIcon },
            { id: 'reports', name: 'Reports', icon: DocumentArrowDownIcon },
            { id: 'insights', name: 'AI Insights', icon: PresentationChartLineIcon }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`group inline-flex items-center py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <tab.icon className="w-5 h-5 mr-2" />
              {tab.name}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && renderOverview()}
      {activeTab === 'revenue' && renderRevenue()}
      {activeTab === 'bookings' && renderBookings()}
      {activeTab === 'geography' && renderGeography()}
      {activeTab === 'reports' && renderReports()}
      
      {activeTab === 'users' && renderUsers()}
      {activeTab === 'properties' && renderProperties()}
      
      {activeTab === 'insights' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <PresentationChartLineIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">AI-Powered Insights</h3>
          <p className="text-gray-600">Machine learning insights, predictive analytics, and recommendations</p>
        </div>
      )}
    </div>
  )
}
