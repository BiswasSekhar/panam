package api

import (
	"database/sql"
	"net/http"
	"panam/backend/models"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type Handler struct {
	db *sql.DB
}

func NewHandler(db *sql.DB) *Handler {
	return &Handler{db: db}
}

func (h *Handler) Register(c *gin.Context) {
	var req models.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	userID := uuid.New().String()
	_, err = h.db.Exec("INSERT INTO users (id, email, password_hash, name) VALUES (?, ?, ?, ?)",
		userID, req.Email, string(hashedPassword), req.Name)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Email already exists"})
		return
	}

	token, err := GenerateToken(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"token": token, "user_id": userID})
}

func (h *Handler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	err := h.db.QueryRow("SELECT id, password_hash FROM users WHERE email = ?", req.Email).
		Scan(&user.ID, &user.PasswordHash)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	token, err := GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": token, "user_id": user.ID})
}

func (h *Handler) CreateTransaction(c *gin.Context) {
	userID := c.GetString("user_id")
	var txn models.Transaction
	if err := c.ShouldBindJSON(&txn); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	txn.ID = uuid.New().String()
	txn.UserID = userID
	txn.CreatedAt = time.Now()

	_, err := h.db.Exec(`INSERT INTO transactions (id, user_id, type, category, amount, description, date, is_recurring, recurring_frequency)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		txn.ID, txn.UserID, txn.Type, txn.Category, txn.Amount, txn.Description, txn.Date, txn.IsRecurring, txn.RecurringFrequency)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create transaction"})
		return
	}

	c.JSON(http.StatusCreated, txn)
}

func (h *Handler) GetTransactions(c *gin.Context) {
	userID := c.GetString("user_id")
	rows, err := h.db.Query(`SELECT id, type, category, amount, description, date, is_recurring, recurring_frequency, created_at
		FROM transactions WHERE user_id = ? ORDER BY date DESC`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch transactions"})
		return
	}
	defer rows.Close()

	var transactions []models.Transaction
	for rows.Next() {
		var txn models.Transaction
		err := rows.Scan(&txn.ID, &txn.Type, &txn.Category, &txn.Amount, &txn.Description, &txn.Date, &txn.IsRecurring, &txn.RecurringFrequency, &txn.CreatedAt)
		if err != nil {
			continue
		}
		txn.UserID = userID
		transactions = append(transactions, txn)
	}

	c.JSON(http.StatusOK, transactions)
}

func (h *Handler) DeleteTransaction(c *gin.Context) {
	userID := c.GetString("user_id")
	txnID := c.Param("id")

	_, err := h.db.Exec("DELETE FROM transactions WHERE id = ? AND user_id = ?", txnID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Transaction deleted"})
}

func (h *Handler) CreateDebtCredit(c *gin.Context) {
	userID := c.GetString("user_id")
	var dc models.DebtCredit
	if err := c.ShouldBindJSON(&dc); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	dc.ID = uuid.New().String()
	dc.UserID = userID
	dc.Status = "pending"
	dc.CreatedAt = time.Now()

	_, err := h.db.Exec(`INSERT INTO debts_credits (id, user_id, type, person_name, amount, description, due_date, status)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		dc.ID, dc.UserID, dc.Type, dc.PersonName, dc.Amount, dc.Description, dc.DueDate, dc.Status)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create debt/credit"})
		return
	}

	c.JSON(http.StatusCreated, dc)
}

func (h *Handler) GetDebtsCredits(c *gin.Context) {
	userID := c.GetString("user_id")
	rows, err := h.db.Query(`SELECT id, type, person_name, amount, description, due_date, status, created_at
		FROM debts_credits WHERE user_id = ? ORDER BY created_at DESC`, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch debts/credits"})
		return
	}
	defer rows.Close()

	var debtsCredits []models.DebtCredit
	for rows.Next() {
		var dc models.DebtCredit
		err := rows.Scan(&dc.ID, &dc.Type, &dc.PersonName, &dc.Amount, &dc.Description, &dc.DueDate, &dc.Status, &dc.CreatedAt)
		if err != nil {
			continue
		}
		dc.UserID = userID
		debtsCredits = append(debtsCredits, dc)
	}

	c.JSON(http.StatusOK, debtsCredits)
}

func (h *Handler) SettleDebtCredit(c *gin.Context) {
	userID := c.GetString("user_id")
	dcID := c.Param("id")

	_, err := h.db.Exec("UPDATE debts_credits SET status = 'settled' WHERE id = ? AND user_id = ?", dcID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to settle"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Settled successfully"})
}

func (h *Handler) GetSummary(c *gin.Context) {
	userID := c.GetString("user_id")

	var totalIncome, totalExpense float64
	h.db.QueryRow("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE user_id = ? AND type = 'income'", userID).Scan(&totalIncome)
	h.db.QueryRow("SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE user_id = ? AND type = 'expense'", userID).Scan(&totalExpense)

	var totalDebt, totalCredit float64
	h.db.QueryRow("SELECT COALESCE(SUM(amount), 0) FROM debts_credits WHERE user_id = ? AND type = 'debt' AND status = 'pending'", userID).Scan(&totalDebt)
	h.db.QueryRow("SELECT COALESCE(SUM(amount), 0) FROM debts_credits WHERE user_id = ? AND type = 'credit' AND status = 'pending'", userID).Scan(&totalCredit)

	c.JSON(http.StatusOK, gin.H{
		"total_income":  totalIncome,
		"total_expense": totalExpense,
		"balance":       totalIncome - totalExpense,
		"total_debt":    totalDebt,
		"total_credit":  totalCredit,
	})
}
