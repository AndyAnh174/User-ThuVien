'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';
import { Plus, X, Search, UserCheck, BookOpen, Calendar, ArrowLeftRight } from 'lucide-react';
import { useToast } from '@/components/ui/ToastProvider';

interface BorrowRecord {
    borrow_id: number;
    user_id: number;
    borrower_name: string;
    book_id: number;
    book_title: string;
    borrow_date: string; // ISO date string
    due_date?: string;
    return_date?: string;
    status: string; // BORROWING, RETURNED, OVERDUE, LOST
    fine_amount: number;
}

interface User {
    user_id: number;
    full_name: string;
    oracle_username: string;
}

interface Book {
    book_id: number;
    title: string;
    available_qty: number;
}

export default function BorrowPage() {
    const { showToast } = useToast();
    const [history, setHistory] = useState<BorrowRecord[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [searchTerm, setSearchTerm] = useState('');
    const [userRole, setUserRole] = useState<string>('READER');

    // Modal State
    const [isBorrowModalOpen, setIsBorrowModalOpen] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    // Return Modal State
    const [returnModalOpen, setReturnModalOpen] = useState(false);
    const [selectedReturn, setSelectedReturn] = useState<BorrowRecord | null>(null);
    const [fineAmount, setFineAmount] = useState<number>(0);

    // Dropdown Data
    const [users, setUsers] = useState<User[]>([]);
    const [books, setBooks] = useState<Book[]>([]);

    // Form State
    const [newBorrow, setNewBorrow] = useState({
        user_id: '',
        book_id: '',
        due_date: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0] // Default +14 days
    });

    useEffect(() => {
        const storedUser = localStorage.getItem('user');
        if (storedUser) {
            const user = JSON.parse(storedUser);
            setUserRole(user.user_type);
        }
        loadData();
    }, []);

    const loadData = async () => {
        try {
            setLoading(true);
            const data = await apiRequest('/borrow');
            setHistory(data);
        } catch (err: any) {
             if (err.message.includes('403') || err.message.includes('ORA-00942')) {
                setError('Bạn không có quyền xem lịch sử mượn trả.');
            } else {
                setError(err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const loadDropdownData = async () => {
         try {
            const [usersData, booksData] = await Promise.all([
                apiRequest('/users'),
                apiRequest('/books')
            ]);
            setUsers(usersData);
            setBooks(booksData.filter((b: Book) => b.available_qty > 0)); // Only show available books
        } catch (err: any) {
            showToast("Lỗi tải danh sách người dùng/sách: " + err.message, 'error');
        }
    }

    const handleOpenBorrowModal = () => {
        setIsBorrowModalOpen(true);
        loadDropdownData();
    };

    const handleBorrow = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (!newBorrow.user_id || !newBorrow.book_id) {
                showToast("Vui lòng chọn người dùng và sách", 'warning');
                return;
            }

            await apiRequest('/borrow', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: Number(newBorrow.user_id),
                    book_id: Number(newBorrow.book_id),
                    due_date: newBorrow.due_date
                })
            });

            showToast('Mượn sách thành công!', 'success');
            setIsBorrowModalOpen(false);
            setNewBorrow({ ...newBorrow, user_id: '', book_id: '' });
            loadData();
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    const handleReturn = (borrow: BorrowRecord) => {
        setSelectedReturn(borrow);
        setFineAmount(0); // Reset default fine
        setReturnModalOpen(true);
    };

    const processReturn = async () => {
        if (!selectedReturn) return;
        setSubmitting(true);
        try {
            await apiRequest(`/borrow/${selectedReturn.borrow_id}/return`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    fine_amount: fineAmount
                })
            });

            showToast('Trả sách thành công!', 'success');
            setReturnModalOpen(false);
            setSelectedReturn(null);
            loadData();
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    const translateStatus = (status: string) => {
        switch (status) {
            case 'RETURNED': return 'Đã trả';
            case 'BORROWING': return 'Đang mượn';
            case 'OVERDUE': return 'Quá hạn';
            case 'LOST': return 'Đã mất';
            default: return status;
        }
    };

    const getStatusColor = (status: string) => {
         switch (status) {
            case 'RETURNED': return 'bg-green-100 text-green-800';
            case 'BORROWING': return 'bg-blue-100 text-blue-800';
            case 'OVERDUE': return 'bg-red-100 text-red-800';
            case 'LOST': return 'bg-gray-100 text-gray-800';
            default: return 'bg-gray-100 text-gray-800';
        }
    };

    // Filter
    const filteredHistory = history.filter(h => 
        h.borrower_name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
        h.book_title?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) return <div className="text-center p-10">Đang tải lịch sử mượn trả...</div>;
    if (error) return <div className="text-red-500 text-center p-10">{error}</div>;

    return (
        <div className="space-y-6">
            <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                   <h2 className="text-2xl font-bold tracking-tight">Quản lý Mượn/Trả</h2>
                   <p className="text-gray-500">Theo dõi trạng thái mượn trả sách (VPD Enabled)</p>
                </div>
                
                <div className="flex gap-2 w-full md:w-auto">
                    <div className="relative flex-1 md:w-64">
                         <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                         <input 
                            type="text" 
                            placeholder="Tìm người mượn hoặc tên sách..."
                            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-800 dark:border-gray-700"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    {userRole?.toUpperCase() !== 'READER' && (
                     <button 
                        onClick={handleOpenBorrowModal}
                        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 whitespace-nowrap"
                    >
                        <Plus size={18} />
                        Mượn sách mới
                    </button>
                    )}
                </div>
            </header>

            <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead className="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Mã PM</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Người mượn</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Sách</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Ngày mượn / Hẹn trả</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Ngày trả</th>
                                <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Trạng thái</th>
                                {userRole !== 'READER' && (
                                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Thao tác</th>
                                )}
                            </tr>
                        </thead>
                        <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                             {filteredHistory.map((item) => (
                                <tr key={item.borrow_id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{item.borrow_id}</td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-white">
                                        {item.borrower_name}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {item.book_title}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        <div>{new Date(item.borrow_date).toLocaleDateString('vi-VN')}</div>
                                        <div className="text-xs text-gray-400">Hẹn: {item.due_date ? new Date(item.due_date).toLocaleDateString('vi-VN') : 'N/A'}</div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                         {item.return_date ? new Date(item.return_date).toLocaleDateString('vi-VN') : '-'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-center">
                                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusColor(item.status)}`}>
                                            {translateStatus(item.status)}
                                        </span>
                                    </td>
                                    {userRole !== 'READER' && (
                                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                        {item.status === 'BORROWING' && (
                                             <button 
                                                onClick={() => handleReturn(item)}
                                                className="text-blue-600 hover:text-blue-900 border border-blue-600 hover:bg-blue-50 px-3 py-1 rounded text-xs"
                                            >
                                                Trả sách
                                            </button>
                                        )}
                                        {item.status === 'OVERDUE' && (
                                             <button 
                                                onClick={() => handleReturn(item)}
                                                className="text-red-600 hover:text-red-900 border border-red-600 hover:bg-red-50 px-3 py-1 rounded text-xs"
                                            >
                                                Trả sách (Phạt)
                                            </button>
                                        )}
                                    </td>
                                    )}
                                </tr>
                             ))}
                        </tbody>
                    </table>
                </div>
            </div>

             {/* Modal Borrow */}
             {isBorrowModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200">
                        <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Mượn sách mới</h3>
                            <button onClick={() => setIsBorrowModalOpen(false)} className="text-gray-400 hover:text-gray-500">
                                <X size={20} />
                            </button>
                        </div>
                        
                        <form onSubmit={handleBorrow} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 flex items-center gap-2">
                                    <UserCheck size={16} /> Người mượn (Độc giả)
                                </label>
                                <select 
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={newBorrow.user_id}
                                    onChange={e => setNewBorrow({...newBorrow, user_id: e.target.value})}
                                    required
                                >
                                    <option value="">-- Chọn người đọc --</option>
                                    {users.map(u => (
                                        <option key={u.user_id} value={u.user_id}>{u.oracle_username} - {u.full_name}</option>
                                    ))}
                                </select>
                            </div>
                            
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 flex items-center gap-2">
                                    <BookOpen size={16} /> Sách
                                </label>
                                <select 
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={newBorrow.book_id}
                                    onChange={e => setNewBorrow({...newBorrow, book_id: e.target.value})}
                                    required
                                >
                                    <option value="">-- Chọn sách (Còn hàng) --</option>
                                    {books.map(b => (
                                        <option key={b.book_id} value={b.book_id}>{b.title} (Còn: {b.available_qty})</option>
                                    ))}
                                </select>
                            </div>
                            
                            <div>
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1 flex items-center gap-2">
                                    <Calendar size={16} /> Hẹn trả
                                </label>
                                <input 
                                    type="date"
                                    className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                    value={newBorrow.due_date}
                                    onChange={e => setNewBorrow({...newBorrow, due_date: e.target.value})}
                                    required
                                />
                            </div>

                            <div className="pt-4 flex justify-end gap-3">
                                <button 
                                    type="button"
                                    onClick={() => setIsBorrowModalOpen(false)}
                                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                                >
                                    Hủy
                                </button>
                                <button 
                                    type="submit"
                                    disabled={submitting}
                                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {submitting ? 'Đang xử lý...' : 'Mượn Sách'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Modal Confirm Return */}
            {returnModalOpen && selectedReturn && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-sm overflow-hidden animate-in fade-in zoom-in duration-200">
                        <div className="p-6 text-center">
                            <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-blue-100 mb-4">
                                <ArrowLeftRight className="h-6 w-6 text-blue-600" />
                            </div>
                            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Xác nhận trả sách</h3>
                            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
                                Bạn có chắc chắn muốn nhận trả sách <strong>"{selectedReturn.book_title}"</strong> từ độc giả <strong>{selectedReturn.borrower_name}</strong>?
                            </p>

                            <div className="mt-4 text-left">
                                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                    Tiền phạt (nếu quá hạn/hư hỏng)
                                </label>
                                <div className="relative">
                                    <input 
                                        type="number"
                                        min="0"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600 pl-8"
                                        value={fineAmount}
                                        onChange={(e) => setFineAmount(Number(e.target.value))}
                                    />
                                    <span className="absolute left-3 top-2 text-gray-400">$</span>
                                </div>
                            </div>

                            <div className="mt-6 flex justify-center gap-3">
                                <button 
                                    type="button"
                                    onClick={() => setReturnModalOpen(false)}
                                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                                >
                                    Hủy bỏ
                                </button>
                                <button 
                                    type="button"
                                    onClick={processReturn}
                                    disabled={submitting}
                                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {submitting ? 'Đang xử lý...' : 'Xác nhận Trả'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
