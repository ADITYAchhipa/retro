import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { MagnifyingGlassIcon, ArrowDownTrayIcon, ArrowPathIcon } from '@heroicons/react/24/outline'
// import api from '@/lib/api'

interface PaymentItem {
  id: string
  type: 'booking' | 'payout' | 'refund'
  amount: number
  currency: string
  status: 'succeeded' | 'pending' | 'failed' | 'refunded'
  method: 'card' | 'upi' | 'wallet' | 'bank_transfer'
  user: string
  date: string
  bookingId?: string
}

const mockPayments: PaymentItem[] = [
  { id: 'pay_1', type: 'booking', amount: 450, currency: 'USD', status: 'succeeded', method: 'card', user: 'John Doe', date: '2024-05-21', bookingId: 'BKG-1001' },
  { id: 'pay_2', type: 'payout', amount: 320, currency: 'USD', status: 'pending', method: 'bank_transfer', user: 'Host: Jane Smith', date: '2024-05-20' },
  { id: 'pay_3', type: 'refund', amount: 120, currency: 'USD', status: 'refunded', method: 'card', user: 'Mike Johnson', date: '2024-05-19', bookingId: 'BKG-1000' },
]

export default function PaymentsPage() {
  const [search, setSearch] = useState('')
  const [status, setStatus] = useState<'all' | PaymentItem['status']>('all')
  const [type, setType] = useState<'all' | PaymentItem['type']>('all')

  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['payments', search, status, type],
    queryFn: async () => {
      // TODO: replace with API call: GET /api/admin/payments
      return mockPayments.filter((p) => {
        const q = search.toLowerCase()
        const matchesSearch = [p.id, p.user, p.bookingId, p.method, p.status].join(' ').toLowerCase().includes(q)
        const matchesStatus = status === 'all' || p.status === status
        const matchesType = type === 'all' || p.type === type
        return matchesSearch && matchesStatus && matchesType
      })
    },
  })

  const totalRevenue = (data || []).filter(p => p.type === 'booking' && p.status === 'succeeded').reduce((s, p) => s + p.amount, 0)
  const totalPayouts = (data || []).filter(p => p.type === 'payout').reduce((s, p) => s + p.amount, 0)
  const totalRefunds = (data || []).filter(p => p.type === 'refund').reduce((s, p) => s + p.amount, 0)

  const exportToCSV = (payments: PaymentItem[], filename: string) => {
    const csvHeaders = 'ID,Type,User,Amount,Currency,Method,Status,Date,Booking ID\n'
    const csvRows = payments.map(payment => 
      `"${payment.id}","${payment.type}","${payment.user.replace(/"/g, '""')}","${payment.amount}","${payment.currency}","${payment.method}","${payment.status}","${new Date(payment.date).toLocaleString()}","${payment.bookingId || ''}"`
    ).join('\n')
    
    const csvContent = csvHeaders + csvRows
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    
    if (link.download !== undefined) {
      const url = URL.createObjectURL(blob)
      link.setAttribute('href', url)
      link.setAttribute('download', `${filename}-${new Date().toISOString().split('T')[0]}.csv`)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Payments</h1>
          <p className="mt-1 text-sm text-gray-500">Monitor transactions, payouts and refunds</p>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={() => refetch()}
            disabled={isFetching}
            className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
          >
            <ArrowPathIcon className={`h-4 w-4 mr-2 ${isFetching ? 'animate-spin' : ''}`} /> 
            {isFetching ? 'Refreshing...' : 'Refresh'}
          </button>
          <button 
            onClick={() => exportToCSV(data || [], 'payments-data')}
            disabled={!data || data.length === 0}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200"
          >
            <ArrowDownTrayIcon className="h-4 w-4 mr-2" />
            Export CSV
          </button>
        </div>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card p-4">
          <div className="text-sm text-gray-500">Revenue (succeeded)</div>
          <div className="text-2xl font-semibold">${totalRevenue.toFixed(2)}</div>
        </div>
        <div className="card p-4">
          <div className="text-sm text-gray-500">Payouts</div>
          <div className="text-2xl font-semibold">${totalPayouts.toFixed(2)}</div>
        </div>
        <div className="card p-4">
          <div className="text-sm text-gray-500">Refunds</div>
          <div className="text-2xl font-semibold">${totalRefunds.toFixed(2)}</div>
        </div>
      </div>

      {/* Filters */}
      <div className="card p-4 grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="md:col-span-2">
          <div className="relative">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input className="input pl-10" placeholder="Search id, user, booking, method" value={search} onChange={(e) => setSearch(e.target.value)} />
          </div>
        </div>
        <div>
          <select className="input" value={status} onChange={(e) => setStatus(e.target.value as any)}>
            <option value="all">All Status</option>
            <option value="succeeded">Succeeded</option>
            <option value="pending">Pending</option>
            <option value="failed">Failed</option>
            <option value="refunded">Refunded</option>
          </select>
        </div>
        <div>
          <select className="input" value={type} onChange={(e) => setType(e.target.value as any)}>
            <option value="all">All Types</option>
            <option value="booking">Booking</option>
            <option value="payout">Payout</option>
            <option value="refund">Refund</option>
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
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Method</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr><td className="px-6 py-4" colSpan={7}>Loading...</td></tr>
              ) : (
                data?.map((p) => (
                  <tr key={p.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{p.id}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{p.type}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{p.user}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{p.currency} {p.amount.toFixed(2)}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{p.method}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        p.status === 'succeeded' ? 'bg-green-100 text-green-800' : p.status === 'pending' ? 'bg-yellow-100 text-yellow-800' : p.status === 'failed' ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800'
                      }`}>
                        {p.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(p.date).toLocaleString()}</td>
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
