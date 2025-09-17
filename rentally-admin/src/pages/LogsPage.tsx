import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { FunnelIcon, ArrowPathIcon } from '@heroicons/react/24/outline'

interface LogItem {
  id: string
  level: 'info' | 'warn' | 'error'
  source: 'api' | 'worker' | 'web'
  message: string
  timestamp: string
  context?: Record<string, any>
}

const mockLogs: LogItem[] = [
  { id: 'l1', level: 'info', source: 'api', message: 'Server started on port 5000', timestamp: new Date().toISOString() },
  { id: 'l2', level: 'warn', source: 'worker', message: 'High queue latency detected', timestamp: new Date(Date.now() - 60000).toISOString() },
  { id: 'l3', level: 'error', source: 'api', message: 'Database connection timeout', timestamp: new Date(Date.now() - 120000).toISOString() },
]

export default function LogsPage() {
  const [level, setLevel] = useState<'all' | LogItem['level']>('all')
  const [source, setSource] = useState<'all' | LogItem['source']>('all')

  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['logs', level, source],
    queryFn: async () => {
      // TODO: replace with API call: GET /api/admin/logs
      return mockLogs.filter((log) => {
        const matchesLevel = level === 'all' || log.level === level
        const matchesSource = source === 'all' || log.source === source
        return matchesLevel && matchesSource
      })
    },
    refetchInterval: 10000,
  })

  const levelBadge = (lvl: LogItem['level']) => lvl === 'error' ? 'bg-red-100 text-red-800' : lvl === 'warn' ? 'bg-yellow-100 text-yellow-800' : 'bg-blue-100 text-blue-800'

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">System Logs</h1>
          <p className="mt-1 text-sm text-gray-500">Monitor API, worker and web logs</p>
        </div>
        <button className="btn-outline" onClick={() => refetch()}>
          <ArrowPathIcon className={`h-5 w-5 mr-2 ${isFetching ? 'animate-spin' : ''}`} /> Refresh
        </button>
      </div>

      <div className="card p-4 flex flex-col sm:flex-row gap-4">
        <select className="input w-full sm:w-auto" value={level} onChange={(e) => setLevel(e.target.value as any)}>
          <option value="all">All Levels</option>
          <option value="info">Info</option>
          <option value="warn">Warning</option>
          <option value="error">Error</option>
        </select>
        <select className="input w-full sm:w-auto" value={source} onChange={(e) => setSource(e.target.value as any)}>
          <option value="all">All Sources</option>
          <option value="api">API</option>
          <option value="worker">Worker</option>
          <option value="web">Web</option>
        </select>
      </div>

      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Level</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Source</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Message</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {isLoading ? (
                <tr><td className="px-6 py-4" colSpan={4}>Loading...</td></tr>
              ) : (
                data?.map((log) => (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{new Date(log.timestamp).toLocaleString()}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${levelBadge(log.level)}`}>{log.level}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{log.source}</td>
                    <td className="px-6 py-4 text-sm text-gray-900">{log.message}</td>
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
