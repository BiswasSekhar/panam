export interface User {
  id: string;
  email: string;
  name: string;
  created_at: string;
}

export interface Transaction {
  id: string;
  user_id: string;
  type: 'income' | 'expense';
  category: string;
  amount: number;
  description: string;
  date: string;
  is_recurring: boolean;
  recurring_frequency?: 'daily' | 'weekly' | 'monthly';
  created_at: string;
}

export interface DebtCredit {
  id: string;
  user_id: string;
  type: 'debt' | 'credit';
  person_name: string;
  amount: number;
  description: string;
  due_date?: string;
  status: 'pending' | 'settled';
  created_at: string;
}

export interface AuthResponse {
  token: string;
  user_id: string;
}

export interface Summary {
  total_income: number;
  total_expense: number;
  balance: number;
  total_debt: number;
  total_credit: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}
