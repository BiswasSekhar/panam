package api

import (
	"database/sql"
	"github.com/gin-gonic/gin"
)

func SetupRouter(db *sql.DB) *gin.Engine {
	router := gin.Default()

	// CORS middleware
	router.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	handler := NewHandler(db)

	// Auth routes
	auth := router.Group("/api/auth")
	{
		auth.POST("/register", handler.Register)
		auth.POST("/login", handler.Login)
	}

	// Protected routes
	api := router.Group("/api")
	api.Use(AuthMiddleware())
	{
		// Transactions
		api.POST("/transactions", handler.CreateTransaction)
		api.GET("/transactions", handler.GetTransactions)
		api.DELETE("/transactions/:id", handler.DeleteTransaction)

		// Debts & Credits
		api.POST("/debts-credits", handler.CreateDebtCredit)
		api.GET("/debts-credits", handler.GetDebtsCredits)
		api.PUT("/debts-credits/:id/settle", handler.SettleDebtCredit)

		// Analytics
		api.GET("/analytics/summary", handler.GetSummary)
	}

	return router
}
