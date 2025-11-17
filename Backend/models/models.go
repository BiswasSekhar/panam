package models

import "time"

type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	Name         string    `json:"name"`
	CreatedAt    time.Time `json:"created_at"`
}

type Transaction struct {
	ID                 string    `json:"id"`
	UserID             string    `json:"user_id"`
	Type               string    `json:"type"` // income, expense
	Category           string    `json:"category"`
	Amount             float64   `json:"amount"`
	Description        string    `json:"description"`
	Date               string    `json:"date"`
	IsRecurring        bool      `json:"is_recurring"`
	RecurringFrequency string    `json:"recurring_frequency,omitempty"` // daily, weekly, monthly
	CreatedAt          time.Time `json:"created_at"`
}

type DebtCredit struct {
	ID          string    `json:"id"`
	UserID      string    `json:"user_id"`
	Type        string    `json:"type"` // debt, credit
	PersonName  string    `json:"person_name"`
	Amount      float64   `json:"amount"`
	Description string    `json:"description"`
	DueDate     string    `json:"due_date,omitempty"`
	Status      string    `json:"status"` // pending, settled
	CreatedAt   time.Time `json:"created_at"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type RegisterRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
	Name     string `json:"name" binding:"required"`
}
