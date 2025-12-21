# 💰 Panam - Smart Expense Manager

A beautiful, modern expense tracking application built with Flutter, featuring intelligent bank statement import, OCR support, and cross-account self-transfer detection.

## ✨ Features

### 📊 Core Functionality
- **Multi-Account Management** - Track expenses across multiple bank accounts with a beautiful carousel interface
- **Smart Categorization** - Organize transactions with customizable categories
- **Analytics Dashboard** - Visualize spending patterns with insightful charts
- **Glassmorphic UI** - Modern design with blur effects and smooth animations
- **Dark/Light Mode** - Seamless theme switching with proper contrast

### 🏦 Bank Statement Import
- **PDF Import** - Extract transactions directly from bank statements
- **OCR Support** - Uses Google ML Kit for image-based PDFs
- **Multi-Bank Support** - Built-in parsers for:
  - Kotak Mahindra Bank
  - State Bank of India (SBI)
- **Encrypted PDF Support** - Import password-protected statements
- **Duplicate Detection** - Automatically identifies and prevents duplicate entries
- **Month Filtering** - Select specific months to import

### 🔄 Self-Transfer Detection
- **Cross-Account Matching** - Automatically detects transfers between your accounts
- **Reference Number Matching** - Uses transaction reference numbers for accurate detection
- **Fuzzy Matching** - Falls back to amount + date matching when needed
- **Smart Totals** - Excludes self-transfers from global income/expense calculations
- **Per-Account Accuracy** - Includes transfers in individual account balances

### 📱 User Experience
- **Transaction Editing** - Tap any transaction to edit details
- **Slidable Actions** - Swipe transactions for quick delete/edit
- **Category Creation** - Add categories on-the-fly during transaction entry
- **Import Sequence Preservation** - Maintains PDF table order in transaction display
- **4-Tab Navigation** - Home, Analytics, Accounts, and Settings
- **Floating Action Button** - Quick access to add transactions

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/panam.git
cd panam
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🏗️ Architecture

### State Management
- **Provider Pattern** - Uses ChangeNotifier for reactive state management
- **Separation of Concerns** - Distinct providers for accounts, categories, and transactions

### Data Persistence
- **Hive Database** - Fast, lightweight NoSQL database for local storage
- **Type Adapters** - Generated adapters for Account, Category, and Transaction models

### Import Pipeline
1. PDF text extraction (Syncfusion Flutter PDF)
2. Bank-specific parsing (regex-based)
3. Month filtering
4. Duplicate detection
5. Self-transfer matching across accounts
6. Hive storage with sequence preservation

## 📦 Dependencies

Key packages used:
- `hive` & `hive_flutter` - Local database
- `provider` - State management
- `syncfusion_flutter_pdf` - PDF text extraction
- `google_mlkit_text_recognition` - OCR support
- `flutter_slidable` - Swipeable list items
- `intl` - Date/number formatting

## 🎨 Design Philosophy

Panam features a modern glassmorphic design with:
- Backdrop blur effects for depth
- Smooth animations and transitions
- Color-coded transaction types (income/expense)
- Theme-aware contrast adjustments
- Responsive layouts for various screen sizes

## 🔐 Privacy & Security

- **100% Local** - All data stored locally on device using Hive
- **No Cloud Sync** - Your financial data never leaves your device
- **Password-Protected PDFs** - Secure import of encrypted statements
- **No Analytics** - No tracking or data collection

## 🧪 Testing

Run tests:
```bash
flutter test
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

Made with ❤️ using Flutter
