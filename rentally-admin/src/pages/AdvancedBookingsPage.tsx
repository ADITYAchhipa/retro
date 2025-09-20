import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import { 
  CalendarIcon,
  UserIcon,
  HomeIcon,
  BanknotesIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ChatBubbleLeftIcon,
  ClockIcon,
  MapPinIcon
} from '@heroicons/react/24/outline'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area
} from 'recharts'

interface Booking {
  id: string
  propertyId: string
  propertyTitle: string
  propertyLocation: string
  guestId: string
  guestName: string
  hostId: string
  hostName: string
  checkIn: string
  checkOut: string
  nights: number
  guests: number
  status: 'confirmed' | 'pending' | 'cancelled' | 'completed' | 'disputed' | 'refunded'
  paymentStatus: 'paid' | 'pending' | 'failed' | 'refunded' | 'partial_refund'
  totalAmount: number
  paidAmount: number
  platformFee: number
  hostEarnings: number
  bookingDate: string
  cancellationReason?: string
  disputeType?: 'damage' | 'cleanliness' | 'amenities' | 'noise' | 'safety' | 'other'
  riskScore: number
  specialRequests?: string
  lastActivity: string
}

const mockBookings: Booking[] = [
  {
    id: 'BK_001',
    propertyId: 'PR_001',
    propertyTitle: 'Luxury Downtown Apartment',
    propertyLocation: 'Manhattan, NY',
    guestId: 'USR_123',
    guestName: 'John Smith',
    hostId: 'HOST_001',
    hostName: 'Sarah Johnson',
    checkIn: '2024-02-15',
    checkOut: '2024-02-20',
    nights: 5,
    guests: 2,
    status: 'confirmed',
    paymentStatus: 'paid',
    totalAmount: 1250.00,
    paidAmount: 1250.00,
    platformFee: 125.00,
    hostEarnings: 1125.00,
    bookingDate: '2024-01-20',
    riskScore: 15,
    specialRequests: 'Late check-in requested',
    lastActivity: '2 hours ago'
  },
  {
    id: 'BK_002',
    propertyId: 'PR_002',
    propertyTitle: 'Cozy Beach House',
    propertyLocation: 'Miami Beach, FL',
    guestId: 'USR_456',
    guestName: 'Emily Davis',
    hostId: 'HOST_002',
    hostName: 'Michael Chen',
    checkIn: '2024-01-25',
    checkOut: '2024-01-28',
    nights: 3,
    guests: 4,
    status: 'disputed',
    paymentStatus: 'paid',
    totalAmount: 900.00,
    paidAmount: 900.00,
    platformFee: 90.00,
    hostEarnings: 810.00,
    bookingDate: '2024-01-10',
    disputeType: 'cleanliness',
    riskScore: 65,
    lastActivity: '1 day ago'
  },
  {
    id: 'BK_003',
    propertyId: 'PR_003',
    propertyTitle: 'Modern Studio Loft',
    propertyLocation: 'Austin, TX',
    guestId: 'USR_789',
    guestName: 'Robert Wilson',
    hostId: 'HOST_003',
    hostName: 'Lisa Rodriguez',
    checkIn: '2024-02-01',
    checkOut: '2024-02-03',
    nights: 2,
    guests: 1,
    status: 'cancelled',
    paymentStatus: 'refunded',
    totalAmount: 320.00,
    paidAmount: 0.00,
    platformFee: 32.00,
    hostEarnings: 0.00,
    bookingDate: '2024-01-28',
    cancellationReason: 'Emergency travel change',
    riskScore: 8,
    lastActivity: '3 days ago'
  }
]

export default function AdvancedBookingsPage() {
  const { selectedCountry } = useCountryStore()
  const [searchTerm, setSearchTerm] = useState('')
  // const [statusFilter, setStatusFilter] = useState('all')
  // const [dateFilter, setDateFilter] = useState('all')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterPayment, setFilterPayment] = useState('all')
  // const [selectedBookings, setSelectedBookings] = useState<string[]>([])
  // const [bulkAction, setBulkAction] = useState('')
  
  // Apply country filtering to bookings
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const filteredBookings = mockBookings.slice(0, Math.floor(mockBookings.length * multiplier))
  const [bookings] = useState<Booking[]>(filteredBookings)

  const getStatusColor = (status: Booking['status']) => {
    switch (status) {
      case 'confirmed': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'cancelled': return 'bg-gray-100 text-gray-800'
      case 'completed': return 'bg-blue-100 text-blue-800'
      case 'disputed': return 'bg-red-100 text-red-800'
      case 'refunded': return 'bg-purple-100 text-purple-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getPaymentColor = (status: Booking['paymentStatus']) => {
    switch (status) {
      case 'paid': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'failed': return 'bg-red-100 text-red-800'
      case 'refunded': return 'bg-purple-100 text-purple-800'
      case 'partial_refund': return 'bg-orange-100 text-orange-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const displayedBookings = bookings.filter(booking => {
    const matchesSearch = booking.propertyTitle.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         booking.guestName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         booking.hostName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         booking.id.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesFilterStatus = filterStatus === 'all' || booking.status === filterStatus
    const matchesPayment = filterPayment === 'all' || booking.paymentStatus === filterPayment
    return matchesSearch && matchesFilterStatus && matchesPayment
  })

  const stats = {
    totalBookings: bookings.length,
    confirmedBookings: bookings.filter(b => b.status === 'confirmed').length,
    pendingBookings: bookings.filter(b => b.status === 'pending').length,
    disputedBookings: bookings.filter(b => b.status === 'disputed').length,
    totalRevenue: bookings.reduce((sum, b) => sum + b.totalAmount, 0),
    averageBookingValue: bookings.reduce((sum, b) => sum + b.totalAmount, 0) / bookings.length,
    highRiskBookings: bookings.filter(b => b.riskScore > 50).length,
    completionRate: (bookings.filter(b => b.status === 'completed').length / bookings.length) * 100
  }

  // const handleResolveDispute = (bookingId: string, resolution: 'favor_guest' | 'favor_host' | 'partial_refund') => {
  //   setBookings(prev => prev.map(b => 
  //     b.id === bookingId 
  //       ? { ...b, status: 'completed', paymentStatus: resolution === 'favor_guest' ? 'refunded' : 'paid' }
  //       : b
  //   ))
  // }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Booking Management</h1>
        <p className="text-gray-600">Manage reservations, disputes, cancellations, and booking lifecycle</p>
      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Booking Trends</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={[
              { month: 'Jan', properties: 45, vehicles: 28, total: 73 },
              { month: 'Feb', properties: 52, vehicles: 35, total: 87 },
              { month: 'Mar', properties: 48, vehicles: 32, total: 80 },
              { month: 'Apr', properties: 58, vehicles: 42, total: 100 },
              { month: 'May', properties: 65, vehicles: 48, total: 113 },
              { month: 'Jun', properties: 72, vehicles: 55, total: 127 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area type="monotone" dataKey="properties" stackId="1" stroke="#3B82F6" fill="#3B82F6" name="Property Bookings" />
              <Area type="monotone" dataKey="vehicles" stackId="1" stroke="#10B981" fill="#10B981" name="Vehicle Bookings" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Booking Status Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Confirmed', value: stats.confirmedBookings, color: '#10B981' },
                  { name: 'Pending', value: stats.pendingBookings, color: '#F59E0B' },
                  { name: 'Disputed', value: stats.disputedBookings, color: '#EF4444' },
                  { name: 'Completed', value: bookings.filter(b => b.status === 'completed').length, color: '#3B82F6' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Confirmed', value: stats.confirmedBookings, color: '#10B981' },
                  { name: 'Pending', value: stats.pendingBookings, color: '#F59E0B' },
                  { name: 'Disputed', value: stats.disputedBookings, color: '#EF4444' },
                  { name: 'Completed', value: bookings.filter(b => b.status === 'completed').length, color: '#3B82F6' }
                ].map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border mb-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Revenue Analytics</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={[
            { month: 'Jan', revenue: 125000, bookings: 73, avgValue: 1712 },
            { month: 'Feb', revenue: 145000, bookings: 87, avgValue: 1667 },
            { month: 'Mar', revenue: 132000, bookings: 80, avgValue: 1650 },
            { month: 'Apr', revenue: 165000, bookings: 100, avgValue: 1650 },
            { month: 'May', revenue: 189000, bookings: 113, avgValue: 1673 },
            { month: 'Jun', revenue: 215000, bookings: 127, avgValue: 1693 }
          ]}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" />
            <YAxis />
            <Tooltip formatter={(value, name) => [
              name === 'revenue' ? `$${Number(value).toLocaleString()}` : value,
              name === 'revenue' ? 'Revenue' : name === 'avgValue' ? 'Avg Value' : 'Bookings'
            ]} />
            <Legend />
            <Bar dataKey="revenue" fill="#3B82F6" name="Revenue" />
            <Bar dataKey="bookings" fill="#10B981" name="Bookings Count" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Bookings</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalBookings}</p>
              <p className="text-sm text-green-600">${stats.totalRevenue.toLocaleString()} revenue</p>
            </div>
            <CalendarIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Confirmed</p>
              <p className="text-2xl font-bold text-green-600">{stats.confirmedBookings}</p>
              <p className="text-sm text-gray-500">{((stats.confirmedBookings / stats.totalBookings) * 100).toFixed(1)}%</p>
            </div>
            <CheckCircleIcon className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Disputed</p>
              <p className="text-2xl font-bold text-red-600">{stats.disputedBookings}</p>
              <p className="text-sm text-gray-500">Need attention</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">High Risk</p>
              <p className="text-2xl font-bold text-orange-600">{stats.highRiskBookings}</p>
              <p className="text-sm text-gray-500">Risk score {'>'}  50</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-orange-500" />
          </div>
        </div>
      </div>

      {/* Additional Stats Row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Average Booking Value</p>
              <p className="text-2xl font-bold text-blue-600">${stats.averageBookingValue.toFixed(0)}</p>
            </div>
            <BanknotesIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Completion Rate</p>
              <p className="text-2xl font-bold text-green-600">{stats.completionRate.toFixed(1)}%</p>
            </div>
            <CheckCircleIcon className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Actions</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.pendingBookings + stats.disputedBookings}</p>
            </div>
            <ClockIcon className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white p-4 rounded-lg shadow-sm border mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <input
                type="text"
                placeholder="Search bookings by ID, property, guest, or host..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-4 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Status</option>
            <option value="confirmed">Confirmed</option>
            <option value="pending">Pending</option>
            <option value="cancelled">Cancelled</option>
            <option value="completed">Completed</option>
            <option value="disputed">Disputed</option>
            <option value="refunded">Refunded</option>
          </select>
          <select
            value={filterPayment}
            onChange={(e) => setFilterPayment(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Payment Status</option>
            <option value="paid">Paid</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
            <option value="refunded">Refunded</option>
            <option value="partial_refund">Partial Refund</option>
          </select>
        </div>
      </div>

      {/* Bookings Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Booking</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Guest/Host</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dates</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Payment</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Risk</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {displayedBookings.map((booking: Booking) => (
                <tr key={booking.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{booking.id}</div>
                      <div className="text-sm text-gray-500">
                        {booking.nights} nights • {booking.guests} guests
                      </div>
                      <div className="text-sm text-gray-500">
                        Booked: {new Date(booking.bookingDate).toLocaleDateString()}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <HomeIcon className="w-5 h-5 text-gray-400 mr-2" />
                      <div>
                        <div className="text-sm font-medium text-gray-900">{booking.propertyTitle}</div>
                        <div className="text-sm text-gray-500 flex items-center">
                          <MapPinIcon className="w-4 h-4 mr-1" />
                          {booking.propertyLocation}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm">
                      <div className="flex items-center mb-1">
                        <UserIcon className="w-4 h-4 text-blue-500 mr-1" />
                        <span className="font-medium text-gray-900">{booking.guestName}</span>
                      </div>
                      <div className="flex items-center text-gray-500">
                        <HomeIcon className="w-4 h-4 text-green-500 mr-1" />
                        <span>{booking.hostName}</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      <div className="flex items-center mb-1">
                        <CalendarIcon className="w-4 h-4 text-gray-400 mr-1" />
                        {new Date(booking.checkIn).toLocaleDateString()}
                      </div>
                      <div className="text-gray-500">
                        to {new Date(booking.checkOut).toLocaleDateString()}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex flex-col gap-1">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(booking.status)}`}>
                        {booking.status}
                      </span>
                      {booking.disputeType && (
                        <span className="text-xs text-red-600">
                          Dispute: {booking.disputeType}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPaymentColor(booking.paymentStatus)}`}>
                        {booking.paymentStatus.replace('_', ' ')}
                      </span>
                      <div className="text-sm text-gray-900 mt-1">
                        ${booking.totalAmount.toFixed(2)}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <span className={`text-sm font-medium ${
                        booking.riskScore > 50 ? 'text-red-600' : 
                        booking.riskScore > 25 ? 'text-yellow-600' : 'text-green-600'
                      }`}>
                        {booking.riskScore}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex items-center gap-2">
                      <button className="text-blue-600 hover:text-blue-900">View</button>
                      {booking.status === 'disputed' && (
                        <button className="text-green-600 hover:text-green-900">Resolve</button>
                      )}
                      {booking.status === 'pending' && (
                        <>
                          <button className="text-green-600 hover:text-green-900">Approve</button>
                          <button className="text-red-600 hover:text-red-900">Cancel</button>
                        </>
                      )}
                      <button className="text-gray-600 hover:text-gray-900">
                        <ChatBubbleLeftIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
