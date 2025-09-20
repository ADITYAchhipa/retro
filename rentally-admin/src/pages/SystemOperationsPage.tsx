import { useState } from 'react'
import {
  CogIcon,
  ServerIcon,
  ShieldCheckIcon,
  ChartBarIcon,
  CheckCircleIcon,
  DocumentTextIcon,
  CircleStackIcon,
  CloudIcon,
  WifiIcon,
  CpuChipIcon,
  EyeIcon,
  ArrowPathIcon
} from '@heroicons/react/24/outline'

interface SystemMetrics {
  server: {
    cpu: number
    memory: number
    disk: number
    uptime: string
    status: 'healthy' | 'warning' | 'critical'
  }
  database: {
    connections: number
    queries: number
    responseTime: number
    status: 'healthy' | 'warning' | 'critical'
  }
  cache: {
    hitRate: number
    memory: number
    status: 'healthy' | 'warning' | 'critical'
  }
  api: {
    requests: number
    latency: number
    errorRate: number
    status: 'healthy' | 'warning' | 'critical'
  }
}

interface SecurityEvent {
  id: string
  type: 'login_attempt' | 'data_access' | 'permission_change' | 'suspicious_activity'
  severity: 'low' | 'medium' | 'high' | 'critical'
  description: string
  user: string
  timestamp: string
  ip: string
  action: 'blocked' | 'allowed' | 'flagged'
}

export default function SystemOperationsPage() {
  const [activeTab, setActiveTab] = useState('overview')

  // Mock data
  const systemMetrics: SystemMetrics = {
    server: {
      cpu: 68,
      memory: 74,
      disk: 45,
      uptime: '15d 8h 42m',
      status: 'healthy'
    },
    database: {
      connections: 147,
      queries: 2847,
      responseTime: 23,
      status: 'healthy'
    },
    cache: {
      hitRate: 94.7,
      memory: 82,
      status: 'healthy'
    },
    api: {
      requests: 15847,
      latency: 89,
      errorRate: 0.12,
      status: 'healthy'
    }
  }

  const securityEvents: SecurityEvent[] = [
    {
      id: '1',
      type: 'suspicious_activity',
      severity: 'high',
      description: 'Multiple failed login attempts from unusual location',
      user: 'john.doe@example.com',
      timestamp: '2024-01-15 14:30:25',
      ip: '192.168.1.100',
      action: 'blocked'
    },
    {
      id: '2',
      type: 'data_access',
      severity: 'medium',
      description: 'Bulk user data export requested',
      user: 'admin@rentally.com',
      timestamp: '2024-01-15 13:45:12',
      ip: '10.0.0.50',
      action: 'allowed'
    },
    {
      id: '3',
      type: 'permission_change',
      severity: 'low',
      description: 'User role updated to Super Admin',
      user: 'system',
      timestamp: '2024-01-15 12:15:33',
      ip: '127.0.0.1',
      action: 'allowed'
    }
  ]

  const tabs = [
    { id: 'overview', name: 'System Overview', icon: ChartBarIcon },
    { id: 'monitoring', name: 'Monitoring', icon: EyeIcon },
    { id: 'security', name: 'Security', icon: ShieldCheckIcon },
    { id: 'configuration', name: 'Configuration', icon: CogIcon },
    { id: 'logs', name: 'System Logs', icon: DocumentTextIcon },
    { id: 'maintenance', name: 'Maintenance', icon: ArrowPathIcon }
  ]

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy':
        return 'text-green-600 bg-green-100'
      case 'warning':
        return 'text-yellow-600 bg-yellow-100'
      case 'critical':
        return 'text-red-600 bg-red-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'low':
        return 'text-blue-600 bg-blue-100'
      case 'medium':
        return 'text-yellow-600 bg-yellow-100'
      case 'high':
        return 'text-orange-600 bg-orange-100'
      case 'critical':
        return 'text-red-600 bg-red-100'
      default:
        return 'text-gray-600 bg-gray-100'
    }
  }

  const renderOverview = () => (
    <div className="space-y-6">
      {/* System Health Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Server Status</p>
              <p className="text-2xl font-bold text-gray-900">Online</p>
              <p className="text-xs text-gray-500">Uptime: {systemMetrics.server.uptime}</p>
            </div>
            <div className={`p-3 rounded-full ${getStatusColor(systemMetrics.server.status)}`}>
              <ServerIcon className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Database</p>
              <p className="text-2xl font-bold text-gray-900">{systemMetrics.database.connections}</p>
              <p className="text-xs text-gray-500">Active connections</p>
            </div>
            <div className={`p-3 rounded-full ${getStatusColor(systemMetrics.database.status)}`}>
              <CircleStackIcon className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Cache Hit Rate</p>
              <p className="text-2xl font-bold text-gray-900">{systemMetrics.cache.hitRate}%</p>
              <p className="text-xs text-gray-500">Memory: {systemMetrics.cache.memory}%</p>
            </div>
            <div className={`p-3 rounded-full ${getStatusColor(systemMetrics.cache.status)}`}>
              <CpuChipIcon className="w-6 h-6" />
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">API Health</p>
              <p className="text-2xl font-bold text-gray-900">{systemMetrics.api.latency}ms</p>
              <p className="text-xs text-gray-500">Avg latency</p>
            </div>
            <div className={`p-3 rounded-full ${getStatusColor(systemMetrics.api.status)}`}>
              <CloudIcon className="w-6 h-6" />
            </div>
          </div>
        </div>
      </div>

      {/* Resource Usage */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Resource Usage</h3>
        <div className="space-y-4">
          <div>
            <div className="flex justify-between text-sm text-gray-600 mb-1">
              <span>CPU Usage</span>
              <span>{systemMetrics.server.cpu}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-blue-500 h-2 rounded-full" style={{ width: `${systemMetrics.server.cpu}%` }}></div>
            </div>
          </div>
          <div>
            <div className="flex justify-between text-sm text-gray-600 mb-1">
              <span>Memory Usage</span>
              <span>{systemMetrics.server.memory}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-green-500 h-2 rounded-full" style={{ width: `${systemMetrics.server.memory}%` }}></div>
            </div>
          </div>
          <div>
            <div className="flex justify-between text-sm text-gray-600 mb-1">
              <span>Disk Usage</span>
              <span>{systemMetrics.server.disk}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-2">
              <div className="bg-yellow-500 h-2 rounded-full" style={{ width: `${systemMetrics.server.disk}%` }}></div>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Alerts */}
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Recent Alerts</h3>
        <div className="space-y-3">
          {securityEvents.slice(0, 3).map((event) => (
            <div key={event.id} className="flex items-center justify-between border-l-4 border-orange-400 pl-4 py-2">
              <div>
                <p className="text-sm font-medium text-gray-900">{event.description}</p>
                <p className="text-xs text-gray-500">{event.timestamp} - {event.user}</p>
              </div>
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${getSeverityColor(event.severity)}`}>
                {event.severity}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderMonitoring = () => (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Performance Metrics</h3>
        <div className="h-64 bg-gray-50 rounded-lg flex items-center justify-center">
          <div className="text-center">
            <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-2" />
            <p className="text-gray-500">Real-time performance charts</p>
            <p className="text-sm text-gray-400">CPU, Memory, Network, Disk I/O</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Active Services</h3>
          <div className="space-y-3">
            {['Web Server', 'Database', 'Redis Cache', 'Message Queue', 'File Storage'].map((service) => (
              <div key={service} className="flex items-center justify-between">
                <span className="text-sm text-gray-900">{service}</span>
                <div className="flex items-center">
                  <CheckCircleIcon className="w-4 h-4 text-green-500 mr-2" />
                  <span className="text-xs text-green-600">Running</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Network Status</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">CDN Status</span>
              <div className="flex items-center">
                <WifiIcon className="w-4 h-4 text-green-500 mr-2" />
                <span className="text-xs text-green-600">Healthy</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Load Balancer</span>
              <div className="flex items-center">
                <CheckCircleIcon className="w-4 h-4 text-green-500 mr-2" />
                <span className="text-xs text-green-600">Active</span>
              </div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">SSL Certificates</span>
              <div className="flex items-center">
                <ShieldCheckIcon className="w-4 h-4 text-green-500 mr-2" />
                <span className="text-xs text-green-600">Valid</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )

  const renderSecurity = () => (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Security Events</h3>
        <div className="space-y-4">
          {securityEvents.map((event) => (
            <div key={event.id} className="border border-gray-200 rounded-lg p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium mr-3 ${getSeverityColor(event.severity)}`}>
                    {event.severity}
                  </span>
                  <span className="text-sm font-medium text-gray-900">{event.type.replace('_', ' ')}</span>
                </div>
                <span className={`px-2 py-1 rounded text-xs ${
                  event.action === 'blocked' ? 'bg-red-100 text-red-800' :
                  event.action === 'allowed' ? 'bg-green-100 text-green-800' :
                  'bg-yellow-100 text-yellow-800'
                }`}>
                  {event.action}
                </span>
              </div>
              <p className="text-sm text-gray-700 mb-2">{event.description}</p>
              <div className="text-xs text-gray-500">
                <span>User: {event.user}</span> | 
                <span> IP: {event.ip}</span> | 
                <span> Time: {event.timestamp}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderConfiguration = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">System Settings</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Maintenance Mode</span>
              <button className="bg-gray-200 relative inline-flex h-6 w-11 items-center rounded-full">
                <span className="translate-x-1 inline-block h-4 w-4 transform rounded-full bg-white transition"></span>
              </button>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Debug Logging</span>
              <button className="bg-blue-600 relative inline-flex h-6 w-11 items-center rounded-full">
                <span className="translate-x-6 inline-block h-4 w-4 transform rounded-full bg-white transition"></span>
              </button>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Auto Backups</span>
              <button className="bg-blue-600 relative inline-flex h-6 w-11 items-center rounded-full">
                <span className="translate-x-6 inline-block h-4 w-4 transform rounded-full bg-white transition"></span>
              </button>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Security Settings</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Two-Factor Auth</span>
              <button className="bg-blue-600 relative inline-flex h-6 w-11 items-center rounded-full">
                <span className="translate-x-6 inline-block h-4 w-4 transform rounded-full bg-white transition"></span>
              </button>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">IP Restrictions</span>
              <button className="bg-blue-600 relative inline-flex h-6 w-11 items-center rounded-full">
                <span className="translate-x-6 inline-block h-4 w-4 transform rounded-full bg-white transition"></span>
              </button>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-900">Session Timeout</span>
              <select className="text-sm border border-gray-300 rounded px-2 py-1">
                <option>30 minutes</option>
                <option>1 hour</option>
                <option>4 hours</option>
                <option>8 hours</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Environment Variables</h3>
        <div className="space-y-3">
          {[
            { key: 'APP_ENV', value: 'production', masked: false },
            { key: 'DATABASE_URL', value: 'postgresql://***', masked: true },
            { key: 'REDIS_URL', value: 'redis://***', masked: true },
            { key: 'JWT_SECRET', value: '***', masked: true },
            { key: 'STRIPE_API_KEY', value: 'sk_live_***', masked: true }
          ].map((env) => (
            <div key={env.key} className="flex items-center justify-between border-b border-gray-100 pb-2">
              <span className="text-sm font-medium text-gray-900">{env.key}</span>
              <span className="text-sm text-gray-600 font-mono">{env.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderLogs = () => (
    <div className="space-y-6">
      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900">System Logs</h3>
          <div className="flex space-x-2">
            <select className="text-sm border border-gray-300 rounded px-3 py-1">
              <option>All Levels</option>
              <option>Error</option>
              <option>Warning</option>
              <option>Info</option>
              <option>Debug</option>
            </select>
            <button className="bg-blue-600 text-white px-3 py-1 rounded text-sm">Refresh</button>
          </div>
        </div>
        <div className="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm h-96 overflow-y-auto">
          <div>[2024-01-15 14:30:25] INFO: Application started successfully</div>
          <div>[2024-01-15 14:30:26] INFO: Database connection established</div>
          <div>[2024-01-15 14:30:27] INFO: Redis cache connected</div>
          <div>[2024-01-15 14:35:12] WARN: High memory usage detected (85%)</div>
          <div>[2024-01-15 14:40:33] ERROR: Payment processing failed for booking #12345</div>
          <div>[2024-01-15 14:45:01] INFO: Backup completed successfully</div>
          <div>[2024-01-15 14:50:18] DEBUG: User authentication successful (user_id: 789)</div>
          <div>[2024-01-15 14:55:42] WARN: Rate limit exceeded for IP 192.168.1.100</div>
        </div>
      </div>
    </div>
  )

  const renderMaintenance = () => (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Database Maintenance</h3>
          <div className="space-y-3">
            <button className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-blue-700">
              Run Database Cleanup
            </button>
            <button className="w-full bg-green-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-green-700">
              Optimize Indexes
            </button>
            <button className="w-full bg-purple-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-purple-700">
              Create Backup
            </button>
            <button className="w-full bg-orange-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-orange-700">
              Analyze Performance
            </button>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-sm border">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Cache Management</h3>
          <div className="space-y-3">
            <button className="w-full bg-red-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-red-700">
              Clear All Cache
            </button>
            <button className="w-full bg-yellow-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-yellow-700">
              Clear User Sessions
            </button>
            <button className="w-full bg-indigo-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-indigo-700">
              Warm Up Cache
            </button>
            <button className="w-full bg-gray-600 text-white py-2 px-4 rounded-lg text-sm hover:bg-gray-700">
              Cache Statistics
            </button>
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Scheduled Maintenance</h3>
        <div className="space-y-4">
          {[
            { task: 'Daily Database Backup', schedule: 'Every day at 2:00 AM', status: 'active' },
            { task: 'Weekly Performance Analysis', schedule: 'Every Sunday at 1:00 AM', status: 'active' },
            { task: 'Monthly Security Scan', schedule: 'First day of month at 3:00 AM', status: 'active' },
            { task: 'Quarterly System Update', schedule: 'Every 3 months', status: 'pending' }
          ].map((maintenance, index) => (
            <div key={index} className="flex items-center justify-between border border-gray-200 rounded-lg p-4">
              <div>
                <p className="text-sm font-medium text-gray-900">{maintenance.task}</p>
                <p className="text-xs text-gray-500">{maintenance.schedule}</p>
              </div>
              <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                maintenance.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
              }`}>
                {maintenance.status}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  )

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return renderOverview()
      case 'monitoring':
        return renderMonitoring()
      case 'security':
        return renderSecurity()
      case 'configuration':
        return renderConfiguration()
      case 'logs':
        return renderLogs()
      case 'maintenance':
        return renderMaintenance()
      default:
        return renderOverview()
    }
  }

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">System Operations</h1>
        <p className="text-gray-600 mt-2">Monitor, configure, and maintain system infrastructure</p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-gray-200 mb-8">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => {
            const Icon = tab.icon
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`group inline-flex items-center py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <Icon className="w-5 h-5 mr-2" />
                {tab.name}
              </button>
            )
          })}
        </nav>
      </div>

      {/* Tab Content */}
      {renderContent()}
    </div>
  )
}
