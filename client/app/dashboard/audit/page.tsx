'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';
import { Search, Filter, ShieldAlert, RefreshCw } from 'lucide-react';

interface AuditLog {
    username: string;
    action: string;
    object_name: string;
    timestamp: string;
    return_code: number; // 0 = Success, others = Fail
    privilege_used: string;
    terminal: string;
    sql_text?: string;
}

export default function AuditPage() {
    const [logs, setLogs] = useState<AuditLog[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    
    // Filters
    const [filterUser, setFilterUser] = useState('');
    const [filterAction, setFilterAction] = useState('');
    
    useEffect(() => {
        loadLogs();
    }, []); // Initial load

    const loadLogs = async () => {
        try {
            setLoading(true);
            // Construct query params
            const params = new URLSearchParams();
            if (filterUser) params.append('username', filterUser);
            if (filterAction && filterAction !== 'ALL') params.append('action', filterAction);
            params.append('limit', '100'); // Always get latest 100

            const data = await apiRequest(`/audit?${params.toString()}`); 
            setLogs(data);
            setError('');
        } catch (err: any) {
             if (err.message.includes('403') || err.message.includes('ORA-00942')) {
                setError('Bạn không có quyền xem Audit Log.');
            } else {
                setError(err.message);
                // Fallback empty data if error to avoid crash
                setLogs([]);
            }
        } finally {
            setLoading(false);
        }
    };

    const getActionColor = (action: string) => {
        switch (action) {
            case 'DELETE':
            case 'DROP':
            case 'TRUNCATE':
                return 'text-red-600 bg-red-50 border-red-100';
            case 'INSERT':
            case 'UPDATE':
            case 'CREATE':
            case 'ALTER':
                return 'text-blue-600 bg-blue-50 border-blue-100';
            case 'SELECT':
                return 'text-gray-600 bg-gray-50 border-gray-100';
            case 'LOGON':
            case 'LOGOFF':
                return 'text-green-600 bg-green-50 border-green-100';
            default:
                return 'text-gray-600 bg-gray-50 border-gray-100';
        }
    };
    
    const formatTime = (isoString?: string) => {
        if (!isoString) return '-';
        try {
            const date = new Date(isoString);
            if (!isNaN(date.getTime())) {
                return date.toLocaleString('vi-VN');
            }
            
            // Try fallback parsing for DD/MM/YYYY HH:mm:ss
            // Example: "30/12/2025 14:00:00"
            const parts = isoString.split(/[\s/:]/);
            if (parts.length >= 6) {
                const day = parseInt(parts[0], 10);
                const month = parseInt(parts[1], 10) - 1;
                const year = parseInt(parts[2], 10);
                const hour = parseInt(parts[3], 10);
                const min = parseInt(parts[4], 10);
                const sec = parseInt(parts[5], 10);
                const fallbackDate = new Date(year, month, day, hour, min, sec);
                 if (!isNaN(fallbackDate.getTime())) {
                    return fallbackDate.toLocaleString('vi-VN');
                }
            }

            return isoString;
        } catch {
            return isoString;
        }
    };

    const actionOptions = ['ALL', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'LOGON', 'LOGOFF', 'CREATE USER', 'DROP USER', 'ALTER SYSTEM'];

    if (error) {
         return (
             <div className="bg-red-50 text-red-600 p-10 rounded-lg border border-red-200 text-center">
                <ShieldAlert size={48} className="mx-auto mb-4 text-red-400"/>
                <h3 className="text-lg font-bold mb-2">Truy cập bị từ chối</h3>
                <p>{error}</p>
                 <p className="text-sm mt-2 text-gray-500">Chỉ Admin hoặc Project Owner mới có quyền xem Audit Log.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <header>
                <h2 className="text-2xl font-bold tracking-tight">Hệ thống Nhật ký (Audit Trail)</h2>
                <p className="text-gray-500">Ghi lại toàn bộ hoạt động truy cập và thay đổi dữ liệu trong hệ thống.</p>
            </header>

            {/* Filters */}
            <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 flex flex-col md:flex-row gap-4 items-end">
                <div className="flex-1 w-full">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Người dùng</label>
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                        <input 
                            type="text" 
                            placeholder="Nhập Oracle Username..."
                            className="w-full pl-9 pr-4 py-2 border rounded-lg focus:ring-blue-500 text-sm"
                            value={filterUser}
                            onChange={(e) => setFilterUser(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && loadLogs()}
                        />
                    </div>
                </div>
                
                <div className="flex-1 w-full">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Hành động</label>
                    <select 
                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 text-sm"
                        value={filterAction}
                        onChange={(e) => setFilterAction(e.target.value)}
                    >
                        {actionOptions.map(opt => (
                            <option key={opt} value={opt}>{opt}</option>
                        ))}
                    </select>
                </div>

                <button 
                    onClick={loadLogs}
                    disabled={loading}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 whitespace-nowrap"
                >
                    {loading ? <RefreshCw size={16} className="animate-spin"/> : <Filter size={16}/>}
                    Lọc Nhật ký
                </button>
            </div>

            <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead className="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Thời gian</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hành động</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Đối tượng</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Chi tiết</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                            {logs.length > 0 ? (
                                logs.map((log, idx) => (
                                    <tr key={idx} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-mono text-xs">
                                            {formatTime(log.timestamp)}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                                            {log.username}
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                                            <span className={`px-2 py-1 inline-flex text-xs leading-5 font-bold rounded border ${getActionColor(log.action)}`}>
                                                {log.action}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                            {log.object_name || '-'}
                                        </td>
                                        <td className="px-6 py-4 text-xs text-gray-500 max-w-xs truncate">
                                            {log.sql_text ? (
                                                <span title={log.sql_text}>{log.sql_text.substring(0, 50)}...</span>
                                            ) : (
                                                log.privilege_used
                                            )}
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan={5} className="px-6 py-10 text-center text-gray-500">
                                        Không tìm thấy nhật ký nào phù hợp.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
