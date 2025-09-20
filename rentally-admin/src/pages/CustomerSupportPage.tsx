import { useState } from 'react'
import { 
  ChatBubbleLeftRightIcon,
  MagnifyingGlassIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  UserIcon,
  TagIcon,
  DocumentTextIcon,
  PaperAirplaneIcon,
  ChartBarIcon
} from '@heroicons/react/24/outline'

interface SupportTicket {
  id: string
  subject: string
  status: 'open' | 'in_progress' | 'waiting_customer' | 'resolved' | 'closed'
  priority: 'low' | 'medium' | 'high' | 'urgent'
  category: 'booking_issue' | 'payment_problem' | 'property_concern' | 'account_help' | 'technical_issue' | 'other'
  customerId: string
  customerName: string
  customerType: 'guest' | 'host'
  assignedTo?: string
  createdAt: string
  lastActivity: string
  messages: number
  description: string
  relatedBookingId?: string
  relatedPropertyId?: string
  tags: string[]
  satisfaction?: number
}

interface Message {
  id: string
  ticketId: string
  sender: string
  senderType: 'customer' | 'agent' | 'system'
  content: string
  timestamp: string
  attachments?: string[]
  isInternal?: boolean
}

const mockTickets: SupportTicket[] = [
  {
    id: 'TKT_001',
    subject: 'Booking cancellation refund issue',
    status: 'open',
    priority: 'high',
    category: 'payment_problem',
    customerId: 'USR_123',
    customerName: 'John Smith',
    customerType: 'guest',
    createdAt: '2024-01-20T09:30:00Z',
    lastActivity: '2024-01-20T14:22:00Z',
    messages: 3,
    description: 'I cancelled my booking 5 days ago but still haven\'t received my refund. The booking was for $1,250.',
    relatedBookingId: 'BK_001',
    tags: ['refund', 'urgent', 'payment'],
    satisfaction: undefined
  },
  {
    id: 'TKT_002',
    subject: 'Property listing not appearing in search',
    status: 'in_progress',
    priority: 'medium',
    category: 'technical_issue',
    customerId: 'HOST_456',
    customerName: 'Sarah Johnson',
    customerType: 'host',
    assignedTo: 'Agent Smith',
    createdAt: '2024-01-19T16:45:00Z',
    lastActivity: '2024-01-20T10:15:00Z',
    messages: 7,
    description: 'My luxury apartment listing hasn\'t been showing up in search results for the past 3 days.',
    relatedPropertyId: 'PR_001',
    tags: ['search', 'visibility', 'technical'],
    satisfaction: undefined
  },
  {
    id: 'TKT_003',
    subject: 'Guest damaged property - dispute help needed',
    status: 'waiting_customer',
    priority: 'urgent',
    category: 'property_concern',
    customerId: 'HOST_789',
    customerName: 'Mike Chen',
    customerType: 'host',
    assignedTo: 'Agent Johnson',
    createdAt: '2024-01-18T11:20:00Z',
    lastActivity: '2024-01-19T08:30:00Z',
    messages: 12,
    description: 'Guest caused significant damage to my beach house. Need help filing damage claim.',
    relatedBookingId: 'BK_002',
    relatedPropertyId: 'PR_002',
    tags: ['damage', 'dispute', 'insurance'],
    satisfaction: undefined
  }
]

const mockMessages: Message[] = [
  {
    id: 'MSG_001',
    ticketId: 'TKT_001',
    sender: 'John Smith',
    senderType: 'customer',
    content: 'I cancelled my booking 5 days ago but still haven\'t received my refund. The booking was for $1,250.',
    timestamp: '2024-01-20T09:30:00Z'
  },
  {
    id: 'MSG_002',
    ticketId: 'TKT_001',
    sender: 'System',
    senderType: 'system',
    content: 'Ticket automatically escalated due to refund delay beyond 72 hours.',
    timestamp: '2024-01-20T12:00:00Z',
    isInternal: true
  },
  {
    id: 'MSG_003',
    ticketId: 'TKT_001',
    sender: 'John Smith',
    senderType: 'customer',
    content: 'This is really frustrating. I need the money back urgently as I have other travel plans.',
    timestamp: '2024-01-20T14:22:00Z'
  }
]

export default function CustomerSupportPage() {
  const [activeTab, setActiveTab] = useState<'tickets' | 'chat' | 'analytics' | 'knowledge'>('tickets')
  const [tickets, setTickets] = useState<SupportTicket[]>(mockTickets)
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null)
  const [messages, setMessages] = useState<Message[]>(mockMessages)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterPriority, setFilterPriority] = useState('all')
  const [newMessage, setNewMessage] = useState('')

  const getStatusColor = (status: SupportTicket['status']) => {
    switch (status) {
      case 'open': return 'bg-red-100 text-red-800'
      case 'in_progress': return 'bg-blue-100 text-blue-800'
      case 'waiting_customer': return 'bg-yellow-100 text-yellow-800'
      case 'resolved': return 'bg-green-100 text-green-800'
      case 'closed': return 'bg-gray-100 text-gray-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getPriorityColor = (priority: SupportTicket['priority']) => {
    switch (priority) {
      case 'urgent': return 'text-red-600'
      case 'high': return 'text-orange-600'
      case 'medium': return 'text-yellow-600'
      case 'low': return 'text-green-600'
      default: return 'text-gray-600'
    }
  }

  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = ticket.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         ticket.customerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         ticket.id.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = filterStatus === 'all' || ticket.status === filterStatus
    const matchesPriority = filterPriority === 'all' || ticket.priority === filterPriority
    return matchesSearch && matchesStatus && matchesPriority
  })

  const stats = {
    totalTickets: tickets.length,
    openTickets: tickets.filter(t => t.status === 'open').length,
    inProgressTickets: tickets.filter(t => t.status === 'in_progress').length,
    avgResponseTime: '2.4 hours',
    customerSatisfaction: 4.6,
    resolutionRate: 89.3,
    urgentTickets: tickets.filter(t => t.priority === 'urgent').length
  }

  const handleSendMessage = () => {
    if (newMessage.trim() && selectedTicket) {
      const message: Message = {
        id: `MSG_${Date.now()}`,
        ticketId: selectedTicket.id,
        sender: 'Support Agent',
        senderType: 'agent',
        content: newMessage,
        timestamp: new Date().toISOString()
      }
      setMessages(prev => [...prev, message])
      setNewMessage('')
      
      // Update ticket last activity
      setTickets(prev => prev.map(t => 
        t.id === selectedTicket.id 
          ? { ...t, lastActivity: new Date().toISOString(), messages: t.messages + 1 }
          : t
      ))
    }
  }

  const renderTicketsList = () => (
    <div className="space-y-6">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Tickets</p>
              <p className="text-2xl font-bold text-gray-900">{stats.totalTickets}</p>
            </div>
            <DocumentTextIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Open</p>
              <p className="text-2xl font-bold text-red-600">{stats.openTickets}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">In Progress</p>
              <p className="text-2xl font-bold text-blue-600">{stats.inProgressTickets}</p>
            </div>
            <ClockIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Avg Response</p>
              <p className="text-2xl font-bold text-green-600">{stats.avgResponseTime}</p>
            </div>
            <ChatBubbleLeftRightIcon className="w-8 h-8 text-green-500" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search tickets by subject, customer, or ID..."
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
            <option value="open">Open</option>
            <option value="in_progress">In Progress</option>
            <option value="waiting_customer">Waiting Customer</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </select>
          <select
            value={filterPriority}
            onChange={(e) => setFilterPriority(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500"
          >
            <option value="all">All Priority</option>
            <option value="urgent">Urgent</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>
      </div>

      {/* Tickets List */}
      <div className="bg-white rounded-lg shadow-sm border overflow-hidden">
        <div className="divide-y divide-gray-200">
          {filteredTickets.map((ticket) => (
            <div 
              key={ticket.id} 
              className="p-6 hover:bg-gray-50 cursor-pointer"
              onClick={() => setSelectedTicket(ticket)}
            >
              <div className="flex items-start justify-between">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-sm font-medium text-gray-900">{ticket.id}</span>
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(ticket.status)}`}>
                      {ticket.status.replace('_', ' ')}
                    </span>
                    <span className={`text-sm font-medium ${getPriorityColor(ticket.priority)}`}>
                      {ticket.priority.toUpperCase()}
                    </span>
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">{ticket.subject}</h3>
                  <p className="text-sm text-gray-600 mb-3 line-clamp-2">{ticket.description}</p>
                  <div className="flex items-center gap-4 text-sm text-gray-500">
                    <div className="flex items-center">
                      <UserIcon className="w-4 h-4 mr-1" />
                      {ticket.customerName} ({ticket.customerType})
                    </div>
                    <div className="flex items-center">
                      <ChatBubbleLeftRightIcon className="w-4 h-4 mr-1" />
                      {ticket.messages} messages
                    </div>
                    <div className="flex items-center">
                      <ClockIcon className="w-4 h-4 mr-1" />
                      {new Date(ticket.lastActivity).toLocaleString()}
                    </div>
                    {ticket.assignedTo && (
                      <div className="flex items-center">
                        <TagIcon className="w-4 h-4 mr-1" />
                        {ticket.assignedTo}
                      </div>
                    )}
                  </div>
                  <div className="flex flex-wrap gap-1 mt-2">
                    {ticket.tags.map((tag) => (
                      <span key={tag} className="inline-flex px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
                <div className="ml-4 flex-shrink-0">
                  <span className="text-sm text-gray-500">{ticket.category.replace('_', ' ')}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderTicketDetail = () => {
    if (!selectedTicket) return null

    const ticketMessages = messages.filter(m => m.ticketId === selectedTicket.id)

    return (
      <div className="bg-white rounded-lg shadow-sm border h-full flex flex-col">
        {/* Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-xl font-semibold text-gray-900">{selectedTicket.subject}</h2>
              <p className="text-sm text-gray-600 mt-1">
                {selectedTicket.customerName} • {selectedTicket.id} • {selectedTicket.category.replace('_', ' ')}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className={`inline-flex px-3 py-1 text-sm font-medium rounded-full ${getStatusColor(selectedTicket.status)}`}>
                {selectedTicket.status.replace('_', ' ')}
              </span>
              <span className={`text-sm font-medium ${getPriorityColor(selectedTicket.priority)}`}>
                {selectedTicket.priority.toUpperCase()}
              </span>
            </div>
          </div>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {ticketMessages.map((message) => (
            <div key={message.id} className={`flex ${message.senderType === 'agent' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-3/4 rounded-lg p-4 ${
                message.senderType === 'agent' 
                  ? 'bg-blue-500 text-white' 
                  : message.senderType === 'system'
                  ? 'bg-gray-100 text-gray-800 border'
                  : 'bg-gray-100 text-gray-900'
              }`}>
                <div className="flex items-center justify-between mb-2">
                  <span className="font-medium text-sm">{message.sender}</span>
                  <span className={`text-xs ${message.senderType === 'agent' ? 'text-blue-100' : 'text-gray-500'}`}>
                    {new Date(message.timestamp).toLocaleString()}
                  </span>
                </div>
                <p className="text-sm">{message.content}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Message Input */}
        <div className="p-6 border-t border-gray-200">
          <div className="flex gap-4">
            <input
              type="text"
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type your message..."
              className="flex-1 px-4 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
            />
            <button
              onClick={handleSendMessage}
              className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 flex items-center gap-2"
            >
              <PaperAirplaneIcon className="w-5 h-5" />
              Send
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Customer Support Center</h1>
        <p className="text-gray-600">Manage support tickets, customer communication, and help resources</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'tickets', name: 'Support Tickets', icon: DocumentTextIcon },
            { id: 'chat', name: 'Live Chat', icon: ChatBubbleLeftRightIcon },
            { id: 'analytics', name: 'Analytics', icon: ChartBarIcon },
            { id: 'knowledge', name: 'Knowledge Base', icon: DocumentTextIcon }
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
      {activeTab === 'tickets' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div>
            {renderTicketsList()}
          </div>
          <div>
            {selectedTicket ? renderTicketDetail() : (
              <div className="bg-white rounded-lg shadow-sm border h-96 flex items-center justify-center">
                <div className="text-center">
                  <ChatBubbleLeftRightIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-600">Select a ticket to view details and messages</p>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
      
      {activeTab === 'chat' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <ChatBubbleLeftRightIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Live Chat Interface</h3>
          <p className="text-gray-600">Real-time customer chat support coming soon</p>
        </div>
      )}
      
      {activeTab === 'analytics' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Support Analytics</h3>
          <p className="text-gray-600">Response times, satisfaction scores, and performance metrics</p>
        </div>
      )}
      
      {activeTab === 'knowledge' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <DocumentTextIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Knowledge Base</h3>
          <p className="text-gray-600">Help articles, FAQs, and customer resources management</p>
        </div>
      )}
    </div>
  )
}
