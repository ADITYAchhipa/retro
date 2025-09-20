import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import { 
  BanknotesIcon,
  ArrowTrendingUpIcon,
  ClockIcon,
  CreditCardIcon,
  DocumentArrowDownIcon,
  ArrowTrendingDownIcon
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

interface Transaction {
  id: string
  type: 'booking_payment' | 'host_payout' | 'platform_fee' | 'refund' | 'penalty'
  amount: number
  status: 'completed' | 'pending' | 'failed' | 'processing'
  date: string
  bookingId?: string
  hostId?: string
  guestId?: string
  description: string
  paymentMethod: string
}

interface HostPayout {
  id: string
  hostId: string
  hostName: string
  amount: number
  status: 'scheduled' | 'processing' | 'completed' | 'failed'
  scheduledDate: string
  completedDate?: string
  bookingsIncluded: number
  platformFee: number
  taxes: number
  netAmount: number
}

const mockTransactions: Transaction[] = [
  {
    id: 'txn_001',
    type: 'booking_payment',
    amount: 1250.00,
    status: 'completed',
    date: '2024-01-20',
    bookingId: 'BK_001',
    guestId: 'USR_123',
    description: 'Booking payment for Manhattan Apartment',
    paymentMethod: 'Credit Card'
  },
  {
    id: 'txn_002',
    type: 'host_payout',
    amount: -1000.00,
    status: 'processing',
    date: '2024-01-20',
    hostId: 'HOST_456',
    description: 'Weekly payout to Sarah Johnson',
    paymentMethod: 'Bank Transfer'
  },
  {
    id: 'txn_003',
    type: 'platform_fee',
    amount: 125.00,
    status: 'completed',
    date: '2024-01-20',
    bookingId: 'BK_001',
    description: 'Platform fee (10%)',
    paymentMethod: 'Automatic'
  }
]

const mockPayouts: HostPayout[] = [
  {
    id: 'PO_001',
    hostId: 'HOST_001',
    hostName: 'Sarah Johnson',
    amount: 5420.00,
    status: 'scheduled',
    scheduledDate: '2024-01-25',
    bookingsIncluded: 12,
    platformFee: 602.22,
    taxes: 271.00,
    netAmount: 4546.78
  },
  {
    id: 'PO_002', 
    hostId: 'HOST_002',
    hostName: 'Michael Chen',
    amount: 2890.00,
    status: 'completed',
    scheduledDate: '2024-01-18',
    completedDate: '2024-01-19',
    bookingsIncluded: 8,
    platformFee: 289.00,
    taxes: 144.50,
    netAmount: 2456.50
  }
]

export default function FinancialOperationsPage() {
  const { selectedCountry } = useCountryStore()
  const [activeTab, setActiveTab] = useState<'overview' | 'transactions' | 'payouts' | 'reports'>('overview')

  // Apply country filtering to financial data
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const [transactions] = useState(mockTransactions.map(t => ({ ...t, amount: t.amount * multiplier })))
  const [payouts] = useState(mockPayouts.map(p => ({ ...p, amount: p.amount * multiplier })))

  const getTransactionTypeColor = (type: Transaction['type']) => {
    switch (type) {
      case 'booking_payment': return 'bg-green-100 text-green-800'
      case 'host_payout': return 'bg-blue-100 text-blue-800'
      case 'platform_fee': return 'bg-purple-100 text-purple-800'
      case 'refund': return 'bg-red-100 text-red-800'
      case 'penalty': return 'bg-orange-100 text-orange-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800'
      case 'processing': return 'bg-yellow-100 text-yellow-800'
      case 'pending': return 'bg-blue-100 text-blue-800'
      case 'failed': return 'bg-red-100 text-red-800'
      case 'scheduled': return 'bg-purple-100 text-purple-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const financialStats = {
    totalRevenue: 125400.00,
    monthlyRevenue: 23650.00,
    platformFees: 12540.00,
    pendingPayouts: 18950.00,
    completedPayouts: 89650.00,
    refundsProcessed: 2340.00,
    revenueGrowth: 15.2,
    averageBookingValue: 245.30
  }

  const renderOverview = () => (
    <div className="space-y-6">
      {/* Financial Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Revenue</p>
              <p className="text-2xl font-bold text-gray-900">${financialStats.totalRevenue.toLocaleString()}</p>
              <div className="flex items-center mt-1">
                <ArrowTrendingUpIcon className="w-4 h-4 text-green-500 mr-1" />
                <span className="text-sm text-green-600">{financialStats.revenueGrowth}% this month</span>
              </div>
            </div>
            <BanknotesIcon className="w-12 h-12 text-blue-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Monthly Revenue</p>
              <p className="text-2xl font-bold text-gray-900">${financialStats.monthlyRevenue.toLocaleString()}</p>
              <p className="text-sm text-gray-500">This month</p>
            </div>
            <ArrowTrendingUpIcon className="w-12 h-12 text-green-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Platform Fees</p>
              <p className="text-2xl font-bold text-gray-900">${financialStats.platformFees.toLocaleString()}</p>
              <p className="text-sm text-gray-500">10% average</p>
            </div>
            <CreditCardIcon className="w-12 h-12 text-purple-500" />
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Payouts</p>
              <p className="text-2xl font-bold text-gray-900">${financialStats.pendingPayouts.toLocaleString()}</p>
              <p className="text-sm text-gray-500">{payouts.filter(p => p.status !== 'completed').length} hosts</p>
            </div>
            <ClockIcon className="w-12 h-12 text-yellow-500" />
          </div>
        </div>
      </div>

      {/* Revenue Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Revenue Trends</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={[
              { month: 'Jan', revenue: 89400, fees: 8940, payouts: 80460 },
              { month: 'Feb', revenue: 95600, fees: 9560, payouts: 86040 },
              { month: 'Mar', revenue: 88200, fees: 8820, payouts: 79380 },
              { month: 'Apr', revenue: 112800, fees: 11280, payouts: 101520 },
              { month: 'May', revenue: 125400, fees: 12540, payouts: 112860 },
              { month: 'Jun', revenue: 134200, fees: 13420, payouts: 120780 }
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value) => [`$${Number(value).toLocaleString()}`, '']} />
              <Legend />
              <Area type="monotone" dataKey="revenue" stackId="1" stroke="#3B82F6" fill="#3B82F6" name="Total Revenue" />
              <Area type="monotone" dataKey="fees" stackId="2" stroke="#10B981" fill="#10B981" name="Platform Fees" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Payment Methods Distribution</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={[
                  { name: 'Credit Card', value: 65, color: '#3B82F6' },
                  { name: 'Bank Transfer', value: 25, color: '#10B981' },
                  { name: 'Digital Wallet', value: 8, color: '#F59E0B' },
                  { name: 'Other', value: 2, color: '#EF4444' }
                ]}
                cx="50%"
                cy="50%"
                outerRadius={100}
                dataKey="value"
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
              >
                {[
                  { name: 'Credit Card', value: 65, color: '#3B82F6' },
                  { name: 'Bank Transfer', value: 25, color: '#10B981' },
                  { name: 'Digital Wallet', value: 8, color: '#F59E0B' },
                  { name: 'Other', value: 2, color: '#EF4444' }
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
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Transaction Volume & Value</h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={[
            { week: 'Week 1', volume: 145, value: 28500, avgTransaction: 196 },
            { week: 'Week 2', volume: 162, value: 32400, avgTransaction: 200 },
            { week: 'Week 3', volume: 138, value: 27600, avgTransaction: 200 },
            { week: 'Week 4', volume: 189, value: 37800, avgTransaction: 200 }
          ]}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="week" />
            <YAxis />
            <Tooltip formatter={(value, name) => [
              name === 'value' ? `$${Number(value).toLocaleString()}` : value,
              name === 'volume' ? 'Transactions' : name === 'value' ? 'Total Value' : 'Avg Transaction'
            ]} />
            <Legend />
            <Bar dataKey="volume" fill="#3B82F6" name="Transaction Volume" />
            <Bar dataKey="avgTransaction" fill="#10B981" name="Avg Transaction Value" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Quick Payouts</h3>
          <p className="text-gray-600 mb-4">Process pending host payouts</p>
          <button className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700">
            Process All Pending
          </button>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Financial Reports</h3>
          <p className="text-gray-600 mb-4">Generate monthly reports</p>
          <button className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 flex items-center justify-center">
            <DocumentArrowDownIcon className="w-5 h-5 mr-2" />
            Download Report
          </button>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Tax Management</h3>
          <p className="text-gray-600 mb-4">Review tax calculations</p>
          <button className="w-full bg-purple-600 text-white py-2 px-4 rounded-md hover:bg-purple-700">
            Tax Dashboard
          </button>
        </div>
      </div>
    </div>
  )

  const renderTransactions = () => (
    <div className="bg-white rounded-lg shadow-sm border">
      <div className="p-6 border-b border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900">Recent Transactions</h3>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Transaction</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Payment Method</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {transactions.map((transaction) => (
              <tr key={transaction.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div>
                    <div className="text-sm font-medium text-gray-900">{transaction.description}</div>
                    <div className="text-sm text-gray-500">ID: {transaction.id}</div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getTransactionTypeColor(transaction.type)}`}>
                    {transaction.type.replace('_', ' ')}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`text-sm font-medium ${transaction.amount >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {transaction.amount >= 0 ? '+' : ''}${Math.abs(transaction.amount).toFixed(2)}
                  </span>
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(transaction.status)}`}>
                    {transaction.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-900">
                  {new Date(transaction.date).toLocaleDateString()}
                </td>
                <td className="px-6 py-4 text-sm text-gray-900">
                  {transaction.paymentMethod}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )

  const renderPayouts = () => (
    <div className="bg-white rounded-lg shadow-sm border">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900">Host Payouts</h3>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
            Schedule Payout
          </button>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Host</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Net Amount</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Bookings</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Schedule Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {payouts.map((payout) => (
              <tr key={payout.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <div className="text-sm font-medium text-gray-900">{payout.hostName}</div>
                  <div className="text-sm text-gray-500">ID: {payout.hostId}</div>
                </td>
                <td className="px-6 py-4 text-sm font-medium text-gray-900">
                  ${payout.amount.toFixed(2)}
                </td>
                <td className="px-6 py-4">
                  <div className="text-sm font-medium text-green-600">${payout.netAmount.toFixed(2)}</div>
                  <div className="text-xs text-gray-500">
                    Fee: ${payout.platformFee.toFixed(2)} • Tax: ${payout.taxes.toFixed(2)}
                  </div>
                </td>
                <td className="px-6 py-4 text-sm text-gray-900">
                  {payout.bookingsIncluded}
                </td>
                <td className="px-6 py-4">
                  <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(payout.status)}`}>
                    {payout.status}
                  </span>
                </td>
                <td className="px-6 py-4 text-sm text-gray-900">
                  {new Date(payout.scheduledDate).toLocaleDateString()}
                  {payout.completedDate && (
                    <div className="text-xs text-gray-500">
                      Completed: {new Date(payout.completedDate).toLocaleDateString()}
                    </div>
                  )}
                </td>
                <td className="px-6 py-4">
                  <div className="flex gap-2">
                    <button className="text-blue-600 hover:text-blue-900 text-sm">View</button>
                    {payout.status === 'scheduled' && (
                      <>
                        <button className="text-green-600 hover:text-green-900 text-sm">Process</button>
                        <button className="text-red-600 hover:text-red-900 text-sm">Cancel</button>
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
  )

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Financial Operations</h1>
        <p className="text-gray-600">Revenue tracking, host payouts, and financial analytics</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'overview', name: 'Overview', icon: BanknotesIcon },
            { id: 'transactions', name: 'Transactions', icon: CreditCardIcon },
            { id: 'payouts', name: 'Payouts', icon: ArrowTrendingDownIcon },
            { id: 'reports', name: 'Reports', icon: DocumentArrowDownIcon }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as any)}
              className={`group inline-flex items-center py-2 px-1 border-b-2 font-medium text-sm ${
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
      {activeTab === 'transactions' && renderTransactions()}
      {activeTab === 'payouts' && renderPayouts()}
      {activeTab === 'reports' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <DocumentArrowDownIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Financial Reports</h3>
          <p className="text-gray-600 mb-6">Advanced reporting and analytics coming soon</p>
          <button className="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700">
            Generate Report
          </button>
        </div>
      )}
    </div>
  )
}
