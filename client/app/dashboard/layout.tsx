'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { logout } from '@/lib/api';
import {
    LayoutDashboard,
    BookOpen,
    ArrowLeftRight,
    Users,
    Shield,
    FileText,
    LogOut
} from 'lucide-react';

export default function DashboardLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    const router = useRouter();
    const pathname = usePathname();
    const [user, setUser] = useState<any>(null);

    useEffect(() => {
        const storedUser = localStorage.getItem('user');
        if (!storedUser) {
            router.push('/login');
            return;
        }
        setUser(JSON.parse(storedUser));
    }, [router]);

    if (!user) return null;

    const getNavigation = () => {
        if (!user) return [];
        let role = user.user_type?.toUpperCase() || 'READER';
        if (role === 'ORACLE_USER') role = 'ADMIN';

        const allNav = [
            { name: 'Tổng quan', href: '/dashboard', icon: LayoutDashboard, roles: ['ADMIN', 'LIBRARIAN', 'STAFF'] },
            { name: 'Sách', href: '/dashboard/books', icon: BookOpen, roles: ['ADMIN', 'LIBRARIAN', 'STAFF', 'READER'] },
            { name: 'Mượn Trả', href: '/dashboard/borrow', icon: ArrowLeftRight, roles: ['ADMIN', 'LIBRARIAN', 'STAFF', 'READER'] },
            { name: 'Người dùng', href: '/dashboard/users', icon: Users, roles: ['ADMIN', 'LIBRARIAN', 'STAFF'] },
            { name: 'Profiles', href: '/dashboard/profiles', icon: Shield, roles: ['ADMIN'] },
            { name: 'Nhật ký (Audit)', href: '/dashboard/audit', icon: FileText, roles: ['ADMIN'] },
        ];

        return allNav.filter(item => item.roles.includes(role));
    };

    const navigation = getNavigation();

    return (
        <div className="flex h-screen bg-gray-100 dark:bg-gray-900 font-sans">
            <aside className="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex flex-col">
                <div className="h-16 flex items-center px-6 border-b border-gray-200 dark:border-gray-700">
                    <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-600 to-indigo-600">
                        Library Admin ({user?.user_type})
                    </span>
                </div>

                <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
                    {navigation.map((item) => {
                        const isActive = pathname === item.href;
                        return (
                            <Link
                                key={item.name}
                                href={item.href}
                                className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors ${isActive
                                    ? 'bg-blue-50 text-blue-700 dark:bg-blue-900/20 dark:text-blue-400'
                                    : 'text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700/50'
                                    }`}
                            >
                                <item.icon className="mr-3 h-5 w-5" />
                                {item.name}
                            </Link>
                        );
                    })}
                </nav>

                <div className="p-4 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex items-center gap-3 mb-4 px-2">
                        <div className="w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300 flex items-center justify-center font-bold text-xs">
                            {user.username?.substring(0, 2).toUpperCase()}
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                                {user.full_name || user.username}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-gray-400 truncate uppercase">
                                {user.user_type} • {user.branch_name || `CN ${user.branch_id}`}
                            </p>
                        </div>
                    </div>
                    <button
                        onClick={logout}
                        className="w-full flex items-center justify-center px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30 rounded-lg transition-colors"
                    >
                        <LogOut className="mr-2 h-4 w-4" />
                        Đăng xuất
                    </button>
                </div>
            </aside>

            <main className="flex-1 overflow-auto">
                <header className="h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between px-8">
                    <h1 className="text-lg font-semibold text-gray-800 dark:text-gray-200">
                        {navigation.find(n => n.href === pathname)?.name || 'Dashboard'}
                    </h1>
                    <div className="flex items-center gap-4">
                        <span className={`px-2 py-1 text-xs font-bold rounded-full ${user.sensitivity_level === 'TOP_SECRET' ? 'bg-red-100 text-red-800' :
                                user.sensitivity_level === 'CONFIDENTIAL' ? 'bg-yellow-100 text-yellow-800' :
                                    user.sensitivity_level === 'INTERNAL' ? 'bg-blue-100 text-blue-800' :
                                        'bg-green-100 text-green-800'
                            }`}>
                            OLS: {user.sensitivity_level || 'PUBLIC'}
                        </span>
                        <span className="text-sm text-gray-500">
                            {user.branch_name || `Chi nhánh ${user.branch_id}`}
                        </span>
                    </div>
                </header>
                <div className="p-8">
                    {children}
                </div>
            </main>
        </div>
    );
}
