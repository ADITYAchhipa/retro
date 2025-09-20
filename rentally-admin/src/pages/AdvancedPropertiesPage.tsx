import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import { 
  MagnifyingGlassIcon, 
  EyeIcon,
  PencilIcon,
  CheckIcon,
  XMarkIcon,
  HomeIcon,
  MapPinIcon,
  CameraIcon,
  StarIcon,
  ExclamationTriangleIcon
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
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell
} from 'recharts'

interface Property {
  id: string
  title: string
  type: 'apartment' | 'house' | 'villa' | 'studio' | 'commercial'
  location: string
  hostName: string
  hostId: string
  status: 'active' | 'pending_approval' | 'suspended' | 'rejected' | 'draft'
  approvalStatus: 'approved' | 'pending' | 'rejected' | 'needs_review'
  price: number
  rating: number
  reviewCount: number
  bookings: number
  revenue: number
  photos: number
  amenities: string[]
  createdDate: string
  lastUpdate: string
  qualityScore: number
  riskFlags: string[]
}

const mockProperties: Property[] = [
  {
    id: '1',
    title: 'Luxury Downtown Apartment',
    type: 'apartment',
    location: 'Manhattan, NY',
    hostName: 'Sarah Johnson',
    hostId: '1',
    status: 'active',
    approvalStatus: 'approved',
    price: 250,
    rating: 4.9,
    reviewCount: 87,
    bookings: 142,
    revenue: 35600,
    photos: 12,
    amenities: ['WiFi', 'Kitchen', 'Parking', 'Pool'],
    createdDate: '2023-08-15',
    lastUpdate: '2024-01-10',
    qualityScore: 95,
    riskFlags: []
  },
  {
    id: '2',
    title: 'Cozy Beachfront Villa',
    type: 'villa',
    location: 'Miami Beach, FL', 
    hostName: 'Michael Chen',
    hostId: '2',
    status: 'pending_approval',
    approvalStatus: 'pending',
    price: 450,
    rating: 0,
    reviewCount: 0,
    bookings: 0,
    revenue: 0,
    photos: 8,
    amenities: ['WiFi', 'Beach Access', 'Pool', 'Hot Tub'],
    createdDate: '2024-01-15',
    lastUpdate: '2024-01-15',
    qualityScore: 78,
    riskFlags: ['Unverified Host', 'New Listing']
  },
  {
    id: '3',
    title: 'Historic Brownstone Studio',
    type: 'studio', 
    location: 'Boston, MA',
    hostName: 'Emma Rodriguez',
    hostId: '3',
    status: 'suspended',
    approvalStatus: 'needs_review',
    price: 120,
    rating: 3.2,
    reviewCount: 15,
    bookings: 8,
    revenue: 960,
    photos: 5,
    amenities: ['WiFi', 'Kitchen'],
    createdDate: '2023-11-20',
    lastUpdate: '2024-01-08',
    qualityScore: 52,
    riskFlags: ['Low Rating', 'Quality Issues', 'Guest Complaints']
  }
]

export default function AdvancedPropertiesPage() {
  const { selectedCountry } = useCountryStore()
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterType, setFilterType] = useState('all')
  
  // Apply country filtering to properties
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const baseProperties = mockProperties.slice(0, Math.floor(mockProperties.length * multiplier))
  const [properties, setProperties] = useState<Property[]>(baseProperties)

  const getStatusColor = (status: Property['status']) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800'
      case 'pending_approval': return 'bg-yellow-100 text-yellow-800'
      case 'suspended': return 'bg-red-100 text-red-800'
      case 'rejected': return 'bg-gray-100 text-gray-800'
      case 'draft': return 'bg-blue-100 text-blue-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getApprovalColor = (approval: Property['approvalStatus']) => {
    switch (approval) {
      case 'approved': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'needs_review': return 'bg-orange-100 text-orange-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const displayedProperties = properties.filter(property => {
    const matchesSearch = property.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         property.hostName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         property.location.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = filterStatus === 'all' || property.status === filterStatus
    const matchesType = filterType === 'all' || property.type === filterType
    return matchesSearch && matchesStatus && matchesType
  })

  const stats = {
    totalProperties: properties.length,
    activeProperties: properties.filter(p => p.status === 'active').length,
    pendingApproval: properties.filter(p => p.approvalStatus === 'pending').length,
    needsReview: properties.filter(p => p.approvalStatus === 'needs_review').length,
    totalRevenue: properties.reduce((sum, p) => sum + p.revenue, 0),
    averageRating: properties.reduce((sum, p) => sum + p.rating, 0) / properties.length
  }

  const handleApprove = (propertyId: string) => {
    setProperties(prev => prev.map(p => 
      p.id === propertyId 
        ? { ...p, approvalStatus: 'approved', status: 'active' }
        : p
    ))
  }

  const handleReject = (propertyId: string) => {
    setProperties(prev => prev.map(p => 
      p.id === propertyId 
        ? { ...p, approvalStatus: 'rejected', status: 'rejected' }
        : p
    ))
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Property Management</h1>
        <p className="text-gray-600">Manage listings, approvals, quality control, and property analytics</p>
      </div>

      {/* Property Performance Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Property Revenue Trends</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={[
              { month: 'Jan', apartment: 85000, house: 120000, villa: 180000 },
              { month: 'Feb', apartment: 92000, house: 135000, villa: 195000 },
              { month: 'Mar', apartment: 88000, house: 128000, villa: 188000 },
              { month: 'Apr', apartment: 98000, house: 145000, villa: 210000 },
              { month: 'May', apartment: 105000, house: 158000, villa: 225000 },
              { month: 'Jun', apartment: 112000, house: 165000, villa: 240000 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${Number(value).toLocaleString()}`, '']} />
              <Legend />
              <Line type="monotone" dataKey="apartment" stroke="#3B82F6" name="Apartments" />
              <Line type="monotone" dataKey="house" stroke="#10B981" name="Houses" />
              <Line type="monotone" dataKey="villa" stroke="#F59E0B" name="Villas" />
            </LineChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Property Type Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Apartments', value: properties.filter(p => p.type === 'apartment').length, color: '#3B82F6' },
                  { name: 'Houses', value: properties.filter(p => p.type === 'house').length, color: '#10B981' },
                  { name: 'Villas', value: properties.filter(p => p.type === 'villa').length, color: '#F59E0B' },
                  { name: 'Studios', value: properties.filter(p => p.type === 'studio').length, color: '#EF4444' },
                  { name: 'Commercial', value: properties.filter(p => p.type === 'commercial').length, color: '#8B5CF6' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Apartments', value: properties.filter(p => p.type === 'apartment').length, color: '#3B82F6' },
                  { name: 'Houses', value: properties.filter(p => p.type === 'house').length, color: '#10B981' },
                  { name: 'Villas', value: properties.filter(p => p.type === 'villa').length, color: '#F59E0B' },
                  { name: 'Studios', value: properties.filter(p => p.type === 'studio').length, color: '#EF4444' },
                  { name: 'Commercial', value: properties.filter(p => p.type === 'commercial').length, color: '#8B5CF6' }
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
        <h3 className="text-lg font-medium text-gray-900 mb-4">Property Performance Analytics</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={[
            { category: 'Apartments', avgRating: 4.2, bookings: 156, revenue: 98000 },
            { category: 'Houses', avgRating: 4.5, bookings: 89, revenue: 145000 },
            { category: 'Villas', avgRating: 4.7, bookings: 45, revenue: 210000 },
            { category: 'Studios', avgRating: 4.1, bookings: 78, revenue: 52000 },
            { category: 'Commercial', avgRating: 4.3, bookings: 23, revenue: 85000 }
          ]}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="category" />
            <YAxis />
            <Tooltip formatter={(value, name) => [
              name === 'revenue' ? `$${Number(value).toLocaleString()}` : value,
              name === 'avgRating' ? 'Avg Rating' : name === 'bookings' ? 'Bookings' : 'Revenue'
            ]} />
            <Legend />
            <Bar dataKey="avgRating" fill="#3B82F6" name="Avg Rating" />
            <Bar dataKey="bookings" fill="#10B981" name="Bookings" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-6 gap-4 mb-6">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Properties</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalProperties}</p>
            </div>
            <HomeIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Active</p>
              <p className="text-2xl font-bold text-green-600">{stats.activeProperties}</p>
            </div>
            <CheckIcon className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Approval</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.pendingApproval}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Needs Review</p>
              <p className="text-2xl font-bold text-orange-600">{stats.needsReview}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-orange-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-blue-600">${stats.totalRevenue.toLocaleString()}</p>
            </div>
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Avg Rating</p>
              <p className="text-2xl font-bold text-purple-600">{stats.averageRating.toFixed(1)}</p>
            </div>
            <StarIcon className="w-8 h-8 text-purple-500" />
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
                placeholder="Search properties by title, location, or host..."
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
            <option value="pending_approval">Pending Approval</option>
            <option value="suspended">Suspended</option>
            <option value="rejected">Rejected</option>
            <option value="draft">Draft</option>
          </select>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Types</option>
            <option value="apartment">Apartment</option>
            <option value="house">House</option>
            <option value="villa">Villa</option>
            <option value="studio">Studio</option>
            <option value="commercial">Commercial</option>
          </select>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2">
            <HomeIcon className="w-5 h-5" />
            Add Property
          </button>
        </div>
      </div>

      {/* Properties Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Property</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Host</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Approval</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Performance</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quality</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Risk Flags</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {displayedProperties.map((property) => (
                <tr key={property.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-12 w-12">
                        <div className="h-12 w-12 rounded-lg bg-gray-300 flex items-center justify-center">
                          <HomeIcon className="w-6 h-6 text-gray-600" />
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">{property.title}</div>
                        <div className="text-sm text-gray-500 flex items-center">
                          <MapPinIcon className="w-4 h-4 mr-1" />
                          {property.location}
                        </div>
                        <div className="text-sm text-gray-500">
                          ${property.price}/night • {property.type}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{property.hostName}</div>
                    <div className="text-sm text-gray-500">ID: {property.hostId}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(property.status)}`}>
                      {property.status.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getApprovalColor(property.approvalStatus)}`}>
                      {property.approvalStatus.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      <div className="flex items-center mb-1">
                        <StarIcon className="w-4 h-4 text-yellow-400 mr-1" />
                        {property.rating > 0 ? `${property.rating} (${property.reviewCount})` : 'No reviews'}
                      </div>
                      <div className="text-xs text-gray-500">
                        {property.bookings} bookings • ${property.revenue.toLocaleString()}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="text-sm font-medium text-gray-900">{property.qualityScore}%</div>
                      <div className="ml-2 flex items-center">
                        <CameraIcon className="w-4 h-4 text-gray-400 mr-1" />
                        <span className="text-xs text-gray-500">{property.photos}</span>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {property.riskFlags.length > 0 ? (
                      <div className="flex flex-col gap-1">
                        {property.riskFlags.slice(0, 2).map((flag: string, index: number) => (
                          <span key={index} className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                            {flag}
                          </span>
                        ))}
                        {property.riskFlags.length > 2 && (
                          <span className="text-xs text-gray-500">+{property.riskFlags.length - 2} more</span>
                        )}
                      </div>
                    ) : (
                      <span className="text-xs text-green-600">No flags</span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex items-center gap-2">
                      <button className="text-blue-600 hover:text-blue-900">
                        <EyeIcon className="w-4 h-4" />
                      </button>
                      <button className="text-green-600 hover:text-green-900">
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      {property.approvalStatus === 'pending' && (
                        <>
                          <button 
                            onClick={() => handleApprove(property.id)}
                            className="text-green-600 hover:text-green-900"
                          >
                            <CheckIcon className="w-4 h-4" />
                          </button>
                          <button 
                            onClick={() => handleReject(property.id)}
                            className="text-red-600 hover:text-red-900"
                          >
                            <XMarkIcon className="w-4 h-4" />
                          </button>
                        </>
                      )}
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
