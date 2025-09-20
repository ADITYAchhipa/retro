import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { StarIcon, MagnifyingGlassIcon, CheckCircleIcon, XCircleIcon, TrashIcon, EyeIcon } from '@heroicons/react/24/outline'

interface ReviewItem {
  id: string
  type: 'PROPERTY' | 'USER'
  target: string
  reviewer: string
  rating: number
  comment?: string
  date: string
  status: 'pending' | 'approved' | 'rejected'
}

const mockReviews: ReviewItem[] = [
  { id: 'r1', type: 'PROPERTY', target: 'Modern Apartment', reviewer: 'John Doe', rating: 5, comment: 'Great stay!', date: '2024-05-21', status: 'approved' },
  { id: 'r2', type: 'USER', target: 'Host: Jane Smith', reviewer: 'Mike Johnson', rating: 4, comment: 'Responsive and helpful host.', date: '2024-05-20', status: 'approved' },
  { id: 'r3', type: 'PROPERTY', target: 'Beach House', reviewer: 'Alice Brown', rating: 2, comment: 'Not as described', date: '2024-05-19', status: 'pending' },
  { id: 'r4', type: 'PROPERTY', target: 'Cozy Room', reviewer: 'Sam Patel', rating: 1, comment: 'Dirty and noisy', date: '2024-05-18', status: 'rejected' },
]

export default function ReviewsPage() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all')
  const [type, setType] = useState<'all' | 'PROPERTY' | 'USER'>('all')
  const [minRating, setMinRating] = useState<number>(0)
  const [selected, setSelected] = useState<ReviewItem | null>(null)

  const { data: reviews, isLoading } = useQuery({
    queryKey: ['reviews', search, status, type, minRating],
    queryFn: async () => {
      // TODO: replace with API call: GET /api/admin/reviews
      return mockReviews.filter((r) => {
        const matchesSearch = [r.target, r.reviewer, r.comment].join(' ').toLowerCase().includes(search.toLowerCase())
        const matchesStatus = status === 'all' || r.status === status
        const matchesType = type === 'all' || r.type === type
        const matchesRating = r.rating >= minRating
        return matchesSearch && matchesStatus && matchesType && matchesRating
      })
    },
  })

  const ratingOptions = useMemo(() => [0,1,2,3,4,5], [])

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Reviews</h1>
          <p className="mt-1 text-sm text-gray-500">Moderate property and user reviews</p>
        </div>
      </div>

      {/* Filters */}
      <div className="card p-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="md:col-span-2">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                className="input pl-10"
                placeholder="Search by target, reviewer or comment"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
          <div>
            <select className="input" value={status} onChange={(e) => setStatus(e.target.value as any)}>
              <option value="all">All Status</option>
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
            </select>
          </div>
          <div className="flex gap-2">
            <select className="input" value={type} onChange={(e) => setType(e.target.value as any)}>
              <option value="all">All Types</option>
              <option value="PROPERTY">Property</option>
              <option value="USER">User</option>
            </select>
            <select className="input" value={minRating} onChange={(e) => setMinRating(Number(e.target.value))}>
              {ratingOptions.map((r) => (
                <option key={r} value={r}>Min {r}★</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Target</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reviewer</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rating</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr><td className="px-6 py-4" colSpan={7}>Loading...</td></tr>
              ) : (
                reviews?.map((r) => (
                  <tr key={r.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{r.type}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{r.target}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{r.reviewer}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">
                      <div className="inline-flex items-center">
                        <StarIcon className="h-4 w-4 text-yellow-500 mr-1" />
                        {r.rating}
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(r.date).toLocaleDateString()}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        r.status === 'approved' ? 'bg-green-100 text-green-800' : r.status === 'rejected' ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {r.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-right">
                      <div className="inline-flex items-center gap-2">
                        <button className="text-gray-600 hover:text-gray-900" onClick={() => setSelected(r)} title="View">
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        <button className="text-green-600 hover:text-green-900" title="Approve">
                          <CheckCircleIcon className="h-5 w-5" />
                        </button>
                        <button className="text-amber-600 hover:text-amber-800" title="Reject">
                          <XCircleIcon className="h-5 w-5" />
                        </button>
                        <button className="text-red-600 hover:text-red-900" title="Delete">
                          <TrashIcon className="h-5 w-5" />
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

      {/* Detail modal */}
      {selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white rounded-lg shadow-lg w-full max-w-lg">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
              <h3 className="text-lg font-medium">Review Details</h3>
              <button onClick={() => setSelected(null)} className="text-gray-500 hover:text-gray-700">✕</button>
            </div>
            <div className="p-6 space-y-3">
              <div className="text-sm text-gray-600">Type</div>
              <div className="text-gray-900">{selected.type}</div>
              <div className="text-sm text-gray-600">Target</div>
              <div className="text-gray-900">{selected.target}</div>
              <div className="text-sm text-gray-600">Reviewer</div>
              <div className="text-gray-900">{selected.reviewer}</div>
              <div className="text-sm text-gray-600">Rating</div>
              <div className="flex items-center text-gray-900"><StarIcon className="h-4 w-4 text-yellow-500 mr-1" />{selected.rating}</div>
              <div className="text-sm text-gray-600">Comment</div>
              <div className="text-gray-900">{selected.comment || '-'}</div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-2">
              <button className="btn-outline" onClick={() => setSelected(null)}>Close</button>
              <button className="btn-primary">Approve</button>
              <button className="btn-secondary">Reject</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
