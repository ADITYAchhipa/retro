import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { FlagIcon, EyeIcon, CheckCircleIcon, XCircleIcon } from '@heroicons/react/24/outline'

interface ContentItem {
  id: string
  type: 'LISTING' | 'REVIEW' | 'USER'
  title: string
  reporter: string
  reason: string
  date: string
  status: 'pending' | 'resolved' | 'dismissed'
}

const mockContent: ContentItem[] = [
  { id: 'c1', type: 'LISTING', title: 'Modern Apartment', reporter: 'John Doe', reason: 'Inappropriate images', date: '2024-05-21', status: 'pending' },
  { id: 'c2', type: 'REVIEW', title: 'Review by Mike J.', reporter: 'Jane Smith', reason: 'Harassment', date: '2024-05-20', status: 'pending' },
  { id: 'c3', type: 'USER', title: 'User: trouble_maker', reporter: 'Alice Brown', reason: 'Spam', date: '2024-05-18', status: 'resolved' },
]

export default function ContentModerationPage() {
  const [type, setType] = useState<'all' | 'LISTING' | 'REVIEW' | 'USER'>('all')
  const [status, setStatus] = useState<'all' | 'pending' | 'resolved' | 'dismissed'>('all')

  const { data: items, isLoading } = useQuery({
    queryKey: ['content', type, status],
    queryFn: async () => {
      // TODO: replace with API call: GET /api/admin/content
      return mockContent.filter((c) => {
        const matchesType = type === 'all' || c.type === type
        const matchesStatus = status === 'all' || c.status === status
        return matchesType && matchesStatus
      })
    },
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Content Moderation</h1>
          <p className="mt-1 text-sm text-gray-500">Review flags and take action on listings, reviews, and users</p>
        </div>
      </div>

      <div className="card p-4 flex flex-col sm:flex-row gap-4">
        <select className="input w-full sm:w-auto" value={type} onChange={(e) => setType(e.target.value as any)}>
          <option value="all">All Types</option>
          <option value="LISTING">Listings</option>
          <option value="REVIEW">Reviews</option>
          <option value="USER">Users</option>
        </select>
        <select className="input w-full sm:w-auto" value={status} onChange={(e) => setStatus(e.target.value as any)}>
          <option value="all">All Status</option>
          <option value="pending">Pending</option>
          <option value="resolved">Resolved</option>
          <option value="dismissed">Dismissed</option>
        </select>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Title</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reporter</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reason</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr><td className="px-6 py-4" colSpan={6}>Loading...</td></tr>
              ) : (
                items?.map((c) => (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{c.type}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{c.title}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{c.reporter}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{c.reason}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(c.date).toLocaleDateString()}</td>
                    <td className="px-6 py-4 text-sm text-right">
                      <div className="inline-flex items-center gap-2">
                        <button className="text-gray-600 hover:text-gray-900" title="View details">
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        <button className="text-green-600 hover:text-green-900" title="Resolve">
                          <CheckCircleIcon className="h-5 w-5" />
                        </button>
                        <button className="text-amber-600 hover:text-amber-800" title="Dismiss">
                          <XCircleIcon className="h-5 w-5" />
                        </button>
                        <button className="text-red-600 hover:text-red-900" title="Ban/Remove">
                          <FlagIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </td>
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
