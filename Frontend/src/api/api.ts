import axios, { AxiosResponse } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { 
  AuthResponse, 
  LoginRequest, 
  RegisterRequest, 
  Transaction, 
  DebtCredit, 
  Summary 
} from '../types';

const API_URL = 'http://192.168.29.36:8080/api';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const auth = {
  register: (data: RegisterRequest): Promise<AxiosResponse<AuthResponse>> => 
    axios.post(`${API_URL}/auth/register`, data),
  login: (data: LoginRequest): Promise<AxiosResponse<AuthResponse>> => 
    axios.post(`${API_URL}/auth/login`, data),
};

export const transactions = {
  getAll: (): Promise<AxiosResponse<Transaction[]>> => 
    api.get('/transactions'),
  create: (data: Partial<Transaction>): Promise<AxiosResponse<Transaction>> => 
    api.post('/transactions', data),
  delete: (id: string): Promise<AxiosResponse<{ message: string }>> => 
    api.delete(`/transactions/${id}`),
};

export const debtsCredits = {
  getAll: (): Promise<AxiosResponse<DebtCredit[]>> => 
    api.get('/debts-credits'),
  create: (data: Partial<DebtCredit>): Promise<AxiosResponse<DebtCredit>> => 
    api.post('/debts-credits', data),
  settle: (id: string): Promise<AxiosResponse<{ message: string }>> => 
    api.put(`/debts-credits/${id}/settle`),
};

export const analytics = {
  getSummary: (): Promise<AxiosResponse<Summary>> => 
    api.get('/analytics/summary'),
};

export default api;
