import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import { 
  MagnifyingGlassIcon, 
  EyeIcon,
  PencilIcon,
  ExclamationTriangleIcon,
  CheckBadgeIcon,
  UserPlusIcon,
  BanknotesIcon,
  TrashIcon
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

interface User {
  id: string
  name: string
  email: string
  type: 'host' | 'guest' | 'both'
  status: 'active' | 'suspended' | 'pending_verification' | 'banned'
  verificationLevel: 'none' | 'email' | 'phone' | 'id' | 'full'
  joinDate: string
  lastActive: string
  totalBookings: number
  totalEarnings: number
  rating: number
  riskScore: number
  avatar?: string
}

const mockUsers: User[] = [
  {
    id: '1',
    name: 'Sarah Johnson',
    email: 'sarah.j@email.com',
    type: 'host',
    status: 'active',
    verificationLevel: 'full',
    joinDate: '2023-08-15',
    lastActive: '2 hours ago',
    totalBookings: 147,
    totalEarnings: 25600,
    rating: 4.9,
    riskScore: 12
  },
  {
    id: '2', 
    name: 'Michael Chen',
    email: 'mike.chen@email.com',
    type: 'guest',
    status: 'active',
    verificationLevel: 'phone',
    joinDate: '2023-11-02',
    lastActive: '1 day ago',
    totalBookings: 23,
    totalEarnings: 0,
    rating: 4.7,
    riskScore: 8
  },
  {
    id: '3',
    name: 'Emma Rodriguez',
    email: 'emma.r@email.com', 
    type: 'both',
    status: 'pending_verification',
    verificationLevel: 'email',
    joinDate: '2024-01-10',
    lastActive: '5 minutes ago',
    totalBookings: 5,
    totalEarnings: 1200,
    rating: 4.3,
    riskScore: 35
  }
]

export default function AdvancedUsersPage() {
  const { selectedCountry } = useCountryStore()
  const [searchTerm, setSearchTerm] = useState('')
  // const [roleFilter, setRoleFilter] = useState('all')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterType, setFilterType] = useState('all')
  // const [selectedUsers, setSelectedUsers] = useState<string[]>([])
  
  // Apply country filtering to users
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const baseUsers = mockUsers.slice(0, Math.floor(mockUsers.length * multiplier))
  const [users] = useState<User[]>(baseUsers)

  const getStatusColor = (status: User['status']) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800'
      case 'suspended': return 'bg-yellow-100 text-yellow-800'
      case 'pending_verification': return 'bg-blue-100 text-blue-800'
      case 'banned': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getVerificationIcon = (level: User['verificationLevel']) => {
    switch (level) {
      case 'full': return <CheckBadgeIcon className="w-5 h-5 text-green-500" />
      case 'id': return <CheckBadgeIcon className="w-5 h-5 text-blue-500" />
      case 'phone': return <CheckBadgeIcon className="w-5 h-5 text-yellow-500" />
      case 'email': return <CheckBadgeIcon className="w-5 h-5 text-gray-500" />
      default: return <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
    }
  }

  const displayedUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = filterStatus === 'all' || user.status === filterStatus
    const matchesType = filterType === 'all' || user.type === filterType
    return matchesSearch && matchesStatus && matchesType
  })

  const stats = {
    totalUsers: users.length,
    activeUsers: users.filter(u => u.status === 'active').length,
    pendingVerification: users.filter(u => u.status === 'pending_verification').length,
    highRiskUsers: users.filter(u => u.riskScore > 30).length,
    totalRevenue: users.reduce((sum, u) => sum + u.totalEarnings, 0)
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
        <p className="text-gray-600">Manage hosts, guests, verification, and user analytics</p>
      </div>

      {/* User Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">User Growth Trends</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={[
              { month: 'Jan', hosts: 145, guests: 320, total: 465 },
              { month: 'Feb', hosts: 165, guests: 380, total: 545 },
              { month: 'Mar', hosts: 178, guests: 420, total: 598 },
              { month: 'Apr', hosts: 195, guests: 465, total: 660 },
              { month: 'May', hosts: 215, guests: 510, total: 725 },
              { month: 'Jun', hosts: 238, guests: 578, total: 816 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip />
              <Legend />
              <Area type="monotone" dataKey="guests" stackId="1" stroke="#3B82F6" fill="#3B82F6" name="Guests" />
              <Area type="monotone" dataKey="hosts" stackId="1" stroke="#10B981" fill="#10B981" name="Hosts" />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">User Type Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Guests Only', value: users.filter(u => u.type === 'guest').length, color: '#3B82F6' },
                  { name: 'Hosts Only', value: users.filter(u => u.type === 'host').length, color: '#10B981' },
                  { name: 'Host & Guest', value: users.filter(u => u.type === 'both').length, color: '#F59E0B' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Guests Only', value: users.filter(u => u.type === 'guest').length, color: '#3B82F6' },
                  { name: 'Hosts Only', value: users.filter(u => u.type === 'host').length, color: '#10B981' },
                  { name: 'Host & Guest', value: users.filter(u => u.type === 'both').length, color: '#F59E0B' }
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
        <h3 className="text-lg font-medium text-gray-900 mb-4">User Verification Status</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={[
            { level: 'None', count: users.filter(u => u.verificationLevel === 'none').length, earnings: 0 },
            { level: 'Email', count: users.filter(u => u.verificationLevel === 'email').length, earnings: 45000 },
            { level: 'Phone', count: users.filter(u => u.verificationLevel === 'phone').length, earnings: 89000 },
            { level: 'ID', count: users.filter(u => u.verificationLevel === 'id').length, earnings: 156000 },
            { level: 'Full', count: users.filter(u => u.verificationLevel === 'full').length, earnings: 285000 }
          ]}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="level" />
            <YAxis />
            <Tooltip formatter={(value, name) => [
              name === 'earnings' ? `$${Number(value).toLocaleString()}` : value,
              name === 'earnings' ? 'Total Earnings' : 'User Count'
            ]} />
            <Legend />
            <Bar dataKey="count" fill="#3B82F6" name="User Count" />
            <Bar dataKey="earnings" fill="#10B981" name="Total Earnings" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Users</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalUsers}</p>
            </div>
            <UserPlusIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active Users</p>
              <p className="text-2xl font-bold text-green-600">{stats.activeUsers}</p>
            </div>
            <CheckBadgeIcon className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Verification</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.pendingVerification}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">High Risk</p>
              <p className="text-2xl font-bold text-red-600">{stats.highRiskUsers}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-blue-600">${stats.totalRevenue.toLocaleString()}</p>
            </div>
            <BanknotesIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white p-4 rounded-lg shadow-sm border mb-6">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search users by name or email..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
            <option value="pending_verification">Pending Verification</option>
            <option value="banned">Banned</option>
          </select>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Types</option>
            <option value="host">Hosts</option>
            <option value="guest">Guests</option>
            <option value="both">Both</option>
          </select>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2">
            <UserPlusIcon className="w-5 h-5" />
            Add User
          </button>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Verification</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Bookings</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Earnings</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Risk Score</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {displayedUsers.map((user: User) => (
                <tr key={user.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10">
                        <div className="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                          <span className="text-sm font-medium text-gray-700">
                            {user.name.split(' ').map((n: string) => n[0]).join('')}
                          </span>
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">{user.name}</div>
                        <div className="text-sm text-gray-500">{user.email}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      {user.type}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(user.status)}`}>
                      {user.status.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      {getVerificationIcon(user.verificationLevel)}
                      <span className="text-sm text-gray-900 capitalize">{user.verificationLevel}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {user.totalBookings}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    ${user.totalEarnings.toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <span className={`text-sm font-medium ${user.riskScore > 30 ? 'text-red-600' : user.riskScore > 15 ? 'text-yellow-600' : 'text-green-600'}`}>
                        {user.riskScore}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex items-center gap-2">
                      <button className="text-blue-600 hover:text-blue-900">
                        <EyeIcon className="w-4 h-4" />
                      </button>
                      <button className="text-green-600 hover:text-green-900">
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button className="text-red-600 hover:text-red-900">
                        <TrashIcon className="w-4 h-4" />
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
