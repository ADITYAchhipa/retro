import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { 
  MagnifyingGlassIcon, 
  EyeIcon,
  PencilIcon,
  TrashIcon,
  PlusIcon,
  MapPinIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline'

const mockProperties = [
  { 
    id: 1, 
    title: 'Modern Downtown Apartment', 
    type: 'APARTMENT', 
    location: 'New York, NY', 
    price: 150, 
    status: 'ACTIVE',
    owner: 'Jane Smith',
    bookings: 12,
    rating: 4.8,
    image: '/api/placeholder/300/200'
  },
  { 
    id: 2, 
    title: 'Tesla Model 3', 
    type: 'VEHICLE', 
    location: 'San Francisco, CA', 
    price: 80, 
    status: 'ACTIVE',
    owner: 'John Doe',
    bookings: 25,
    rating: 4.9,
    image: '/api/placeholder/300/200'
  },
  { 
    id: 3, 
    title: 'Beach House Villa', 
    type: 'HOUSE', 
    location: 'Miami, FL', 
    price: 300, 
    status: 'INACTIVE',
    owner: 'Mike Johnson',
    bookings: 8,
    rating: 4.6,
    image: '/api/placeholder/300/200'
  },
]

export default function PropertiesPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')

  const { data: properties, isLoading } = useQuery({
    queryKey: ['properties', searchTerm, typeFilter, statusFilter],
    queryFn: async () => {
      return mockProperties.filter(property => {
        const matchesSearch = property.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                            property.location.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesType = typeFilter === 'all' || property.type === typeFilter
        const matchesStatus = statusFilter === 'all' || property.status === statusFilter
        return matchesSearch && matchesType && matchesStatus
      })
    }
  })

  const getTypeBadge = (type: string) => {
    const colors = {
      HOUSE: 'bg-blue-100 text-blue-800',
      APARTMENT: 'bg-green-100 text-green-800',
      VEHICLE: 'bg-purple-100 text-purple-800',
      EQUIPMENT: 'bg-orange-100 text-orange-800'
    }
    return colors[type as keyof typeof colors] || 'bg-gray-100 text-gray-800'
  }

  const getStatusBadge = (status: string) => {
    return status === 'ACTIVE' 
      ? 'bg-green-100 text-green-800' 
      : 'bg-red-100 text-red-800'
  }

  if (isLoading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-8 bg-gray-200 rounded w-1/4"></div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-64 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Properties</h1>
          <p className="mt-1 text-sm text-gray-500">Manage all properties and vehicles</p>
        </div>
        <button className="btn-primary">
          <PlusIcon className="h-5 w-5 mr-2" />
          Add Property
        </button>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search properties..."
                className="input pl-10"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <select
            className="input w-auto"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            <option value="all">All Types</option>
            <option value="HOUSE">Houses</option>
            <option value="APARTMENT">Apartments</option>
            <option value="VEHICLE">Vehicles</option>
            <option value="EQUIPMENT">Equipment</option>
          </select>

          <select
            className="input w-auto"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="ACTIVE">Active</option>
            <option value="INACTIVE">Inactive</option>
          </select>
        </div>
      </div>

      {/* Properties Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {properties?.map((property) => (
          <div key={property.id} className="card overflow-hidden">
            <div className="aspect-w-16 aspect-h-9">
              <div className="w-full h-48 bg-gray-200 flex items-center justify-center">
                <span className="text-gray-500">Property Image</span>
              </div>
            </div>
            
            <div className="p-4">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-lg font-semibold text-gray-900 truncate">{property.title}</h3>
                <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusBadge(property.status)}`}>
                  {property.status}
                </span>
              </div>
              
              <div className="flex items-center text-sm text-gray-500 mb-2">
                <MapPinIcon className="h-4 w-4 mr-1" />
                {property.location}
              </div>
              
              <div className="flex items-center justify-between mb-3">
                <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getTypeBadge(property.type)}`}>
                  {property.type}
                </span>
                <div className="flex items-center text-sm text-gray-900">
                  <CurrencyDollarIcon className="h-4 w-4 mr-1" />
                  ${property.price}/day
                </div>
              </div>
              
              <div className="flex justify-between items-center text-sm text-gray-500 mb-4">
                <span>Owner: {property.owner}</span>
                <span>{property.bookings} bookings</span>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex text-yellow-400">
                    {[...Array(5)].map((_, i) => (
                      <svg key={i} className="h-4 w-4 fill-current" viewBox="0 0 20 20">
                        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                      </svg>
                    ))}
                  </div>
                  <span className="ml-1 text-sm text-gray-600">{property.rating}</span>
                </div>
                
                <div className="flex space-x-2">
                  <button className="text-blue-600 hover:text-blue-900">
                    <EyeIcon className="h-5 w-5" />
                  </button>
                  <button className="text-green-600 hover:text-green-900">
                    <PencilIcon className="h-5 w-5" />
                  </button>
                  <button className="text-red-600 hover:text-red-900">
                    <TrashIcon className="h-5 w-5" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between">
        <div className="text-sm text-gray-700">
          Showing <span className="font-medium">1</span> to <span className="font-medium">{properties?.length}</span> of{' '}
          <span className="font-medium">{properties?.length}</span> results
        </div>
        <div className="flex space-x-2">
          <button className="btn-outline">Previous</button>
          <button className="btn-outline">Next</button>
        </div>
      </div>
    </div>
  )
}
