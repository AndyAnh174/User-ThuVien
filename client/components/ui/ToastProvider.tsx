'use client';

import React, { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { X, CheckCircle, AlertCircle, Info, AlertTriangle } from 'lucide-react';

type ToastType = 'success' | 'error' | 'info' | 'warning';

interface Toast {
    id: number;
    message: string;
    type: ToastType;
}

interface ToastContextType {
    showToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export function ToastProvider({ children }: { children: React.ReactNode }) {
    const [toasts, setToasts] = useState<Toast[]>([]);

    const showToast = useCallback((message: string, type: ToastType = 'info') => {
        const id = Date.now();
        setToasts(prev => [...prev, { id, message, type }]);

        // Auto remove after 3 seconds
        setTimeout(() => {
            setToasts(prev => prev.filter(t => t.id !== id));
        }, 3000);
    }, []);

    const removeToast = (id: number) => {
        setToasts(prev => prev.filter(t => t.id !== id));
    };

    return (
        <ToastContext.Provider value={{ showToast }}>
            {children}
            <div className="fixed top-5 right-5 z-[9999] flex flex-col gap-2">
                {toasts.map(toast => (
                    <div 
                        key={toast.id}
                        className={`
                            min-w-[300px] max-w-md p-4 rounded-lg shadow-lg border flex items-start gap-3 transform transition-all duration-300 animate-in slide-in-from-right-full
                            ${toast.type === 'success' ? 'bg-white border-green-200 text-green-800 dark:bg-gray-800 dark:border-green-900' : ''}
                            ${toast.type === 'error' ? 'bg-white border-red-200 text-red-800 dark:bg-gray-800 dark:border-red-900' : ''}
                            ${toast.type === 'info' ? 'bg-white border-blue-200 text-blue-800 dark:bg-gray-800 dark:border-blue-900' : ''}
                            ${toast.type === 'warning' ? 'bg-white border-yellow-200 text-yellow-800 dark:bg-gray-800 dark:border-yellow-900' : ''}
                        `}
                    >
                        <div className="mt-0.5">
                            {toast.type === 'success' && <CheckCircle size={20} className="text-green-500" />}
                            {toast.type === 'error' && <AlertCircle size={20} className="text-red-500" />}
                            {toast.type === 'info' && <Info size={20} className="text-blue-500" />}
                            {toast.type === 'warning' && <AlertTriangle size={20} className="text-yellow-500" />}
                        </div>
                        <div className="flex-1 text-sm font-medium pt-0.5 dark:text-gray-200">
                            {toast.message}
                        </div>
                        <button 
                            onClick={() => removeToast(toast.id)}
                            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                        >
                            <X size={16} />
                        </button>
                    </div>
                ))}
            </div>
        </ToastContext.Provider>
    );
}

export function useToast() {
    const context = useContext(ToastContext);
    if (context === undefined) {
        throw new Error('useToast must be used within a ToastProvider');
    }
    return context;
}
