'use client';

import { useEffect, useState } from 'react';
import { apiRequest } from '@/lib/api';
import { Plus, Pencil, Trash2, X, Search } from 'lucide-react';
import { useToast } from '@/components/ui/ToastProvider';

interface Book {
    book_id: number;
    title: string;
    author: string;
    publisher: string;
    publish_year: number;
    isbn: string;
    category_id: number;
    category_name?: string;
    branch_id: number;
    branch_name?: string;
    quantity: number;
    available_qty: number;
    sensitivity_level: string;
}


interface Category {
    category_id: number;
    category_name: string;
}

interface Branch {
    branch_id: number;
    branch_name: string;
}

export default function BooksPage() {
    const { showToast } = useToast();
    const [books, setBooks] = useState<Book[]>([]);
    const [categories, setCategories] = useState<Category[]>([]);
    const [branches, setBranches] = useState<Branch[]>([]);
    
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [searchTerm, setSearchTerm] = useState('');
    const [userRole, setUserRole] = useState<string>('READER');

    // Modal State
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    // Form State
    const defaultBookState = {
        book_id: 0,
        title: '',
        author: '',
        publisher: '',
        publish_year: new Date().getFullYear(),
        isbn: '',
        category_id: 1,
        branch_id: 1,
        quantity: 10,
        sensitivity_level: 'PUBLIC'
    };
    const [currentBook, setCurrentBook] = useState(defaultBookState);

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
            const [booksData, catsData, branchesData] = await Promise.all([
                apiRequest('/books'),
                apiRequest('/books/categories'),
                apiRequest('/books/branches')
            ]);
            setBooks(booksData);
            setCategories(catsData);
            setBranches(branchesData);
        } catch (err: any) {
             if (err.message.includes('403') || err.message.includes('ORA-00942')) {
                setError('Bạn không có quyền xem danh sách sách.');
            } else {
                setError(err.message);
            }
        } finally {
            setLoading(false);
        }
    };

    const getSensitivityColor = (level: string) => {
        switch (level) {
            case 'TOP_SECRET': return 'bg-red-100 text-red-800 border-red-200';
            case 'CONFIDENTIAL': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
            case 'INTERNAL': return 'bg-blue-100 text-blue-800 border-blue-200';
            default: return 'bg-green-100 text-green-800 border-green-200';
        }
    };
    
    const translateLevel = (level: string) => {
         switch (level) {
            case 'TOP_SECRET': return 'TỐI MẬT';
            case 'CONFIDENTIAL': return 'MẬT';
            case 'INTERNAL': return 'NỘI BỘ';
            default: return 'CÔNG KHAI';
        }
    }

    // Handlers
    const handleAddNew = () => {
        setCurrentBook(defaultBookState);
        setIsEditing(false);
        setIsModalOpen(true);
    };

    const handleEdit = (book: Book) => {
        // ... (existing code)
        setCurrentBook({
            book_id: book.book_id,
            title: book.title,
            author: book.author || '',
            publisher: book.publisher || '',
            publish_year: book.publish_year || new Date().getFullYear(),
            isbn: book.isbn || '',
            category_id: book.category_id || 1,
            branch_id: book.branch_id || 1,
            quantity: book.quantity,
            sensitivity_level: book.sensitivity_level
        });
        setIsEditing(true);
        setIsModalOpen(true);
    };

    const handleDelete = async (bookId: number, title: string) => {
        if (!confirm(`Bạn có chắc muốn xóa sách "${title}"?`)) return;
        
        try {
            await apiRequest(`/books/${bookId}`, { method: 'DELETE' });
            showToast('Đã xóa sách thành công', 'success');
            loadData(); // Reload list
        } catch (err: any) {
            showToast('Lỗi khi xóa: ' + err.message, 'error');
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            const payload = {
                ...currentBook,
                category_id: Number(currentBook.category_id),
                branch_id: Number(currentBook.branch_id),
                publish_year: Number(currentBook.publish_year),
                quantity: Number(currentBook.quantity)
            };
            
            if (isEditing) {
                // Remove ID from payload for update
                const { book_id, ...updatePayload } = payload;
                await apiRequest(`/books/${currentBook.book_id}`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(updatePayload)
                });
            } else {
                 const { book_id, ...createPayload } = payload;
                await apiRequest('/books', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(createPayload)
                });
            }
            
            showToast(isEditing ? 'Cập nhật thành công!' : 'Thêm sách thành công!', 'success');
            setIsModalOpen(false);
            loadData();
        } catch (err: any) {
            showToast('Lỗi: ' + err.message, 'error');
        } finally {
            setSubmitting(false);
        }
    };

    // Filter logic
    const filteredBooks = books.filter(b => 
        b.title.toLowerCase().includes(searchTerm.toLowerCase()) || 
        b.author.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) return <div className="text-center p-10">Đang tải kho sách...</div>;
    if (error) return <div className="text-red-500 text-center p-10">{error}</div>;

    return (
        <div className="space-y-6">
            <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
                <div>
                    <h2 className="text-2xl font-bold tracking-tight">Kho Sách</h2>
                    <p className="text-gray-500">Quản lý và tra cứu sách trong hệ thống (VPD Enabled)</p>
                </div>
                <div className="flex gap-2 w-full md:w-auto">
                    <div className="relative flex-1 md:w-64">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                        <input 
                            type="text" 
                            placeholder="Tìm kiếm sách..."
                            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-800 dark:border-gray-700"
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    {userRole?.toUpperCase() !== 'READER' && (
                    <button 
                        onClick={handleAddNew}
                        className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium flex items-center gap-2 whitespace-nowrap"
                    >
                        <Plus size={18} />
                        Thêm Sách
                    </button>
                    )}
                </div>
            </header>

            <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                        <thead className="bg-gray-50 dark:bg-gray-700/50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">ID</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Tên Sách</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Author/Year</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Thể loại</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Chi nhánh</th>
                                <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Độ mật (OLS)</th>
                                <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Số lượng</th>
                                {userRole !== 'READER' && (
                                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Thao tác</th>
                                )}
                            </tr>
                        </thead>
                        <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                            {filteredBooks.map((book) => (
                                <tr key={book.book_id} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">#{book.book_id}</td>
                                    <td className="px-6 py-4">
                                        <div className="text-sm font-medium text-gray-900 dark:text-white">{book.title}</div>
                                        <div className="text-xs text-gray-500">{book.publisher}</div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap">
                                        <div className="text-sm text-gray-900 dark:text-white">{book.author}</div>
                                        <div className="text-xs text-gray-500">{book.publish_year}</div>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {book.category_name}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {book.branch_name || `Chi nhánh ${book.branch_id}`}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-center">
                                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-bold rounded-full border ${getSensitivityColor(book.sensitivity_level)}`}>
                                            {translateLevel(book.sensitivity_level)}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-center font-medium text-gray-900 dark:text-white">
                                        <span title="Available / Total">{book.available_qty}/{book.quantity}</span>
                                    </td>
                                    {userRole !== 'READER' && (
                                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium flex justify-end gap-2">
                                        <button 
                                            onClick={() => handleEdit(book)}
                                            className="text-blue-600 hover:text-blue-900 p-1 hover:bg-blue-50 rounded"
                                            title="Sửa sách"
                                        >
                                            <Pencil size={16} />
                                        </button>
                                        <button 
                                            onClick={() => handleDelete(book.book_id, book.title)}
                                            className="text-red-600 hover:text-red-900 p-1 hover:bg-red-50 rounded"
                                            title="Xóa sách"
                                        >
                                            <Trash2 size={16} />
                                        </button>
                                    </td>
                                    )}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

             {/* Modal Form */}
             {isModalOpen && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
                    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-2xl overflow-hidden max-h-[90vh] overflow-y-auto">
                        <div className="p-6 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center sticky top-0 bg-white dark:bg-gray-800 z-10">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
                                {isEditing ? 'Cập nhật Sách' : 'Thêm Sách Mới'}
                            </h3>
                            <button onClick={() => setIsModalOpen(false)} className="text-gray-400 hover:text-gray-500">
                                <X size={20} />
                            </button>
                        </div>
                        
                        <form onSubmit={handleSubmit} className="p-6 space-y-4">
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div className="col-span-2">
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tên sách</label>
                                    <input 
                                        type="text" required
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.title}
                                        onChange={e => setCurrentBook({...currentBook, title: e.target.value})}
                                    />
                                </div>
                                
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tác giả</label>
                                    <input 
                                        type="text" required
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.author}
                                        onChange={e => setCurrentBook({...currentBook, author: e.target.value})}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Nhà xuất bản</label>
                                    <input 
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.publisher}
                                        onChange={e => setCurrentBook({...currentBook, publisher: e.target.value})}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Năm xuất bản</label>
                                    <input 
                                        type="number"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.publish_year}
                                        onChange={e => setCurrentBook({...currentBook, publish_year: Number(e.target.value)})}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">ISBN</label>
                                    <input 
                                        type="text"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.isbn}
                                        onChange={e => setCurrentBook({...currentBook, isbn: e.target.value})}
                                    />
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Thể loại</label>
                                    <select 
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.category_id}
                                        onChange={e => setCurrentBook({...currentBook, category_id: Number(e.target.value)})}
                                    >
                                        {categories.map(c => (
                                            <option key={c.category_id} value={c.category_id}>{c.category_name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Chi nhánh (VPD)</label>
                                    <select 
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.branch_id}
                                        onChange={e => setCurrentBook({...currentBook, branch_id: Number(e.target.value)})}
                                    >
                                        {branches.map(b => (
                                            <option key={b.branch_id} value={b.branch_id}>{b.branch_name}</option>
                                        ))}
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Độ Mật (OLS)</label>
                                    <select 
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.sensitivity_level}
                                        onChange={e => setCurrentBook({...currentBook, sensitivity_level: e.target.value})}
                                    >
                                        <option value="PUBLIC">CÔNG KHAI (Public)</option>
                                        <option value="INTERNAL">NỘI BỘ (Internal)</option>
                                        <option value="CONFIDENTIAL">MẬT (Confidential)</option>
                                        <option value="TOP_SECRET">TỐI MẬT (Top Secret)</option>
                                    </select>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Tổng số lượng</label>
                                    <input 
                                        type="number" min="1"
                                        className="w-full px-3 py-2 border rounded-lg focus:ring-blue-500 dark:bg-gray-700 dark:border-gray-600"
                                        value={currentBook.quantity}
                                        onChange={e => setCurrentBook({...currentBook, quantity: Number(e.target.value)})}
                                    />
                                </div>
                            </div>
                            
                            <div className="pt-4 flex justify-end gap-3 border-t border-gray-100 dark:border-gray-700 mt-4">
                                <button 
                                    type="button"
                                    onClick={() => setIsModalOpen(false)}
                                    className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
                                >
                                    Hủy
                                </button>
                                <button 
                                    type="submit"
                                    disabled={submitting}
                                    className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
                                >
                                    {submitting ? 'Đang lưu...' : (isEditing ? 'Cập nhật' : 'Thêm mới')}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
