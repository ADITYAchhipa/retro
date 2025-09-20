import { useState } from 'react'
import { 
  TruckIcon,
  MagnifyingGlassIcon,
  EyeIcon,
  PencilIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  MapPinIcon,
  CurrencyDollarIcon,
  StarIcon,
  ClockIcon
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
  Line
} from 'recharts'

interface Vehicle {
  id: string
  make: string
  model: string
  year: number
  category: 'car' | 'truck' | 'van' | 'motorcycle' | 'rv' | 'boat'
  ownerId: string
  ownerName: string
  status: 'active' | 'inactive' | 'pending' | 'maintenance' | 'suspended'
  location: string
  pricePerDay: number
  availability: boolean
  rating: number
  totalBookings: number
  revenue: number
  lastMaintenance: string
  nextMaintenance: string
  photos: string[]
  features: string[]
  registrationDate: string
  licenseNumber: string
  insuranceExpiry: string
  riskScore: number
}

const mockVehicles: Vehicle[] = [
  {
    id: 'VH_001',
    make: 'Toyota',
    model: 'Camry',
    year: 2022,
    category: 'car',
    ownerId: 'OWN_001',
    ownerName: 'John Smith',
    status: 'active',
    location: 'Los Angeles, CA',
    pricePerDay: 85,
    availability: true,
    rating: 4.8,
    totalBookings: 127,
    revenue: 10795,
    lastMaintenance: '2024-01-10',
    nextMaintenance: '2024-04-10',
    photos: ['photo1.jpg', 'photo2.jpg'],
    features: ['GPS', 'Bluetooth', 'AC', 'Automatic'],
    registrationDate: '2023-08-15',
    licenseNumber: 'ABC123XY',
    insuranceExpiry: '2024-12-31',
    riskScore: 15
  },
  {
    id: 'VH_002',
    make: 'Ford',
    model: 'F-150',
    year: 2021,
    category: 'truck',
    ownerId: 'OWN_002',
    ownerName: 'Sarah Johnson',
    status: 'maintenance',
    location: 'Austin, TX',
    pricePerDay: 120,
    availability: false,
    rating: 4.6,
    totalBookings: 89,
    revenue: 10680,
    lastMaintenance: '2024-01-05',
    nextMaintenance: '2024-07-05',
    photos: ['photo3.jpg'],
    features: ['4WD', 'Towing Package', 'Bed Liner'],
    registrationDate: '2023-06-20',
    licenseNumber: 'DEF456ZY',
    insuranceExpiry: '2024-11-15',
    riskScore: 25
  },
  {
    id: 'VH_003',
    make: 'Honda',
    model: 'Civic',
    year: 2023,
    category: 'car',
    ownerId: 'OWN_003',
    ownerName: 'Mike Chen',
    status: 'pending',
    location: 'Seattle, WA',
    pricePerDay: 65,
    availability: false,
    rating: 0,
    totalBookings: 0,
    revenue: 0,
    lastMaintenance: '2024-01-01',
    nextMaintenance: '2024-07-01',
    photos: ['photo4.jpg', 'photo5.jpg', 'photo6.jpg'],
    features: ['Fuel Efficient', 'Apple CarPlay', 'Lane Assist'],
    registrationDate: '2024-01-15',
    licenseNumber: 'GHI789AB',
    insuranceExpiry: '2025-01-15',
    riskScore: 8
  }
]

export default function VehicleManagementPage() {
  const [vehicles] = useState<Vehicle[]>(mockVehicles)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState<'all' | Vehicle['status']>('all')
  const [categoryFilter, setCategoryFilter] = useState<'all' | Vehicle['category']>('all')
  const [selectedVehicle, setSelectedVehicle] = useState<Vehicle | null>(null)

  const filteredVehicles = vehicles.filter(vehicle => {
    const matchesSearch = 
      vehicle.make.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.model.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.ownerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      vehicle.licenseNumber.toLowerCase().includes(searchTerm.toLowerCase())
    
    const matchesStatus = statusFilter === 'all' || vehicle.status === statusFilter
    const matchesCategory = categoryFilter === 'all' || vehicle.category === categoryFilter
    
    return matchesSearch && matchesStatus && matchesCategory
  })

  const stats = {
    totalVehicles: vehicles.length,
    activeVehicles: vehicles.filter(v => v.status === 'active').length,
    pendingApproval: vehicles.filter(v => v.status === 'pending').length,
    inMaintenance: vehicles.filter(v => v.status === 'maintenance').length,
    totalRevenue: vehicles.reduce((sum, v) => sum + v.revenue, 0),
    avgRating: vehicles.filter(v => v.rating > 0).reduce((sum, v, _, arr) => sum + v.rating / arr.length, 0),
    highRiskVehicles: vehicles.filter(v => v.riskScore > 50).length
  }

  const getStatusColor = (status: Vehicle['status']) => {
    switch (status) {
      case 'active':
        return 'text-green-800 bg-green-100'
      case 'pending':
        return 'text-yellow-800 bg-yellow-100'
      case 'maintenance':
        return 'text-orange-800 bg-orange-100'
      case 'inactive':
        return 'text-gray-800 bg-gray-100'
      case 'suspended':
        return 'text-red-800 bg-red-100'
      default:
        return 'text-gray-800 bg-gray-100'
    }
  }

  const getCategoryIcon = (category: Vehicle['category']) => {
    switch (category) {
      case 'car':
        return '🚗'
      case 'truck':
        return '🚚'
      case 'van':
        return '🚐'
      case 'motorcycle':
        return '🏍️'
      case 'rv':
        return '🚐'
      case 'boat':
        return '⛵'
      default:
        return '🚗'
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)
  }

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Vehicle Management</h1>
        <p className="text-gray-600 mt-2">Manage vehicle fleet, approvals, and performance</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Vehicles</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalVehicles}</p>
              <p className="text-sm text-gray-500">{stats.activeVehicles} active</p>
            </div>
            <TruckIcon className="w-12 h-12 text-blue-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Approval</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.pendingApproval}</p>
              <p className="text-sm text-gray-500">Need review</p>
            </div>
            <ClockIcon className="w-12 h-12 text-yellow-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-green-600">{formatCurrency(stats.totalRevenue)}</p>
              <p className="text-sm text-gray-500">From vehicle rentals</p>
            </div>
            <CurrencyDollarIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Average Rating</p>
              <p className="text-2xl font-bold text-purple-600">{stats.avgRating.toFixed(1)}</p>
              <div className="flex items-center mt-1">
                {[...Array(5)].map((_, i) => (
                  <StarIcon 
                    key={i} 
                    className={`w-4 h-4 ${i < Math.floor(stats.avgRating) ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
                  />
                ))}
              </div>
            </div>
            <StarIcon className="w-12 h-12 text-purple-500" />
          </div>
        </div>
      </div>

      {/* Filters and Search */}
      <div className="bg-white p-6 rounded-lg shadow-sm border mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search by make, model, owner, or license..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
          <div className="flex gap-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as any)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Status</option>
              <option value="active">Active</option>
              <option value="pending">Pending</option>
              <option value="maintenance">Maintenance</option>
              <option value="inactive">Inactive</option>
              <option value="suspended">Suspended</option>
            </select>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value as any)}
              className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="all">All Categories</option>
              <option value="car">Cars</option>
              <option value="truck">Trucks</option>
              <option value="van">Vans</option>
              <option value="motorcycle">Motorcycles</option>
              <option value="rv">RVs</option>
              <option value="boat">Boats</option>
            </select>
          </div>
        </div>
      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Fleet Performance</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={[
              { category: 'Cars', count: 145, revenue: 85000, utilization: 78 },
              { category: 'Trucks', count: 65, revenue: 95000, utilization: 85 },
              { category: 'Vans', count: 45, revenue: 52000, utilization: 72 },
              { category: 'Motorcycles', count: 35, revenue: 18000, utilization: 65 },
              { category: 'RVs', count: 25, revenue: 45000, utilization: 90 },
              { category: 'Boats', count: 15, revenue: 32000, utilization: 68 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="category" />
              <YAxis />
              <Tooltip formatter={(value, name) => [
                name === 'revenue' ? formatCurrency(value as number) : name === 'utilization' ? `${value}%` : value,
                name === 'revenue' ? 'Revenue' : name === 'utilization' ? 'Utilization' : 'Count'
              ]} />
              <Legend />
              <Bar dataKey="count" fill="#3B82F6" name="Vehicle Count" />
              <Bar dataKey="utilization" fill="#10B981" name="Utilization %" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Revenue Trends</h3>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={[
              { month: 'Jan', revenue: 45000, bookings: 235 },
              { month: 'Feb', revenue: 52000, bookings: 267 },
              { month: 'Mar', revenue: 48000, bookings: 245 },
              { month: 'Apr', revenue: 58000, bookings: 298 },
              { month: 'May', revenue: 65000, bookings: 325 },
              { month: 'Jun', revenue: 72000, bookings: 356 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value, name) => [
                name === 'revenue' ? formatCurrency(value as number) : value,
                name === 'revenue' ? 'Revenue' : 'Bookings'
              ]} />
              <Legend />
              <Line type="monotone" dataKey="revenue" stroke="#3B82F6" strokeWidth={2} name="Revenue" />
              <Line type="monotone" dataKey="bookings" stroke="#10B981" strokeWidth={2} name="Bookings" />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Vehicles Table */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Vehicle
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Owner
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Location
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Price/Day
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Performance
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {filteredVehicles.map((vehicle) => (
                <tr key={vehicle.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 w-10 h-10">
                        <div className="w-10 h-10 bg-gray-200 rounded-lg flex items-center justify-center text-lg">
                          {getCategoryIcon(vehicle.category)}
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900">
                          {vehicle.year} {vehicle.make} {vehicle.model}
                        </div>
                        <div className="text-sm text-gray-500">
                          {vehicle.licenseNumber} • {vehicle.category}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{vehicle.ownerName}</div>
                    <div className="text-sm text-gray-500">ID: {vehicle.ownerId}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(vehicle.status)}`}>
                      {vehicle.status}
                    </span>
                    {vehicle.riskScore > 50 && (
                      <div className="flex items-center mt-1">
                        <ExclamationTriangleIcon className="w-4 h-4 text-red-500 mr-1" />
                        <span className="text-xs text-red-600">High Risk</span>
                      </div>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center text-sm text-gray-900">
                      <MapPinIcon className="w-4 h-4 text-gray-400 mr-1" />
                      {vehicle.location}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">
                      {formatCurrency(vehicle.pricePerDay)}
                    </div>
                    <div className={`text-sm ${vehicle.availability ? 'text-green-600' : 'text-red-600'}`}>
                      {vehicle.availability ? 'Available' : 'Unavailable'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">
                      <div className="flex items-center mb-1">
                        <StarIcon className="w-4 h-4 text-yellow-400 mr-1" />
                        {vehicle.rating > 0 ? vehicle.rating.toFixed(1) : 'New'}
                      </div>
                      <div className="text-xs text-gray-500">
                        {vehicle.totalBookings} bookings
                      </div>
                      <div className="text-xs text-gray-500">
                        {formatCurrency(vehicle.revenue)} revenue
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <div className="flex items-center space-x-3">
                      <button
                        onClick={() => setSelectedVehicle(vehicle)}
                        className="text-blue-600 hover:text-blue-900"
                      >
                        <EyeIcon className="w-5 h-5" />
                      </button>
                      <button className="text-green-600 hover:text-green-900">
                        <PencilIcon className="w-5 h-5" />
                      </button>
                      {vehicle.status === 'pending' && (
                        <>
                          <button className="text-green-600 hover:text-green-900">
                            <CheckCircleIcon className="w-5 h-5" />
                          </button>
                          <button className="text-red-600 hover:text-red-900">
                            <XCircleIcon className="w-5 h-5" />
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

      {/* Vehicle Details Modal */}
      {selectedVehicle && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
          <div className="relative top-20 mx-auto p-5 border w-11/12 md:w-3/4 lg:w-1/2 shadow-lg rounded-md bg-white">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-medium text-gray-900">Vehicle Details</h3>
              <button
                onClick={() => setSelectedVehicle(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircleIcon className="w-6 h-6" />
              </button>
            </div>
            
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-500">Vehicle</p>
                  <p className="text-sm text-gray-900">
                    {selectedVehicle.year} {selectedVehicle.make} {selectedVehicle.model}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">License Number</p>
                  <p className="text-sm text-gray-900">{selectedVehicle.licenseNumber}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Owner</p>
                  <p className="text-sm text-gray-900">{selectedVehicle.ownerName}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Category</p>
                  <p className="text-sm text-gray-900">
                    {getCategoryIcon(selectedVehicle.category)} {selectedVehicle.category}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Insurance Expiry</p>
                  <p className="text-sm text-gray-900">{selectedVehicle.insuranceExpiry}</p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-500">Next Maintenance</p>
                  <p className="text-sm text-gray-900">{selectedVehicle.nextMaintenance}</p>
                </div>
              </div>
              
              <div>
                <p className="text-sm font-medium text-gray-500 mb-2">Features</p>
                <div className="flex flex-wrap gap-2">
                  {selectedVehicle.features.map((feature, index) => (
                    <span key={index} className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                      {feature}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
