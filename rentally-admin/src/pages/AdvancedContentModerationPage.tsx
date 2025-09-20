import { useState } from 'react'
import { 
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  ExclamationTriangleIcon,
  ShieldCheckIcon,
  ClockIcon,
  FlagIcon,
  CameraIcon,
  ChatBubbleLeftRightIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline'

interface ContentItem {
  id: string
  type: 'property_photo' | 'profile_photo' | 'review' | 'listing_description' | 'message'
  status: 'pending' | 'approved' | 'rejected' | 'flagged' | 'under_review'
  priority: 'low' | 'medium' | 'high' | 'urgent'
  submittedBy: string
  submittedById: string
  submittedAt: string
  content: string
  imageUrl?: string
  riskScore: number
  aiFlags: string[]
  reportReasons?: string[]
  reviewedBy?: string
  reviewedAt?: string
  reviewNotes?: string
  relatedItemId?: string
  relatedItemType?: 'property' | 'user' | 'booking'
}

interface FraudAlert {
  id: string
  type: 'fake_listing' | 'identity_theft' | 'payment_fraud' | 'review_manipulation' | 'account_takeover'
  severity: 'low' | 'medium' | 'high' | 'critical'
  userId: string
  userName: string
  description: string
  detectedAt: string
  status: 'active' | 'investigating' | 'resolved' | 'false_positive'
  evidence: string[]
  confidenceScore: number
  actionsTaken: string[]
}

const mockContentItems: ContentItem[] = [
  {
    id: 'CNT_001',
    type: 'property_photo',
    status: 'pending',
    priority: 'high',
    submittedBy: 'Sarah Johnson',
    submittedById: 'HOST_001',
    submittedAt: '2024-01-20T10:30:00Z',
    content: 'Luxury apartment main bedroom photo',
    imageUrl: '/api/placeholder/400/300',
    riskScore: 85,
    aiFlags: ['Potential Stock Photo', 'Quality Issues'],
    relatedItemId: 'PR_001',
    relatedItemType: 'property'
  },
  {
    id: 'CNT_002',
    type: 'review',
    status: 'flagged',
    priority: 'urgent',
    submittedBy: 'Anonymous User',
    submittedById: 'USR_456',
    submittedAt: '2024-01-19T14:22:00Z',
    content: 'This place was absolutely terrible. The host was rude and the place was dirty. I demand a full refund immediately!',
    riskScore: 92,
    aiFlags: ['Aggressive Language', 'Potential Fake Review'],
    reportReasons: ['Inappropriate Content', 'Fraudulent Review'],
    relatedItemId: 'PR_002',
    relatedItemType: 'property'
  },
  {
    id: 'CNT_003',
    type: 'profile_photo',
    status: 'under_review',
    priority: 'medium',
    submittedBy: 'Mike Chen',
    submittedById: 'USR_789',
    submittedAt: '2024-01-18T09:15:00Z',
    content: 'User profile photo update',
    imageUrl: '/api/placeholder/150/150',
    riskScore: 45,
    aiFlags: ['Face Recognition Mismatch'],
    reviewedBy: 'Admin User',
    reviewedAt: '2024-01-18T10:00:00Z',
    reviewNotes: 'Investigating potential identity mismatch'
  }
]

const mockFraudAlerts: FraudAlert[] = [
  {
    id: 'FRAUD_001',
    type: 'fake_listing',
    severity: 'critical',
    userId: 'HOST_999',
    userName: 'Suspicious Host',
    description: 'Multiple identical property listings detected across different locations',
    detectedAt: '2024-01-20T08:00:00Z',
    status: 'investigating',
    evidence: ['Duplicate Photos', 'Same Description Text', 'Different Addresses'],
    confidenceScore: 95,
    actionsTaken: ['Account Suspended', 'Listings Removed']
  },
  {
    id: 'FRAUD_002', 
    type: 'review_manipulation',
    severity: 'high',
    userId: 'USR_888',
    userName: 'Review Bot',
    description: 'Coordinated fake positive reviews from multiple accounts',
    detectedAt: '2024-01-19T16:30:00Z',
    status: 'active',
    evidence: ['Similar Review Patterns', 'Account Creation Dates', 'IP Address Clustering'],
    confidenceScore: 87,
    actionsTaken: ['Reviews Flagged']
  }
]

export default function AdvancedContentModerationPage() {
  const [activeTab, setActiveTab] = useState<'content' | 'fraud' | 'reports' | 'settings'>('content')
  const [contentItems, setContentItems] = useState<ContentItem[]>(mockContentItems)
  const [fraudAlerts] = useState<FraudAlert[]>(mockFraudAlerts)
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterType, setFilterType] = useState('all')

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved': return 'bg-green-100 text-green-800'
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      case 'flagged': return 'bg-orange-100 text-orange-800'
      case 'under_review': return 'bg-blue-100 text-blue-800'
      case 'investigating': return 'bg-purple-100 text-purple-800'
      case 'resolved': return 'bg-green-100 text-green-800'
      case 'active': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent': return 'text-red-600'
      case 'high': return 'text-orange-600'
      case 'medium': return 'text-yellow-600'
      case 'low': return 'text-green-600'
      default: return 'text-gray-600'
    }
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200'
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200'
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200'
      case 'low': return 'bg-blue-100 text-blue-800 border-blue-200'
      default: return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const handleApproveContent = (itemId: string) => {
    setContentItems(prev => prev.map(item => 
      item.id === itemId 
        ? { ...item, status: 'approved', reviewedAt: new Date().toISOString(), reviewedBy: 'Current Admin' }
        : item
    ))
  }

  const handleRejectContent = (itemId: string) => {
    setContentItems(prev => prev.map(item => 
      item.id === itemId 
        ? { ...item, status: 'rejected', reviewedAt: new Date().toISOString(), reviewedBy: 'Current Admin' }
        : item
    ))
  }

  const stats = {
    pendingReviews: contentItems.filter(item => item.status === 'pending').length,
    flaggedContent: contentItems.filter(item => item.status === 'flagged').length,
    activeFraudAlerts: fraudAlerts.filter(alert => alert.status === 'active').length,
    contentProcessedToday: 47,
    averageResponseTime: '2.3 hours',
    automationAccuracy: 94.2
  }

  const renderContentModeration = () => (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Pending Reviews</p>
              <p className="text-2xl font-bold text-yellow-600">{stats.pendingReviews}</p>
            </div>
            <ClockIcon className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Flagged Content</p>
              <p className="text-2xl font-bold text-red-600">{stats.flaggedContent}</p>
            </div>
            <FlagIcon className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Fraud Alerts</p>
              <p className="text-2xl font-bold text-orange-600">{stats.activeFraudAlerts}</p>
            </div>
            <ExclamationTriangleIcon className="w-8 h-8 text-orange-500" />
          </div>
        </div>
        <div className="bg-white p-4 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">AI Accuracy</p>
              <p className="text-2xl font-bold text-blue-600">{stats.automationAccuracy}%</p>
            </div>
            <ShieldCheckIcon className="w-8 h-8 text-blue-500" />
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <div className="flex gap-4">
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="all">All Status</option>
            <option value="pending">Pending</option>
            <option value="flagged">Flagged</option>
            <option value="under_review">Under Review</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md"
          >
            <option value="all">All Types</option>
            <option value="property_photo">Property Photos</option>
            <option value="profile_photo">Profile Photos</option>
            <option value="review">Reviews</option>
            <option value="listing_description">Descriptions</option>
            <option value="message">Messages</option>
          </select>
        </div>
      </div>

      {/* Content Items */}
      <div className="bg-white rounded-lg shadow-sm border">
        <div className="p-6 border-b">
          <h3 className="text-lg font-semibold">Content Queue</h3>
        </div>
        <div className="divide-y divide-gray-200">
          {contentItems.map((item) => (
            <div key={item.id} className="p-6 hover:bg-gray-50">
              <div className="flex items-start justify-between">
                <div className="flex space-x-4">
                  <div className="flex-shrink-0">
                    {item.imageUrl ? (
                      <div className="w-16 h-16 bg-gray-200 rounded-lg flex items-center justify-center">
                        <CameraIcon className="w-8 h-8 text-gray-400" />
                      </div>
                    ) : (
                      <div className="w-16 h-16 bg-blue-100 rounded-lg flex items-center justify-center">
                        <ChatBubbleLeftRightIcon className="w-8 h-8 text-blue-500" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-2">
                      <span className="text-sm font-medium text-gray-900">
                        {item.type.replace('_', ' ').toUpperCase()}
                      </span>
                      <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(item.status)}`}>
                        {item.status.replace('_', ' ')}
                      </span>
                      <span className={`text-sm font-medium ${getPriorityColor(item.priority)}`}>
                        {item.priority.toUpperCase()}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 mb-2">
                      by {item.submittedBy} • {new Date(item.submittedAt).toLocaleString()}
                    </p>
                    <p className="text-sm text-gray-900 mb-2">{item.content}</p>
                    <div className="flex flex-wrap gap-1 mb-2">
                      {item.aiFlags.map((flag, index) => (
                        <span key={index} className="inline-flex px-2 py-1 text-xs bg-red-100 text-red-800 rounded-full">
                          {flag}
                        </span>
                      ))}
                    </div>
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <span>Risk Score: <span className={`font-medium ${item.riskScore > 70 ? 'text-red-600' : item.riskScore > 40 ? 'text-yellow-600' : 'text-green-600'}`}>{item.riskScore}</span></span>
                      {item.reviewedBy && (
                        <span>Reviewed by {item.reviewedBy}</span>
                      )}
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 text-blue-600 hover:bg-blue-50 rounded-md">
                    <EyeIcon className="w-5 h-5" />
                  </button>
                  {item.status === 'pending' && (
                    <>
                      <button 
                        onClick={() => handleApproveContent(item.id)}
                        className="p-2 text-green-600 hover:bg-green-50 rounded-md"
                      >
                        <CheckIcon className="w-5 h-5" />
                      </button>
                      <button 
                        onClick={() => handleRejectContent(item.id)}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-md"
                      >
                        <XMarkIcon className="w-5 h-5" />
                      </button>
                    </>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderFraudDetection = () => (
    <div className="space-y-6">
      <div className="bg-white rounded-lg shadow-sm border">
        <div className="p-6 border-b">
          <h3 className="text-lg font-semibold">Active Fraud Alerts</h3>
        </div>
        <div className="divide-y divide-gray-200">
          {fraudAlerts.map((alert) => (
            <div key={alert.id} className={`p-6 border-l-4 ${getSeverityColor(alert.severity)}`}>
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-2">
                    <ExclamationTriangleIcon className="w-5 h-5 text-red-500" />
                    <span className="font-medium text-gray-900">
                      {alert.type.replace('_', ' ').toUpperCase()}
                    </span>
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full border ${getSeverityColor(alert.severity)}`}>
                      {alert.severity.toUpperCase()}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-2">
                    User: {alert.userName} (ID: {alert.userId})
                  </p>
                  <p className="text-sm text-gray-900 mb-3">{alert.description}</p>
                  <div className="mb-3">
                    <p className="text-sm font-medium text-gray-700 mb-1">Evidence:</p>
                    <ul className="text-sm text-gray-600 space-y-1">
                      {alert.evidence.map((evidence, index) => (
                        <li key={index} className="flex items-center">
                          <span className="w-2 h-2 bg-red-400 rounded-full mr-2"></span>
                          {evidence}
                        </li>
                      ))}
                    </ul>
                  </div>
                  <div className="mb-3">
                    <p className="text-sm font-medium text-gray-700 mb-1">Actions Taken:</p>
                    <div className="flex flex-wrap gap-1">
                      {alert.actionsTaken.map((action, index) => (
                        <span key={index} className="inline-flex px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
                          {action}
                        </span>
                      ))}
                    </div>
                  </div>
                  <div className="flex items-center gap-4 text-sm text-gray-500">
                    <span>Confidence: <span className="font-medium">{alert.confidenceScore}%</span></span>
                    <span>Detected: {new Date(alert.detectedAt).toLocaleString()}</span>
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(alert.status)}`}>
                      {alert.status.replace('_', ' ')}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-2 ml-4">
                  <button className="px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded-md border border-blue-200">
                    Investigate
                  </button>
                  <button className="px-3 py-1 text-sm text-green-600 hover:bg-green-50 rounded-md border border-green-200">
                    Resolve
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Content Moderation & Fraud Detection</h1>
        <p className="text-gray-600">AI-powered content review, fraud detection, and safety monitoring</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {[
            { id: 'content', name: 'Content Queue', icon: CameraIcon },
            { id: 'fraud', name: 'Fraud Alerts', icon: ShieldCheckIcon },
            { id: 'reports', name: 'User Reports', icon: FlagIcon },
            { id: 'settings', name: 'AI Settings', icon: ArrowPathIcon }
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
      {activeTab === 'content' && renderContentModeration()}
      {activeTab === 'fraud' && renderFraudDetection()}
      {activeTab === 'reports' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <FlagIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">User Reports</h3>
          <p className="text-gray-600">User-reported content and disputes coming soon</p>
        </div>
      )}
      {activeTab === 'settings' && (
        <div className="bg-white p-12 rounded-lg shadow-sm border text-center">
          <ArrowPathIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">AI Configuration</h3>
          <p className="text-gray-600">Configure AI moderation rules and thresholds</p>
        </div>
      )}
    </div>
  )
}
