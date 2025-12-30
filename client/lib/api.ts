export const API_URL = 'http://localhost:8000/api';

export const getAuthHeaders = () => {
    const user = typeof window !== 'undefined' ? localStorage.getItem('user') : null;
    if (!user) return {};
    
    const { username, password } = JSON.parse(user);
    const credentials = btoa(`${username}:${password}`);
    return {
        'Authorization': `Basic ${credentials}`,
        'Content-Type': 'application/json'
    };
};

export const apiRequest = async (endpoint: string, options: RequestInit = {}) => {
    const headers = { ...getAuthHeaders(), ...options.headers };
    try {
        const response = await fetch(`${API_URL}${endpoint}`, {
            ...options,
            headers: headers as HeadersInit
        });
        
        if (response.status === 401) {
            // Handle unauthorized - maybe redirect to login
            if (typeof window !== 'undefined') {
                window.location.href = '/login';
            }
        }
        
        if (!response.ok) {
           const errorData = await response.json().catch(() => ({}));
           throw new Error(errorData.detail || `Error ${response.status}: ${response.statusText}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API Request Failed:', error);
        throw error;
    }
};

export const logout = () => {
    if (typeof window !== 'undefined') {
        localStorage.removeItem('user');
        window.location.href = '/login';
    }
};
