import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { MagnifyingGlassIcon, ChatBubbleLeftRightIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'

interface TicketItem {
  id: string
  subject: string
  category: 'booking' | 'payment' | 'listing' | 'account' | 'other'
  user: string
  priority: 'low' | 'medium' | 'high'
  status: 'open' | 'pending' | 'resolved' | 'closed'
  createdAt: string
  lastUpdate: string
}

const mockTickets: TicketItem[] = [
  { id: 'TCK-1001', subject: 'Refund request for booking BKG-1001', category: 'payment', user: 'John Doe', priority: 'high', status: 'open', createdAt: '2024-05-20', lastUpdate: '2024-05-21' },
  { id: 'TCK-1002', subject: 'Listing review flagged', category: 'listing', user: 'Jane Smith', priority: 'medium', status: 'pending', createdAt: '2024-05-19', lastUpdate: '2024-05-20' },
  { id: 'TCK-1003', subject: 'Cannot login to account', category: 'account', user: 'Mike Johnson', priority: 'low', status: 'resolved', createdAt: '2024-05-18', lastUpdate: '2024-05-19' },
]

export default function SupportPage() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState<'all' | TicketItem['status']>('all')
  const [category, setCategory] = useState<'all' | TicketItem['category']>('all')

  const { data, isLoading } = useQuery({
    queryKey: ['tickets', search, status, category],
    queryFn: async () => {
      // TODO: replace with API call: GET /api/admin/tickets
      return mockTickets.filter((t) => {
        const q = search.toLowerCase()
        const matchesSearch = [t.id, t.subject, t.user, t.category].join(' ').toLowerCase().includes(q)
        const matchesStatus = status === 'all' || t.status === status
        const matchesCategory = category === 'all' || t.category === category
        return matchesSearch && matchesStatus && matchesCategory
      })
    }
  })

  const priorityBadge = (p: TicketItem['priority']) => p === 'high' ? 'bg-red-100 text-red-800' : p === 'medium' ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'
  const statusBadge = (s: TicketItem['status']) => s === 'open' ? 'bg-green-100 text-green-800' : s === 'pending' ? 'bg-yellow-100 text-yellow-800' : s === 'resolved' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Support</h1>
          <p className="mt-1 text-sm text-gray-500">Handle customer support inquiries and tickets</p>
        </div>
        <button className="btn-primary">
          <ChatBubbleLeftRightIcon className="h-5 w-5 mr-2" /> New Ticket
        </button>
      </div>

      {/* Filters */}
      <div className="card p-4 grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="md:col-span-2">
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input className="input pl-10" placeholder="Search subject, user or id" value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>
        <div>
          <select className="input" value={status} onChange={(e) => setStatus(e.target.value as any)}>
            <option value="all">All Status</option>
            <option value="open">Open</option>
            <option value="pending">Pending</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </select>
        </div>
        <div>
          <select className="input" value={category} onChange={(e) => setCategory(e.target.value as any)}>
            <option value="all">All Categories</option>
            <option value="booking">Booking</option>
            <option value="payment">Payment</option>
            <option value="listing">Listing</option>
            <option value="account">Account</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Subject</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Priority</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Updated</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr><td className="px-6 py-4" colSpan={7}>Loading...</td></tr>
              ) : (
                data?.map((t) => (
                  <tr key={t.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{t.id}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{t.subject}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{t.user}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${priorityBadge(t.priority)}`}>{t.priority}</span>
                    </td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${statusBadge(t.status)}`}>{t.status}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(t.createdAt).toLocaleString()}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(t.lastUpdate).toLocaleString()}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
