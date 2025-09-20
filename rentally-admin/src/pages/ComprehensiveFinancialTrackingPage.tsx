import { useState } from 'react'
import { useCountryStore } from '@/stores/countryStore'
import {
  CurrencyDollarIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  ExclamationTriangleIcon,
  PlusIcon
} from '@heroicons/react/24/outline'
import {
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts'

// Types
interface Expense {
  id: string
  category: 'infrastructure' | 'marketing' | 'staff' | 'operations' | 'legal' | 'maintenance' | 'other'
  subcategory: string
  description: string
  amount: number
  date: string
  status: 'paid' | 'pending' | 'overdue'
  vendor: string
  invoiceNumber?: string
  dueDate?: string
}

interface Revenue {
  id: string
  source: 'booking_fees' | 'subscription' | 'commission' | 'advertising' | 'other'
  description: string
  amount: number
  date: string
  status: 'received' | 'pending'
  customerId?: string
}

interface Bill {
  id: string
  vendor: string
  category: string
  amount: number
  dueDate: string
  status: 'paid' | 'pending' | 'overdue'
  description: string
  invoiceNumber: string
}

// Mock Data
const mockExpenses: Expense[] = [
  {
    id: 'exp001',
    category: 'infrastructure',
    subcategory: 'Cloud Services',
    description: 'AWS hosting and storage',
    amount: 2450.00,
    date: '2024-01-15',
    status: 'paid',
    vendor: 'Amazon Web Services',
    invoiceNumber: 'AWS-2024-001'
  },
  {
    id: 'exp002',
    category: 'marketing',
    subcategory: 'Digital Advertising',
    description: 'Google Ads campaign',
    amount: 1200.00,
    date: '2024-01-10',
    status: 'paid',
    vendor: 'Google Ads',
    invoiceNumber: 'GA-2024-001'
  },
  {
    id: 'exp003',
    category: 'staff',
    subcategory: 'Salaries',
    description: 'Developer salaries',
    amount: 15000.00,
    date: '2024-01-01',
    status: 'paid',
    vendor: 'Payroll',
    invoiceNumber: 'PAY-2024-001'
  },
  {
    id: 'exp004',
    category: 'operations',
    subcategory: 'Customer Support',
    description: 'Support platform subscription',
    amount: 199.00,
    date: '2024-01-05',
    status: 'pending',
    vendor: 'Zendesk',
    invoiceNumber: 'ZD-2024-001',
    dueDate: '2024-02-05'
  },
  {
    id: 'exp005',
    category: 'legal',
    subcategory: 'Compliance',
    description: 'Legal consultation fees',
    amount: 800.00,
    date: '2024-01-20',
    status: 'overdue',
    vendor: 'Legal Partners LLP',
    invoiceNumber: 'LP-2024-001',
    dueDate: '2024-01-25'
  }
]

const mockRevenue: Revenue[] = [
  {
    id: 'rev001',
    source: 'booking_fees',
    description: 'Platform booking fees',
    amount: 8500.00,
    date: '2024-01-15',
    status: 'received'
  },
  {
    id: 'rev002',
    source: 'commission',
    description: 'Host commission (5%)',
    amount: 2100.00,
    date: '2024-01-10',
    status: 'received'
  },
  {
    id: 'rev003',
    source: 'subscription',
    description: 'Premium host subscriptions',
    amount: 999.00,
    date: '2024-01-05',
    status: 'received'
  },
  {
    id: 'rev004',
    source: 'advertising',
    description: 'Property listing promotions',
    amount: 450.00,
    date: '2024-01-12',
    status: 'pending'
  }
]

const mockBills: Bill[] = [
  {
    id: 'bill001',
    vendor: 'Office Lease Co.',
    category: 'Office Rent',
    amount: 3500.00,
    dueDate: '2024-02-01',
    status: 'pending',
    description: 'Monthly office rent',
    invoiceNumber: 'OL-2024-002'
  },
  {
    id: 'bill002',
    vendor: 'Internet Provider',
    category: 'Utilities',
    amount: 299.00,
    dueDate: '2024-01-28',
    status: 'pending',
    description: 'Business internet service',
    invoiceNumber: 'IP-2024-001'
  },
  {
    id: 'bill003',
    vendor: 'Insurance Corp',
    category: 'Insurance',
    amount: 1200.00,
    dueDate: '2024-01-25',
    status: 'overdue',
    description: 'Business liability insurance',
    invoiceNumber: 'IC-2024-001'
  }
]

// Chart Data
const monthlyFinancialData = [
  { month: 'Jan', revenue: 12049, expenses: 19649, profit: -7600 },
  { month: 'Feb', revenue: 15200, expenses: 18900, profit: -3700 },
  { month: 'Mar', revenue: 18500, expenses: 17200, profit: 1300 },
  { month: 'Apr', revenue: 22100, expenses: 19800, profit: 2300 },
  { month: 'May', revenue: 25800, expenses: 21500, profit: 4300 },
  { month: 'Jun', revenue: 28900, expenses: 22100, profit: 6800 }
]

const expenseBreakdown = [
  { name: 'Staff', value: 15000, color: '#8884d8' },
  { name: 'Infrastructure', value: 2450, color: '#82ca9d' },
  { name: 'Marketing', value: 1200, color: '#ffc658' },
  { name: 'Legal', value: 800, color: '#ff7c7c' },
  { name: 'Operations', value: 199, color: '#8dd1e1' }
]

// const revenueBreakdown = [
//   { name: 'Booking Fees', value: 8500, color: '#0088FE' },
//   { name: 'Commission', value: 2100, color: '#00C49F' },
//   { name: 'Subscriptions', value: 999, color: '#FFBB28' },
//   { name: 'Advertising', value: 450, color: '#FF8042' }
// ]

export default function ComprehensiveFinancialTrackingPage() {
  const { selectedCountry } = useCountryStore()
  const [activeTab, setActiveTab] = useState<'overview' | 'expenses' | 'revenue' | 'bills' | 'reports'>('overview')
  
  // Apply country-specific multipliers to financial data
  const getCountryMultiplier = (countryCode: string) => {
    const multipliers: Record<string, number> = {
      'ALL': 1.0, 'US': 1.0, 'GB': 0.3, 'DE': 0.25, 'CA': 0.2, 'AU': 0.15, 
      'IN': 0.4, 'JP': 0.2, 'FR': 0.18, 'BR': 0.12, 'MX': 0.08
    }
    return multipliers[countryCode] || 0.05
  }
  
  const multiplier = getCountryMultiplier(selectedCountry.code)
  const [expenses] = useState<Expense[]>(mockExpenses.map(expense => ({ ...expense, amount: expense.amount * multiplier })))
  const [revenue] = useState<Revenue[]>(mockRevenue.map(revenue => ({ ...revenue, amount: revenue.amount * multiplier })))
  const [bills] = useState<Bill[]>(mockBills.map(bill => ({ ...bill, amount: bill.amount * multiplier })))

  // Calculate totals
  const totalRevenue = revenue.reduce((sum, rev) => sum + rev.amount, 0)
  const totalExpenses = expenses.reduce((sum, exp) => sum + exp.amount, 0)
  const netProfit = totalRevenue - totalExpenses
  const pendingBills = bills.filter(bill => bill.status === 'pending' || bill.status === 'overdue')
  const overdueBills = bills.filter(bill => bill.status === 'overdue')

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid': case 'received': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'overdue': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  // const getCategoryColor = (category: string) => {
  //   switch (category) {
  //     case 'infrastructure': return 'bg-blue-100 text-blue-800'
  //     case 'marketing': return 'bg-purple-100 text-purple-800'
  //     case 'staff': return 'bg-green-100 text-green-800'
  //     case 'operations': return 'bg-orange-100 text-orange-800'
  //     case 'legal': return 'bg-red-100 text-red-800'
  //     default: return 'bg-gray-100 text-gray-800'
  //   }
  // }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Comprehensive Financial Tracking</h1>
        <p className="text-gray-600">Complete overview of app expenses, revenue, and financial health</p>
      </div>

      {/* Tab Navigation */}
      <div className="mb-6">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            {[
              { id: 'overview', name: 'Overview', icon: '📊' },
              { id: 'expenses', name: 'Expenses', icon: '💸' },
              { id: 'revenue', name: 'Revenue', icon: '💰' },
              { id: 'bills', name: 'Bills & Payables', icon: '📄' },
              { id: 'reports', name: 'Reports', icon: '📈' }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <span className="mr-2">{tab.icon}</span>
                {tab.name}
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <div className="space-y-6">
          {/* Financial KPIs */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="flex items-center">
                <div className="p-2 bg-green-100 rounded-md">
                  <ArrowTrendingUpIcon className="h-6 w-6 text-green-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Total Revenue</p>
                  <p className="text-2xl font-semibold text-gray-900">${totalRevenue.toLocaleString()}</p>
                </div>
              </div>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <div className="flex items-center">
                <div className="p-2 bg-red-100 rounded-md">
                  <ArrowTrendingDownIcon className="h-6 w-6 text-red-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Total Expenses</p>
                  <p className="text-2xl font-semibold text-gray-900">${totalExpenses.toLocaleString()}</p>
                </div>
              </div>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <div className="flex items-center">
                <div className={`p-2 rounded-md ${netProfit >= 0 ? 'bg-green-100' : 'bg-red-100'}`}>
                  <CurrencyDollarIcon className={`h-6 w-6 ${netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`} />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Net Profit/Loss</p>
                  <p className={`text-2xl font-semibold ${netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    ${netProfit.toLocaleString()}
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-white p-6 rounded-lg shadow">
              <div className="flex items-center">
                <div className="p-2 bg-yellow-100 rounded-md">
                  <ExclamationTriangleIcon className="h-6 w-6 text-yellow-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Pending Bills</p>
                  <p className="text-2xl font-semibold text-gray-900">{pendingBills.length}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Monthly Financial Trend */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-semibold mb-4">Monthly Financial Trend</h3>
              <ResponsiveContainer width="100%" height={300}>
                <AreaChart data={monthlyFinancialData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Area type="monotone" dataKey="revenue" stackId="1" stroke="#10b981" fill="#10b981" name="Revenue" />
                  <Area type="monotone" dataKey="expenses" stackId="2" stroke="#ef4444" fill="#ef4444" name="Expenses" />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Expense Breakdown */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h3 className="text-lg font-semibold mb-4">Expense Breakdown</h3>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={expenseBreakdown}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={120}
                    fill="#8884d8"
                    dataKey="value"
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                  >
                    {expenseBreakdown.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Recent Transactions */}
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">Recent Transactions</h3>
              <button className="text-blue-600 hover:text-blue-700 text-sm font-medium">View All</button>
            </div>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Description</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {[...expenses.slice(0, 3), ...revenue.slice(0, 2)].map((transaction, index) => (
                    <tr key={index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs rounded-full ${'amount' in transaction && transaction.amount > 0 ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}`}>
                          {'category' in transaction ? 'Expense' : 'Revenue'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {transaction.description}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <span className={'category' in transaction ? 'text-red-600' : 'text-green-600'}>
                          {'category' in transaction ? '-' : '+'}${transaction.amount.toLocaleString()}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(transaction.date).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(transaction.status)}`}>
                          {transaction.status.charAt(0).toUpperCase() + transaction.status.slice(1)}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Alert Section */}
          {overdueBills.length > 0 && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <div className="flex">
                <ExclamationTriangleIcon className="h-5 w-5 text-red-400" />
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-red-800">Overdue Bills Alert</h3>
                  <p className="mt-2 text-sm text-red-700">
                    You have {overdueBills.length} overdue bill{overdueBills.length > 1 ? 's' : ''} requiring immediate attention.
                  </p>
                  <button className="mt-2 text-sm bg-red-100 text-red-800 px-3 py-1 rounded hover:bg-red-200">
                    Review Overdue Bills
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Other tabs would be implemented similarly with their specific content */}
      {activeTab !== 'overview' && (
        <div className="bg-white p-8 rounded-lg shadow text-center">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            {activeTab.charAt(0).toUpperCase() + activeTab.slice(1)} Management
          </h3>
          <p className="text-gray-600">
            Detailed {activeTab} management interface will be implemented here with full CRUD operations,
            filtering, search, and advanced analytics.
          </p>
          <button className="mt-4 bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
            <PlusIcon className="h-4 w-4 inline mr-2" />
            Add New {activeTab.slice(0, -1)}
          </button>
        </div>
      )}
    </div>
  )
}
