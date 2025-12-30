'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';
import { Plus, X, Pencil, Trash2, Shield, Settings, Clock, Users } from 'lucide-react';
import { useToast } from '@/components/ui/ToastProvider';

interface ProfileSummary {
    profile_name: string;
}
//...


interface ProfileDetail {
    profile_name: string;
    resources: { resource_name: string; limit: string; resource_type?: string }[];
    users: string[];
}

export default function ProfilesPage() {
    const { showToast } = useToast();
    const [profiles, setProfiles] = useState<ProfileSummary[]>([]);
    
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    
    // Modal State
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [selectedProfile, setSelectedProfile] = useState<ProfileDetail | null>(null);

    // Form State
    const [formData, setFormData] = useState({
        profile_name: '',
        sessions_per_user: 'UNLIMITED',
        connect_time: 'UNLIMITED',
        idle_time: 'UNLIMITED'
        // Add more limits if needed
    });

    useEffect(() => {
        loadProfiles();
    }, []);

    const loadProfiles = async () => {
        try {
            setLoading(true);
            const data = await apiRequest('/profiles');
            setProfiles(data);
        } catch (err: any) {
             if (err.message.includes('403') || err.message.includes('ORA-00942')) {
                setError('Bạn không có quyền quản lý Profiles.');
            } else {
                setError(err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const handleCreateNew = () => {
        setFormData({
            profile_name: '',
            sessions_per_user: 'UNLIMITED',
            connect_time: 'UNLIMITED',
            idle_time: 'UNLIMITED'
        });
        setSelectedProfile(null);
        setIsEditing(false);
        setIsModalOpen(true);
    };

    const handleViewDetail = async (profileName: string) => {
        try {
            const data = await apiRequest(`/profiles/${profileName}`);
            setSelectedProfile(data);
            
            // ... (Pre-fill)
            
            setIsEditing(true);

        } catch (err: any) {
            showToast('Lỗi tải chi tiết profile: ' + err.message, 'error');
        }
    };

    // ... (handleCreateNew)

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (isEditing) {
                // Update
                const payload = {
                    sessions_per_user: formData.sessions_per_user,
                    connect_time: formData.connect_time,
                    idle_time: formData.idle_time
                };
                await apiRequest(`/profiles/${formData.profile_name}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
            } else {
                // Create
                await apiRequest('/profiles', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
            }
            
            showToast(isEditing ? 'Cập nhật thành công!' : 'Tạo Profile thành công!', 'success');
            setIsModalOpen(false);
            setSelectedProfile(null);
            loadProfiles();
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    const handleDelete = async (profileName: string) => {
        if (['DEFAULT', 'ORA_STIG_PROFILE'].includes(profileName)) {
            showToast('Không thể xóa Profile mặc định của hệ thống!', 'warning');
            return;
        }
        if (!confirm(`Bạn có chắc muốn xóa Profile "${profileName}"? Users đang dùng Profile này sẽ bị chuyển về DEFAULT (Cascade).`)) return;

        try {
            await apiRequest(`/profiles/${profileName}?cascade=true`, {
                method: 'DELETE'
            });
            showToast('Đã xóa Profile', 'success');
            setSelectedProfile(null);
            loadProfiles();
        } catch (err: any) {
            showToast('Lỗi khi xóa: ' + err.message, 'error');
        }
    };

    if (loading) return <div className="text-center p-10">Đang tải Profiles Oracle...</div>;
    if (error) return <div className="text-red-500 text-center p-10">{error}</div>;

    return (
        <div className="space-y-6">
            <header className="flex justify-between items-center">
                <div>
                    <h2 className="text-2xl font-bold tracking-tight">Cấu hình Profiles Oracle</h2>
                    <p className="text-gray-500">Quản lý giới hạn tài nguyên và chính sách mật khẩu cho User.</p>
                </div>
                <button 
                    onClick={handleCreateNew}
                    className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2"
                >
                    <Plus size={18} />
                    Tạo Profile
                </button>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {profiles.map((item, idx) => (
                    <div 
                        key={idx} 
                        onClick={() => handleViewDetail(item.profile_name)}
                        className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow border border-gray-200 dark:border-gray-700 flex items-center space-x-3 hover:border-blue-300 transition-colors cursor-pointer group"
                    >
                        <div className={`p-3 rounded text-white ${['DEFAULT', 'MONITOR'].includes(item.profile_name) ? 'bg-gray-400' : 'bg-blue-500'}`}>
                           <Shield size={24} />
                        </div>
                        <div className="flex-1">
                            <h3 className="font-bold text-gray-900 dark:text-white group-hover:text-blue-600">{item.profile_name}</h3>
                            <p className="text-xs text-gray-500">Oracle Profile</p>
                        </div>
                        <div className="text-gray-300">
                             <Settings size={20} />
                        </div>
                    </div>
                ))}
            </div>

            {/* Detail/Edit Modal */}
            {(selectedProfile || isModalOpen) && (
                 <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] overflow-y-auto">
                         <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center bg-gray-50 dark:bg-gray-700/50">
                            <div>
                                <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                                    {isModalOpen && !selectedProfile ? 'Tạo Profile Mới' : `Chi tiết: ${selectedProfile?.profile_name}`}
                                </h3>
                                {selectedProfile && <p className="text-sm text-gray-500">Đang xem thông tin chi tiết</p>}
                            </div>
                            <button onClick={() => { setIsModalOpen(false); setSelectedProfile(null); }} className="text-gray-400 hover:text-gray-500">
                                <X size={20} />
                            </button>
                        </div>

                         <div className="p-6">
                            {/* If viewing detail but not editing yet (or toggle edit) */}
                            {selectedProfile && !isModalOpen && (
                                <div className="space-y-6">
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                        <div className="bg-blue-50 dark:bg-blue-900/10 p-4 rounded-lg border border-blue-100 dark:border-blue-900/30">
                                            <h4 className="font-semibold flex items-center gap-2 mb-2 text-blue-700 dark:text-blue-300"><Clock size={16}/> Giới hạn thời gian</h4>
                                            <ul className="space-y-2 text-sm">
                                                <li className="flex justify-between">
                                                    <span>Connect Time:</span> 
                                                    <span className="font-medium">{selectedProfile.resources.find((r:any) => r.resource_name === 'CONNECT_TIME')?.limit}</span>
                                                </li>
                                                <li className="flex justify-between">
                                                    <span>Idle Time:</span> 
                                                    <span className="font-medium">{selectedProfile.resources.find((r:any) => r.resource_name === 'IDLE_TIME')?.limit}</span>
                                                </li>
                                            </ul>
                                        </div>
                                         <div className="bg-purple-50 dark:bg-purple-900/10 p-4 rounded-lg border border-purple-100 dark:border-purple-900/30">
                                            <h4 className="font-semibold flex items-center gap-2 mb-2 text-purple-700 dark:text-purple-300"><Users size={16}/> Giới hạn User</h4>
                                            <ul className="space-y-2 text-sm">
                                                <li className="flex justify-between">
                                                    <span>Sessions/User:</span> 
                                                    <span className="font-medium">{selectedProfile.resources.find((r:any) => r.resource_name === 'SESSIONS_PER_USER')?.limit}</span>
                                                </li>
                                            </ul>
                                        </div>
                                    </div>
                                    
                                    <div>
                                        <h4 className="font-semibold mb-2">Users đang dùng Profile này:</h4>
                                        {selectedProfile.users.length > 0 ? (
                                            <div className="flex flex-wrap gap-2">
                                                {selectedProfile.users.map(u => (
                                                    <span key={u} className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded text-xs font-mono">{u}</span>
                                                ))}
                                            </div>
                                        ) : (
                                            <p className="text-sm text-gray-400 italic">Chưa có user nào.</p>
                                        )}
                                    </div>

                                    <div className="flex justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-700">
                                         <button 
                                            onClick={() => handleDelete(selectedProfile.profile_name)}
                                            className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg flex items-center gap-2"
                                        >
                                            <Trash2 size={16}/> Xóa Profile
                                        </button>
                                        <button 
                                            onClick={() => setIsModalOpen(true)} // Enable form mode
                                            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg flex items-center gap-2"
                                        >
                                            <Pencil size={16}/> Chỉnh sửa
                                        </button>
                                    </div>
                                </div>
                            )}

                            {/* Form Mode (Create or Edit) */}
                            {isModalOpen && (
                                <form onSubmit={handleSubmit} className="space-y-4">
                                    {!isEditing && (
                                        <div>
                                            <label className="block text-sm font-medium mb-1">Tên Profile</label>
                                            <input 
                                                type="text" required
                                                className="w-full px-3 py-2 border rounded"
                                                placeholder="VD: STAFF_PROFILE"
                                                value={formData.profile_name}
                                                onChange={e => setFormData({...formData, profile_name: e.target.value.toUpperCase()})}
                                            />
                                        </div>
                                    )}
                                    
                                    <div className="grid grid-cols-3 gap-4">
                                        <div>
                                            <label className="block text-sm font-medium mb-1">Sessions / User</label>
                                            <input 
                                                type="text"
                                                className="w-full px-3 py-2 border rounded"
                                                placeholder="UNLIMITED or number"
                                                value={formData.sessions_per_user}
                                                onChange={e => setFormData({...formData, sessions_per_user: e.target.value.toUpperCase()})}
                                            />
                                            <p className="text-xs text-gray-500 mt-1">Số session tối đa 1 user mở được.</p>
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium mb-1">Idle Time (phút)</label>
                                            <input 
                                                type="text"
                                                className="w-full px-3 py-2 border rounded"
                                                placeholder="UNLIMITED or number"
                                                value={formData.idle_time}
                                                onChange={e => setFormData({...formData, idle_time: e.target.value.toUpperCase()})}
                                            />
                                            <p className="text-xs text-gray-500 mt-1">Tự logout nếu không hoạt động.</p>
                                        </div>
                                        <div>
                                            <label className="block text-sm font-medium mb-1">Connect Time (phút)</label>
                                            <input 
                                                type="text"
                                                className="w-full px-3 py-2 border rounded"
                                                placeholder="UNLIMITED or number"
                                                value={formData.connect_time}
                                                onChange={e => setFormData({...formData, connect_time: e.target.value.toUpperCase()})}
                                            />
                                            <p className="text-xs text-gray-500 mt-1">Tổng thời gian tối đa 1 session.</p>
                                        </div>
                                    </div>
                                    
                                    <div className="flex justify-end gap-3 pt-4">
                                         <button 
                                            type="button"
                                            onClick={() => { setIsModalOpen(false); if(!selectedProfile) setSelectedProfile(null); }}
                                            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg"
                                        >
                                            Hủy
                                        </button>
                                        <button 
                                            type="submit"
                                            disabled={submitting}
                                            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 rounded-lg"
                                        >
                                            {submitting ? 'Đang lưu...' : 'Lưu Cấu Hình'}
                                        </button>
                                    </div>
                                </form>
                            )}
                         </div>
                    </div>
                 </div>
            )}
        </div>
    );
}
