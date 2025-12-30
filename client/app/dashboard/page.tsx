'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';

export default function DashboardHome() {
  const [stats, setStats] = useState({ books: 0, users: 0, borrows: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
        try {
            // These might fail depending on permissions, but we'll try fetch lists to count
            // Or use better summary endpoints if available. For now, try fetching lists.
            const [books, users, borrows] = await Promise.allSettled([
                apiRequest('/books'),
                apiRequest('/users'),
                apiRequest('/borrow')
            ]);
            
            setStats({
                books: books.status === 'fulfilled' ? (books.value as any[]).length : 0,
                users: users.status === 'fulfilled' ? (users.value as any[]).length : 0,
                borrows: borrows.status === 'fulfilled' ? (borrows.value as any[]).length : 0,
            });
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };
    fetchStats();
  }, []);

  if (loading) return <div className="text-center p-10">Đang tải dữ liệu...</div>;

  return (
    <div className="space-y-6">
      <div className="grid gap-6 md:grid-cols-3">
        {/* Card 1: Books */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Tổng số sách</h3>
                <span className="p-2 bg-blue-100 text-blue-600 rounded-full dark:bg-blue-900 dark:text-blue-300">📚</span>
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-white">{stats.books}</div>
            <p className="text-xs text-gray-500 mt-1">Đầu sách trong hệ thống</p>
        </div>

        {/* Card 2: Users */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
             <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Người dùng</h3>
                <span className="p-2 bg-green-100 text-green-600 rounded-full dark:bg-green-900 dark:text-green-300">👥</span>
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-white">{stats.users}</div>
            <p className="text-xs text-gray-500 mt-1">Tài khoản hoạt động</p>
        </div>

        {/* Card 3: Borrowing */}
        <div className="p-6 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
             <div className="flex items-center justify-between mb-4">
                <h3 className="text-sm font-medium text-gray-500 dark:text-gray-400">Lượt mượn</h3>
                <span className="p-2 bg-orange-100 text-orange-600 rounded-full dark:bg-orange-900 dark:text-orange-300">🔄</span>
            </div>
            <div className="text-3xl font-bold text-gray-900 dark:text-white">{stats.borrows}</div>
            <p className="text-xs text-gray-500 mt-1">Đang mượn / Đã trả</p>
        </div>
      </div>

      {/* Quick Info */}
       <div className="bg-blue-50 dark:bg-blue-900/10 p-4 rounded-lg border border-blue-100 dark:border-blue-900/20">
            <h4 className="font-semibold text-blue-800 dark:text-blue-300 mb-2">Thông tin hệ thống</h4>
            <ul className="text-sm text-blue-700 dark:text-blue-400 space-y-1">
                <li>• Database: Oracle Database 23ai Free</li>
                <li>• Container: FREEPDB1</li>
                <li>• Security: VPD enabled, Audit enabled</li>
                <li>• Client: Next.js + TailwindCSS</li>
            </ul>
        </div>
    </div>
  );
}
