# Panam - Expense Manager App
## Detailed Implementation Plan & Timeline

---

## 📋 Project Overview

**App Name:** Panam  
**Description:** A personal expense manager app with OCR receipt scanning and bank statement import  
**Platform:** iOS & Android (Flutter)  
**Storage:** Local only (Hive)  
**Target:** MVP in 3-4 weeks

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── colors.dart
│   │   └── strings.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── date_utils.dart
│       ├── currency_utils.dart
│       └── validators.dart
├── data/
│   ├── models/
│   │   ├── transaction.dart
│   │   ├── account.dart
│   │   └── category.dart
│   ├── repositories/
│   │   ├── transaction_repository.dart
│   │   ├── account_repository.dart
│   │   └── category_repository.dart
│   └── local/
│       ├── hive_service.dart
│       └── adapters/
│           ├── transaction_adapter.dart
│           ├── account_adapter.dart
│           └── category_adapter.dart
├── providers/
│   ├── app_provider.dart
│   ├── transaction_provider.dart
│   ├── account_provider.dart
│   └── category_provider.dart
├── services/
│   ├── ocr_service.dart
│   └── statement_parser_service.dart
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       ├── balance_card.dart
│   │       └── recent_transactions.dart
│   ├── transactions/
│   │   ├── transactions_screen.dart
│   │   ├── add_transaction_screen.dart
│   │   └── widgets/
│   │       └── transaction_card.dart
│   ├── accounts/
│   │   ├── accounts_screen.dart
│   │   ├── add_account_screen.dart
│   │   └── widgets/
│   │       └── account_card.dart
│   ├── import/
│   │   ├── ocr_import_screen.dart
│   │   └── statement_import_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── widgets/
    ├── common/
    │   ├── custom_button.dart
    │   ├── custom_text_field.dart
    │   ├── loading_indicator.dart
    │   └── empty_state.dart
    └── dialogs/
        ├── confirm_dialog.dart
        └── category_picker_dialog.dart
```

---

## 📊 Data Models

### Transaction Model
```dart
class Transaction {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String categoryId;
  final String accountId;
  final TransactionType type; // income/expense
  final String? note;
  final DateTime createdAt;
}

enum TransactionType { income, expense }
```

### Account Model
```dart
class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final String? icon;
  final DateTime createdAt;
}

enum AccountType { cash, bank, wallet, card, other }
```

### Category Model
```dart
class Category {
  final String id;
  final String name;
  final String? icon;
  final bool isIncome;
  final bool isDefault;
}
```

---

## 📦 Dependencies to Add

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.2
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Unique IDs
  uuid: ^4.5.1
  
  # File Operations
  file_picker: ^8.1.6
  image_picker: ^1.1.2
  path_provider: ^2.1.5
  
  # OCR
  google_mlkit_text_recognition: ^0.14.0
  
  # PDF Parsing
  syncfusion_flutter_pdf: ^28.2.6
  
  # UI Helpers
  intl: ^0.20.2
  flutter_slidable: ^4.0.0
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.13
```

---

## 🗓️ Implementation Timeline

### Week 1: Foundation & Core Features

---

#### Sprint 1.1: Project Setup (Day 1-2)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 1.1.1 | Add dependencies | Update pubspec.yaml with all required packages | 30 min |
| 1.1.2 | Create folder structure | Set up lib/ directory as per architecture | 30 min |
| 1.1.3 | Configure Hive | Initialize Hive in main.dart, set up service | 1 hr |
| 1.1.4 | Create data models | Transaction, Account, Category models | 2 hr |
| 1.1.5 | Create Hive adapters | TypeAdapters for all models | 1.5 hr |
| 1.1.6 | Set up theme | Create app theme with colors and typography | 1 hr |
| 1.1.7 | Configure app entry | Update main.dart and create app.dart | 30 min |

**Deliverables:**
- [ ] All dependencies installed
- [ ] Folder structure created
- [ ] Hive initialized and working
- [ ] Models created with Hive adapters
- [ ] App runs without errors

**Files to Create:**
```
lib/main.dart (update)
lib/app.dart
lib/core/constants/app_constants.dart
lib/core/constants/colors.dart
lib/core/constants/strings.dart
lib/core/theme/app_theme.dart
lib/data/models/transaction.dart
lib/data/models/account.dart
lib/data/models/category.dart
lib/data/local/hive_service.dart
lib/data/local/adapters/transaction_adapter.dart
lib/data/local/adapters/account_adapter.dart
lib/data/local/adapters/category_adapter.dart
```

---

#### Sprint 1.2: State Management & Repositories (Day 2-3)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 1.2.1 | Create repositories | CRUD operations for each model | 2 hr |
| 1.2.2 | Create providers | ChangeNotifier for each domain | 2 hr |
| 1.2.3 | Set up MultiProvider | Configure providers in app.dart | 30 min |
| 1.2.4 | Add default categories | Seed default expense/income categories | 1 hr |
| 1.2.5 | Test state management | Verify data flow works correctly | 1.5 hr |

**Deliverables:**
- [ ] Repositories with CRUD operations
- [ ] Providers connected to repositories
- [ ] Default categories seeded on first launch
- [ ] State updates reflected in UI

**Files to Create:**
```
lib/data/repositories/transaction_repository.dart
lib/data/repositories/account_repository.dart
lib/data/repositories/category_repository.dart
lib/providers/app_provider.dart
lib/providers/transaction_provider.dart
lib/providers/account_provider.dart
lib/providers/category_provider.dart
```

---

#### Sprint 1.3: Navigation & Shell (Day 3-4)
**Estimated Time: 4-6 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 1.3.1 | Create bottom nav | BottomNavigationBar with 4 tabs | 1 hr |
| 1.3.2 | Create screen stubs | Empty screens for all main routes | 1 hr |
| 1.3.3 | Create common widgets | Button, TextField, LoadingIndicator | 2 hr |
| 1.3.4 | Add utility functions | Date formatting, currency formatting | 1 hr |

**Deliverables:**
- [ ] Navigation between all main screens
- [ ] Reusable UI components ready
- [ ] Utility functions available

**Files to Create:**
```
lib/screens/home/home_screen.dart
lib/screens/transactions/transactions_screen.dart
lib/screens/accounts/accounts_screen.dart
lib/screens/settings/settings_screen.dart
lib/widgets/common/custom_button.dart
lib/widgets/common/custom_text_field.dart
lib/widgets/common/loading_indicator.dart
lib/widgets/common/empty_state.dart
lib/core/utils/date_utils.dart
lib/core/utils/currency_utils.dart
lib/core/utils/validators.dart
```

---

#### Sprint 1.4: Dashboard/Home Screen (Day 4-5)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 1.4.1 | Balance card widget | Shows total balance, income, expense | 2 hr |
| 1.4.2 | Recent transactions list | Last 5-10 transactions | 2 hr |
| 1.4.3 | Quick action buttons | Add expense/income FAB | 1 hr |
| 1.4.4 | Connect to provider | Display real data from state | 1.5 hr |

**Deliverables:**
- [ ] Dashboard shows total balance
- [ ] Recent transactions displayed
- [ ] Quick actions accessible

**Files to Create/Update:**
```
lib/screens/home/home_screen.dart (update)
lib/screens/home/widgets/balance_card.dart
lib/screens/home/widgets/recent_transactions.dart
lib/widgets/common/transaction_tile.dart
```

---

### Week 2: Core Transaction Features

---

#### Sprint 2.1: Transactions List & Card (Day 6-7)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 2.1.1 | Transaction card widget | Display single transaction details | 2 hr |
| 2.1.2 | Transactions list | ListView with all transactions | 2 hr |
| 2.1.3 | Swipe actions | Delete/edit on swipe | 1.5 hr |
| 2.1.4 | Empty state | Show when no transactions | 30 min |

**Deliverables:**
- [ ] All transactions visible in list
- [ ] Transaction cards show relevant info
- [ ] Swipe to delete/edit works

**Files to Create:**
```
lib/screens/transactions/transactions_screen.dart (update)
lib/screens/transactions/widgets/transaction_card.dart
```

---

#### Sprint 2.2: Add/Edit Transaction (Day 7-8)
**Estimated Time: 8-10 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 2.2.1 | Add transaction form | Amount, description, date fields | 2 hr |
| 2.2.2 | Category picker | Grid/list of categories | 1.5 hr |
| 2.2.3 | Account selector | Dropdown of accounts | 1 hr |
| 2.2.4 | Date picker | Calendar date selection | 1 hr |
| 2.2.5 | Form validation | Validate all inputs | 1 hr |
| 2.2.6 | Edit transaction | Pre-fill form for editing | 1.5 hr |
| 2.2.7 | Save logic | Connect to provider | 1 hr |

**Deliverables:**
- [ ] Can add new transaction with all fields
- [ ] Can edit existing transaction
- [ ] Form validates correctly
- [ ] Transaction saved to Hive

**Files to Create:**
```
lib/screens/transactions/add_transaction_screen.dart
lib/widgets/dialogs/category_picker_dialog.dart
```

---

#### Sprint 2.3: Accounts Feature (Day 8-9)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 2.3.1 | Account card widget | Display account with balance | 1.5 hr |
| 2.3.2 | Accounts list | All accounts with balances | 1.5 hr |
| 2.3.3 | Add account form | Name, type, initial balance | 2 hr |
| 2.3.4 | Edit/delete account | Modify existing accounts | 1.5 hr |
| 2.3.5 | Calculate balance | Sum transactions per account | 1 hr |

**Deliverables:**
- [ ] All accounts visible with balances
- [ ] Can add/edit/delete accounts
- [ ] Balance calculated from transactions

**Files to Create:**
```
lib/screens/accounts/accounts_screen.dart (update)
lib/screens/accounts/add_account_screen.dart
lib/screens/accounts/widgets/account_card.dart
```

---

#### Sprint 2.4: Categories Management (Day 9-10)
**Estimated Time: 4-6 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 2.4.1 | Categories list | View all categories | 1.5 hr |
| 2.4.2 | Add custom category | Form to add new | 1.5 hr |
| 2.4.3 | Edit/delete category | Modify custom categories | 1.5 hr |
| 2.4.4 | Category icons | Icon selection for categories | 1 hr |

**Deliverables:**
- [ ] Default categories displayed
- [ ] Can add custom categories
- [ ] Can edit/delete non-default categories

**Files to Create:**
```
lib/screens/settings/categories_screen.dart
lib/screens/settings/add_category_screen.dart
```

---

### Week 3: OCR & Import Features

---

#### Sprint 3.1: OCR Service Setup (Day 11-12)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 3.1.1 | Configure permissions | iOS/Android camera permissions | 1 hr |
| 3.1.2 | Create OCR service | Integrate ML Kit text recognition | 2 hr |
| 3.1.3 | Image capture | Camera and gallery options | 1.5 hr |
| 3.1.4 | Text extraction | Get text from image | 1 hr |
| 3.1.5 | Test on device | Verify OCR works on real device | 1.5 hr |

**Deliverables:**
- [ ] Camera permissions configured
- [ ] Can capture/select image
- [ ] Text extracted from image

**Files to Create:**
```
lib/services/ocr_service.dart
android/app/src/main/AndroidManifest.xml (update)
ios/Runner/Info.plist (update)
```

---

#### Sprint 3.2: Receipt Parsing (Day 12-13)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 3.2.1 | Parse amount | Regex to extract amounts | 2 hr |
| 3.2.2 | Parse date | Regex for date formats | 1.5 hr |
| 3.2.3 | Parse description | Extract merchant/description | 1.5 hr |
| 3.2.4 | Confidence scoring | Rank parsed results | 1 hr |
| 3.2.5 | Test with receipts | Test various receipt formats | 1.5 hr |

**Deliverables:**
- [ ] Amount extracted from receipt
- [ ] Date extracted when present
- [ ] Description/merchant identified

**Files to Update:**
```
lib/services/ocr_service.dart (add parsing methods)
```

---

#### Sprint 3.3: OCR Import Screen (Day 13-14)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 3.3.1 | Import screen UI | Scan button, preview area | 2 hr |
| 3.3.2 | Parsed data preview | Show extracted info | 1.5 hr |
| 3.3.3 | Edit before save | Allow corrections | 1.5 hr |
| 3.3.4 | Confirm and save | Add to transactions | 1 hr |
| 3.3.5 | Error handling | Handle OCR failures | 1 hr |

**Deliverables:**
- [ ] Complete OCR import flow
- [ ] User can edit parsed data
- [ ] Transaction created from receipt

**Files to Create:**
```
lib/screens/import/ocr_import_screen.dart
lib/screens/import/widgets/parsed_receipt_preview.dart
```

---

#### Sprint 3.4: Bank Statement Parser (Day 14-15)
**Estimated Time: 8-10 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 3.4.1 | PDF parser service | Syncfusion PDF text extraction | 2 hr |
| 3.4.2 | Statement parsing | Regex for transaction rows | 3 hr |
| 3.4.3 | Image statement | Reuse OCR for image statements | 1.5 hr |
| 3.4.4 | Transaction mapping | Map parsed data to model | 1.5 hr |
| 3.4.5 | Test with samples | Test various statement formats | 2 hr |

**Deliverables:**
- [ ] Can extract text from PDF
- [ ] Transactions parsed from statement
- [ ] Works with image statements too

**Files to Create:**
```
lib/services/statement_parser_service.dart
```

---

### Week 4: Import UI & Polish

---

#### Sprint 4.1: Statement Import Screen (Day 16-17)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 4.1.1 | File picker UI | Select PDF/image | 1.5 hr |
| 4.1.2 | Parsing progress | Loading indicator during parse | 1 hr |
| 4.1.3 | Transaction preview | List of parsed transactions | 2 hr |
| 4.1.4 | Select/deselect | Choose which to import | 1.5 hr |
| 4.1.5 | Import action | Save selected to Hive | 1 hr |

**Deliverables:**
- [ ] Complete statement import flow
- [ ] User can select which transactions to import
- [ ] Imported transactions visible in app

**Files to Create:**
```
lib/screens/import/statement_import_screen.dart
lib/screens/import/widgets/transaction_preview_list.dart
```

---

#### Sprint 4.2: Deduplication & Validation (Day 17-18)
**Estimated Time: 4-6 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 4.2.1 | Duplicate detection | Check existing transactions | 2 hr |
| 4.2.2 | Mark duplicates | Visual indicator for duplicates | 1 hr |
| 4.2.3 | Import validation | Ensure data integrity | 1.5 hr |

**Deliverables:**
- [ ] Duplicates detected and marked
- [ ] User warned about duplicates
- [ ] Clean data imported

**Files to Update:**
```
lib/services/statement_parser_service.dart
lib/screens/import/statement_import_screen.dart
```

---

#### Sprint 4.3: Settings & Polish (Day 18-19)
**Estimated Time: 6-8 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 4.3.1 | Settings screen | Manage categories link | 1.5 hr |
| 4.3.2 | About section | App version, info | 30 min |
| 4.3.3 | Loading states | Add indicators everywhere | 1.5 hr |
| 4.3.4 | Error handling | User-friendly error messages | 2 hr |
| 4.3.5 | Empty states | All screens have empty states | 1 hr |

**Deliverables:**
- [ ] Settings screen complete
- [ ] Loading/error states everywhere
- [ ] Consistent UX across app

**Files to Create/Update:**
```
lib/screens/settings/settings_screen.dart (update)
lib/widgets/dialogs/error_dialog.dart
```

---

#### Sprint 4.4: Testing & Bug Fixes (Day 19-21)
**Estimated Time: 8-12 hours**

| Task ID | Task | Description | Time |
|---------|------|-------------|------|
| 4.4.1 | Unit tests | Test parsing functions | 2 hr |
| 4.4.2 | Widget tests | Test key UI flows | 2 hr |
| 4.4.3 | Manual testing | Test on real devices | 3 hr |
| 4.4.4 | Bug fixes | Fix identified issues | 3 hr |
| 4.4.5 | Performance check | Ensure smooth performance | 1.5 hr |

**Deliverables:**
- [ ] Core functionality tested
- [ ] Major bugs fixed
- [ ] App performs well

**Files to Create:**
```
test/unit/ocr_service_test.dart
test/unit/statement_parser_test.dart
test/widget/transaction_form_test.dart
```

---

## 🎯 Milestones Summary

| Milestone | Date | Success Criteria |
|-----------|------|------------------|
| **M1: Foundation** | End of Day 3 | App runs, Hive works, navigation complete |
| **M2: Core Transactions** | End of Day 10 | Can add/edit/view transactions & accounts |
| **M3: OCR Import** | End of Day 14 | Can scan receipt and create transaction |
| **M4: Statement Import** | End of Day 17 | Can import from PDF/image statement |
| **M5: MVP Complete** | End of Day 21 | All features work, basic testing done |

---

## 📝 Default Categories

### Expense Categories
1. 🍔 Food & Dining
2. 🚗 Transport
3. 🛒 Shopping
4. 🏠 Housing
5. 💡 Utilities
6. 🎬 Entertainment
7. 💊 Healthcare
8. 📚 Education
9. 👔 Personal Care
10. 🎁 Gifts
11. 📦 Other

### Income Categories
1. 💼 Salary
2. 💰 Freelance
3. 📈 Investment
4. 🎁 Gift Received
5. 💵 Other Income

---

## 🔧 iOS/Android Configuration

### iOS (Info.plist additions)
```xml
<key>NSCameraUsageDescription</key>
<string>Panam needs camera access to scan receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Panam needs photo library access to import receipt images</string>
```

### Android (AndroidManifest.xml additions)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

---

## 📌 Quick Reference Commands

```bash
# Add dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## ⚠️ Known Limitations (MVP)

1. No cloud sync - data is local only
2. Basic regex parsing - may not work for all receipt formats
3. No budget tracking
4. No charts/analytics
5. No search/filter
6. No data export
7. No dark mode
8. Single currency only

---

## 🚀 Post-MVP Features (Future)

- [ ] Budget tracking with alerts
- [ ] Charts and analytics (fl_chart)
- [ ] Cloud sync (Firebase)
- [ ] Search and filter
- [ ] Data export (CSV)
- [ ] Dark mode
- [ ] Multi-currency support
- [ ] Recurring transactions
- [ ] Bill reminders
- [ ] ML-based categorization
