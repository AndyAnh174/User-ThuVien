'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const credentials = btoa(`${username}:${password}`);
      const res = await fetch('http://localhost:8000/api/auth/login', {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${credentials}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
      });

      if (!res.ok) {
        throw new Error('Đăng nhập thất bại. Kiểm tra lại thông tin.');
      }

      const data = await res.json();
      
      // Store user info and credentials
      localStorage.setItem('user', JSON.stringify({ 
        username, 
        password, 
        ...data.user 
      }));

      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 dark:bg-gray-950 p-4">
      <div className="w-full max-w-md space-y-8 bg-white dark:bg-gray-900 p-8 rounded-xl shadow-lg border border-gray-200 dark:border-gray-800">
        <div className="text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-gray-100">
            Thư Viện Số
          </h2>
          <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
            Hệ thống Quản lý Người dùng & Tài liệu
          </p>
        </div>
        
        <form className="mt-8 space-y-6" onSubmit={handleLogin}>
          <div className="space-y-4">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Tài khoản Oracle
              </label>
              <input
                id="username"
                name="username"
                type="text"
                required
                className="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-700 px-3 py-2 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 sm:text-sm"
                placeholder="Ví dụ: admin_user"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Mật khẩu
              </label>
              <input
                id="password"
                name="password"
                type="password"
                required
                className="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-700 px-3 py-2 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 sm:text-sm"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          {error && (
            <div className="text-red-500 text-sm text-center bg-red-50 dark:bg-red-900/20 p-2 rounded">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="group relative flex w-full justify-center rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
          >
             {loading ? 'Đang xử lý...' : 'Đăng nhập'}
          </button>
        </form>

        <div className="mt-6">
            <div className="relative">
                <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-gray-300 dark:border-gray-700"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                    <span className="bg-white dark:bg-gray-900 px-2 text-gray-500">Tài khoản mẫu</span>
                </div>
            </div>
            <div className="mt-4 grid grid-cols-2 gap-2 text-xs text-gray-500 dark:text-gray-400 text-center">
                <div className="p-2 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
                     onClick={() => {setUsername('admin_user'); setPassword('Admin123');}}>
                    <div className="font-bold">Admin</div>
                    admin_user / Admin123
                </div>
                <div className="p-2 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
                     onClick={() => {setUsername('librarian_user'); setPassword('Librarian123');}}>
                    <div className="font-bold">Thủ thư</div>
                    librarian_user / Librarian123
                </div>
                <div className="p-2 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
                     onClick={() => {setUsername('reader_user'); setPassword('Reader123');}}>
                    <div className="font-bold">Độc giả</div>
                    reader_user / Reader123
                </div>
                 <div className="p-2 border rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
                     onClick={() => {setUsername('staff_user'); setPassword('Staff123');}}>
                    <div className="font-bold">Nhân viên</div>
                    staff_user / Staff123
                </div>
            </div>
        </div>
      </div>
    </div>
  );
}
