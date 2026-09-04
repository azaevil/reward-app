import axios from 'axios';

const api = axios.create({
  baseURL: 'http://127.0.0.1:8000',
});

// Request Interceptor: Her isteğe Authorization header ekler
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response Interceptor: 401 Unauthorized hatalarını yakalar
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token');
    }
    return Promise.reject(error);
  }
);

export const adminApi = {
  getRevenueStats: async () => {
    const response = await api.get('/admin/analytics/revenue');
    return response.data;
  },
  getWithdrawals: async () => {
    const response = await api.get('/admin/withdrawals');
    return response.data;
  },
  approveWithdrawal: async (withdrawalId) => {
    const response = await api.post(`/admin/withdrawals/${withdrawalId}/approve`);
    return response.data;
  },
  approveAllWithdrawals: async () => {
    const response = await api.post('/admin/withdrawals/approve-all');
    return response.data;
  },
  login: async (email, password) => {
    const response = await api.post('/auth/login', {
      email: email,
      password: password
    });
    if (response.data && response.data.access_token) {
      localStorage.setItem('token', response.data.access_token);
    }
    return response.data;
  },
  logout: () => {
    localStorage.removeItem('token');
  }
};

export default api;