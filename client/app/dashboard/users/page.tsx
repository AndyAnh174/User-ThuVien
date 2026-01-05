'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';
import { Plus, X, Pencil, Trash2 } from 'lucide-react';
import { useToast } from '@/components/ui/ToastProvider';

interface User {
    user_id: number;
    oracle_username: string;
    full_name: string;
    user_type: string;
    sensitivity_level: string;
    branch_id: number;
    branch_name?: string;
    email?: string;
    phone?: string;
    address?: string;
    department?: string;
}

interface Branch {
    branch_id: number;
    branch_name: string;
}

export default function UsersPage() {
    const { showToast } = useToast();
    const [users, setUsers] = useState<User[]>([]);
    const [profiles, setProfiles] = useState<{ profile_name: string }[]>([]);
    const [branches, setBranches] = useState<Branch[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [currentUserRole, setCurrentUserRole] = useState('');


    // Form State
    const [newUser, setNewUser] = useState({
        username: '',
        password: '',
        full_name: '',
        user_type: 'READER',
        sensitivity_level: 'PUBLIC',
        branch_id: 2,
        email: '',
        phone: '',
        address: '',
        department: '',
        profile: 'DEFAULT'
    });

    const [editingUser, setEditingUser] = useState<Partial<User> & { profile?: string }>({});

    useEffect(() => {
        loadUsers();
        loadProfiles();
        loadBranches();
        // Get current user role
        const userStr = localStorage.getItem('user');
        if (userStr) {
            try {
                const u = JSON.parse(userStr);
                setCurrentUserRole(u.user_type);
            } catch (e) { }
        }
    }, []);

    const loadBranches = async () => {
        try {
            const data = await apiRequest('/books/branches');
            setBranches(data);
        } catch (err) {
            console.error("Failed to load branches", err);
        }
    };

    const loadProfiles = async () => {
        try {
            const data = await apiRequest('/profiles');
            setProfiles(data);
        } catch (err) {
            console.error("Failed to load profiles", err);
        }
    };

    const loadUsers = async () => {
        try {
            setLoading(true);
            const data = await apiRequest('/users');
            setUsers(data);
        } catch (err: any) {
            if (err.message.includes('403') || err.message.includes('ORA-00942')) {
                setError('Bạn không có quyền xem danh sách người dùng.');
            } else {
                setError(err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const translateUserType = (type: string) => {
        switch (type) {
            case 'ADMIN': return 'Quản trị viên';
            case 'LIBRARIAN': return 'Thủ thư';
            case 'STAFF': return 'Nhân viên';
            case 'READER': return 'Độc giả';
            default: return type;
        }
    };

    const openEditModal = (user: User) => {
        setEditingUser({
            user_id: user.user_id,
            full_name: user.full_name,
            branch_id: user.branch_id,
            email: user.email,
            phone: user.phone,
            address: user.address,
            department: user.department,
            profile: '' // Default empty
        });
        setIsEditModalOpen(true);
    };

    // --- CREATE HANDLER ---
    const handleCreateUser = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        setError('');

        try {
            const payload = {
                username: newUser.username,
                password: newUser.password,
                full_name: newUser.full_name,
                user_type: newUser.user_type,
                branch_id: newUser.branch_id,
                default_tablespace: "LIBRARY_DATA",
                temporary_tablespace: "LIBRARY_TEMP",
                quota: "10M",
                email: newUser.email,
                phone: newUser.phone,
                address: newUser.address,
                department: newUser.department,
                profile: newUser.profile
            };

            await apiRequest('/users', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            await loadUsers();
            setIsCreateModalOpen(false);
            setNewUser({
                username: '',
                password: '',
                full_name: '',
                user_type: 'READER',
                sensitivity_level: 'PUBLIC',
                branch_id: 2,
                email: '',
                phone: '',
                address: '',
                department: '',
                profile: 'DEFAULT'
            });
            showToast('Tạo người dùng thành công!', 'success');
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // --- EDIT HANDLER ---
    // ... (openEditModal)

    const handleUpdateUser = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            const payload = {
                full_name: editingUser.full_name,
                branch_id: editingUser.branch_id,
                email: editingUser.email,
                phone: editingUser.phone,
                address: editingUser.address,
                department: editingUser.department,
                profile: editingUser.profile || undefined
            };

            await apiRequest(`/users/${editingUser.user_id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            await loadUsers();
            setIsEditModalOpen(false);
            showToast('Cập nhật thành công!', 'success');
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // --- DELETE HANDLER ---
    const handleDeleteUser = async (userId: number, username: string) => {
        if (!confirm(`Bạn có chắc muốn xóa người dùng ${username}? Hành động này sẽ xóa cả tài khoản Oracle.`)) {
            return;
        }

        try {
            await apiRequest(`/users/${userId}?cascade=true`, {
                method: 'DELETE'
            });
            await loadUsers();
            showToast(`Đã xóa người dùng ${username}`, 'success');
        } catch (err: any) {
            showToast('Lỗi khi xóa: ' + err.message, 'error');
        }
    };

    if (loading) return <div className="text-center p-10">Đang tải danh sách người dùng...</div>;

    if (error) {
        return (
            <div className="bg-red-50 text-red-600 p-10 rounded-lg border border-red-200 text-center">
                <h3 className="text-lg font-bold mb-2">Truy cập bị từ chối</h3>
                <p>{error}</p>
                <p className="text-sm mt-2 text-gray-500">Chỉ có Quản trị viên mới được xem trang này.</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <header className="flex justify-between items-center">
                <h2 className="text-2xl font-bold tracking-tight">Quản lý Người dùng</h2>
                <button
                    onClick={() => setIsCreateModalOpen(true)}
                    className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                >
                    <Plus size={18} />
                    Thêm Người dùng
                </button>
            </header>

            <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 overflow-hidden">
                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                    <thead className="bg-gray-50 dark:bg-gray-700/50">
                        <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Mã</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Tài khoản</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Họ và Tên</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Vai trò</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Độ mật (OLS)</th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Chi nhánh</th>
                            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                        {users.map((user) => (
                            <tr key={user.user_id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.user_id}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">{user.oracle_username}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.full_name}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                                        {translateUserType(user.user_type)}
                                    </span>
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                    {user.sensitivity_level === 'TOP_SECRET' ? 'TỐI MẬT' :
                                        user.sensitivity_level === 'CONFIDENTIAL' ? 'MẬT' :
                                            user.sensitivity_level === 'INTERNAL' ? 'NỘI BỘ' : 'CÔNG KHAI'}
                                </td>
                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.branch_name || branches.find(b => b.branch_id === user.branch_id)?.branch_name || `CN ${user.branch_id}`}</td>
                                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium flex justify-end gap-2">
                                    <button
                                        onClick={() => openEditModal(user)}
                                        className="text-blue-600 hover:text-blue-900 p-1 hover:bg-blue-50 rounded"
                                        title="Sửa thông tin"
                                    >
                                        <Pencil size={16} />
                                    </button>
                                    <button
                                        onClick={() => handleDeleteUser(user.user_id, user.oracle_username)}
                                        className="text-red-600 hover:text-red-900 p-1 hover:bg-red-50 rounded"
                                        title="Xóa người dùng"
                                    >
                                        <Trash2 size={16} />
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* Modal Create User */}
            {isCreateModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-md overflow-hidden">
                        <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Thêm người dùng mới</h3>
                            <button onClick={() => setIsCreateModalOpen(false)} className="text-gray-400 hover:text-gray-500">
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleCreateUser} className="p-6 space-y-4">
                            {/* ... Fields (Create users fields) ... */}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tài khoản (Username)</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    placeholder="VD: nv_a"
                                    value={newUser.username}
                                    onChange={e => setNewUser({ ...newUser, username: e.target.value.toUpperCase() })}
                                />
                                <p className="text-xs text-gray-500 mt-1">Sẽ tự động viết hoa (Oracle standard)</p>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Mật khẩu</label>
                                <input
                                    type="password"
                                    required
                                    minLength={6}
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={newUser.password}
                                    onChange={e => setNewUser({ ...newUser, password: e.target.value })}
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Họ và Tên</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={newUser.full_name}
                                    onChange={e => setNewUser({ ...newUser, full_name: e.target.value })}
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                                    <input
                                        type="email"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.email}
                                        onChange={e => setNewUser({ ...newUser, email: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Điện thoại</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.phone}
                                        onChange={e => setNewUser({ ...newUser, phone: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Địa chỉ</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.address}
                                        onChange={e => setNewUser({ ...newUser, address: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Phòng ban</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.department}
                                        onChange={e => setNewUser({ ...newUser, department: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Vai trò</label>
                                    <select
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.user_type}
                                        onChange={e => setNewUser({ ...newUser, user_type: e.target.value })}
                                    >
                                        <option value="READER">Độc giả</option>
                                        <option value="STAFF">Nhân viên</option>
                                        <option value="LIBRARIAN">Thủ thư</option>
                                        <option value="ADMIN">Quản trị viên</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Chi nhánh</label>
                                    <select
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.branch_id}
                                        onChange={e => setNewUser({ ...newUser, branch_id: Number(e.target.value) })}
                                    >
                                        {branches.map(b => (
                                            <option key={b.branch_id} value={b.branch_id}>{b.branch_name}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>

                            {currentUserRole === 'ADMIN' && (
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Oracle Profile (Admin Only)</label>
                                    <select
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={newUser.profile}
                                        onChange={e => setNewUser({ ...newUser, profile: e.target.value })}
                                    >
                                        {profiles.map(p => (
                                            <option key={p.profile_name} value={p.profile_name}>{p.profile_name}</option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            <div className="pt-4 flex justify-end gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsCreateModalOpen(false)}
                                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                                >
                                    Hủy
                                </button>
                                <button
                                    type="submit"
                                    disabled={submitting}
                                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {submitting ? 'Đang tạo...' : 'Tạo User'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Modal Edit User */}
            {isEditModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-md overflow-hidden">
                        <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Cập nhật thông tin</h3>
                            <button onClick={() => setIsEditModalOpen(false)} className="text-gray-400 hover:text-gray-500">
                                <X size={20} />
                            </button>
                        </div>

                        <form onSubmit={handleUpdateUser} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Họ và Tên</label>
                                <input
                                    type="text"
                                    required
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={editingUser.full_name}
                                    onChange={e => setEditingUser({ ...editingUser, full_name: e.target.value })}
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                                    <input
                                        type="email"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={editingUser.email || ''}
                                        onChange={e => setEditingUser({ ...editingUser, email: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Điện thoại</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={editingUser.phone || ''}
                                        onChange={e => setEditingUser({ ...editingUser, phone: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Địa chỉ</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={editingUser.address || ''}
                                        onChange={e => setEditingUser({ ...editingUser, address: e.target.value })}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Phòng ban</label>
                                    <input
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={editingUser.department || ''}
                                        onChange={e => setEditingUser({ ...editingUser, department: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Chi nhánh</label>
                                <select
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={editingUser.branch_id}
                                    onChange={e => setEditingUser({ ...editingUser, branch_id: Number(e.target.value) })}
                                >
                                    {branches.map(b => (
                                        <option key={b.branch_id} value={b.branch_id}>{b.branch_name}</option>
                                    ))}
                                </select>
                            </div>

                            {currentUserRole === 'ADMIN' && (
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Oracle Profile (Admin Only)</label>
                                    <select
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={editingUser.profile || ''}
                                        onChange={e => setEditingUser({ ...editingUser, profile: e.target.value })}
                                    >
                                        <option value="">-- Giữ nguyên --</option>
                                        {profiles.map(p => (
                                            <option key={p.profile_name} value={p.profile_name}>{p.profile_name}</option>
                                        ))}
                                    </select>
                                    <p className="text-xs text-gray-500 mt-1">Chọn profile mới nếu muốn thay đổi.</p>
                                </div>
                            )}

                            <div className="pt-4 flex justify-end gap-3">
                                <button
                                    type="button"
                                    onClick={() => setIsEditModalOpen(false)}
                                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                                >
                                    Hủy
                                </button>
                                <button
                                    type="submit"
                                    disabled={submitting}
                                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {submitting ? 'Đang lưu...' : 'Lưu thay đổi'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
