# Panam - Expense Tracker

A modern expense tracking app built with React Native (TypeScript) and Go, designed for Indian finance management.

## Features

- 💰 Track income and expenses with categories
- 🔄 Recurring transactions support
- 💳 Debts and credits management
- 📄 PDF scanning for automatic transaction extraction (offline)
- 📊 Financial analytics dashboard
- 🎨 Modern, minimalistic, vibrant UI
- 🔐 JWT authentication
- 🇮🇳 Indian Rupee (₹) currency support

## Tech Stack

**Frontend:**
- React Native (Expo) with TypeScript
- React Navigation
- Axios for API calls
- AsyncStorage for local data
- Type-safe API layer

**Backend:**
- Go (Gin framework)
- SQLite database
- JWT authentication
- RESTful API

## Getting Started

### Quick Start

**Backend:**
```bash
./start-backend.sh
```
Or manually:
```bash
cd Backend
go mod download
go run main.go
```
Server runs on `http://localhost:8080`

**Frontend:**
```bash
./start-frontend.sh
```
Or manually:
```bash
cd Frontend
npm install
npm start
```

For detailed setup instructions, see [SETUP.md](SETUP.md)

For feature roadmap, see [FEATURES.md](FEATURES.md)

## API Endpoints

- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login user
- `GET /api/transactions` - Get all transactions
- `POST /api/transactions` - Create transaction
- `DELETE /api/transactions/:id` - Delete transaction
- `GET /api/debts-credits` - Get debts/credits
- `POST /api/debts-credits` - Create debt/credit
- `PUT /api/debts-credits/:id/settle` - Settle debt/credit
- `GET /api/analytics/summary` - Get financial summary

## Project Structure

```
panam/
├── Backend/
│   ├── main.go
│   ├── api/
│   │   ├── router.go
│   │   ├── handler.go
│   │   └── auth.go
│   ├── db/
│   │   └── db.go
│   └── models/
│       └── models.go
└── Frontend/
    ├── App.tsx
    ├── tsconfig.json
    ├── src/
    │   ├── types/
    │   │   └── index.ts
    │   ├── api/
    │   │   └── api.ts
    │   └── screens/
    │       ├── LoginScreen.tsx
    │       ├── RegisterScreen.tsx
    │       ├── HomeScreen.tsx
    │       ├── TransactionsScreen.tsx
    │       ├── DebtsCreditsScreen.tsx
    │       ├── AddTransactionScreen.tsx
    │       └── ScanPDFScreen.tsx
    └── package.json
```

## License

MIT
