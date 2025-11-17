# Panam Features & Roadmap

## ✅ Implemented Features

### Authentication
- User registration with email/password
- JWT-based login
- Secure token storage with AsyncStorage
- Protected routes

### Transaction Management
- Add income/expense transactions
- Category selection (Food, Transport, Shopping, Bills, Entertainment, Health, Salary, Other)
- Amount tracking in Indian Rupees (₹)
- Transaction descriptions
- Date selection
- View all transactions
- Delete transactions (long press)

### Recurring Transactions
- Mark transactions as recurring
- Frequency options: Daily, Weekly, Monthly
- Visual indicator for recurring items

### Debts & Credits
- Track money owed (debts)
- Track money to receive (credits)
- Person name tracking
- Due date support
- Settle debts/credits
- Status tracking (pending/settled)

### Analytics Dashboard
- Current balance calculation
- Total income summary
- Total expenses summary
- Pending debts total
- Pending credits total
- Pull-to-refresh functionality

### PDF Scanning (Scaffolded)
- PDF document picker
- Ready for OCR integration
- Offline processing capability
- Auto-transaction creation (coming soon)

### UI/UX
- Modern, minimalistic design
- Vibrant color scheme (Indigo primary)
- Bottom tab navigation
- Modal screens for actions
- Responsive layouts
- Indian finance context

## 🚧 Upcoming Features

### Phase 1: Enhanced PDF Scanning
- [ ] Integrate Tesseract OCR or Vision Camera OCR
- [ ] Extract transaction details from bank statements
- [ ] Parse common Indian bank PDF formats (SBI, HDFC, ICICI, etc.)
- [ ] Auto-categorize based on merchant names
- [ ] Batch import multiple transactions

### Phase 2: Advanced Analytics
- [ ] Monthly/yearly expense charts
- [ ] Category-wise breakdown (pie charts)
- [ ] Spending trends over time
- [ ] Budget vs actual comparison
- [ ] Export reports as PDF/CSV

### Phase 3: Smart Features
- [ ] Budget setting per category
- [ ] Spending alerts and notifications
- [ ] Bill payment reminders
- [ ] Recurring transaction auto-creation
- [ ] AI-powered expense categorization
- [ ] Merchant name recognition

### Phase 4: Indian Finance Specific
- [ ] UPI transaction import
- [ ] GST tracking for businesses
- [ ] Income tax calculation helper
- [ ] Investment tracking (Mutual Funds, Stocks)
- [ ] EMI calculator and tracker
- [ ] Festival budget planner

### Phase 5: Social & Sharing
- [ ] Split expenses with friends
- [ ] Group expense tracking
- [ ] Shared debt/credit management
- [ ] Export and share reports

### Phase 6: Data & Security
- [ ] Cloud backup (optional)
- [ ] Biometric authentication
- [ ] Data encryption
- [ ] Multi-device sync
- [ ] Offline-first architecture improvements

## 🎨 UI Enhancements Planned
- [ ] Dark mode support
- [ ] Custom themes
- [ ] Animated transitions
- [ ] Haptic feedback
- [ ] Gesture controls
- [ ] Widget support (iOS/Android)

## 🔧 Technical Improvements
- [ ] Unit tests (Frontend & Backend)
- [ ] Integration tests
- [ ] CI/CD pipeline
- [ ] Docker containerization
- [ ] PostgreSQL option for production
- [ ] Redis caching layer
- [ ] Rate limiting
- [ ] API versioning

## 📱 Platform Support
- [x] iOS (via Expo)
- [x] Android (via Expo)
- [ ] Web version
- [ ] Desktop app (Electron)

## 🌐 Localization
- [x] English
- [ ] Hindi
- [ ] Tamil
- [ ] Telugu
- [ ] Bengali
- [ ] Other Indian languages
