# Quick Start Guide

## Prerequisites Check

Before starting, ensure you have:
- ✅ Go 1.21+ installed: `go version`
- ✅ Node.js 18+ installed: `node --version`
- ✅ npm installed: `npm --version`

## Start Backend (Terminal 1)

```bash
cd panam
./start-backend.sh
```

You should see:
```
🚀 Starting Panam Backend...
Server starting on :8080
```

## Start Frontend (Terminal 2)

```bash
cd panam
./start-frontend.sh
```

You should see the Expo dev server with a QR code.

## Run the App

### Option 1: iOS Simulator (Mac only)
Press `i` in the Expo terminal

### Option 2: Android Emulator
Press `a` in the Expo terminal

### Option 3: Physical Device
1. Install "Expo Go" app from App Store/Play Store
2. Scan the QR code shown in terminal
3. **Important**: Update API URL in `Frontend/src/api/api.ts`:
   ```typescript
   const API_URL = 'http://YOUR_COMPUTER_IP:8080/api';
   ```
   Replace `YOUR_COMPUTER_IP` with your machine's local IP (find with `ifconfig` on Mac/Linux or `ipconfig` on Windows)

## Test the App

1. **Register**: Create a new account
2. **Add Transaction**: Click "+ Add Transaction" on home screen
3. **View Dashboard**: See your balance and stats
4. **Scan PDF**: Try the PDF scanner (demo mode)

## Troubleshooting

### Backend Issues

**Port already in use:**
```bash
lsof -ti:8080 | xargs kill -9
```

**Database issues:**
```bash
rm panam/Backend/panam.db
```

### Frontend Issues

**Dependencies not installed:**
```bash
cd panam/Frontend
rm -rf node_modules package-lock.json
npm install
```

**Expo cache issues:**
```bash
cd panam/Frontend
npx expo start -c
```

**Can't connect to backend:**
- Check backend is running on port 8080
- For physical device, use your computer's IP instead of localhost
- Disable firewall temporarily for testing

## Development Tips

### Backend Hot Reload
Install Air for hot reload:
```bash
go install github.com/cosmtrek/air@latest
cd panam/Backend
air
```

### Frontend Hot Reload
Expo automatically reloads on file changes. Press `r` to manually reload.

### View Logs
- Backend: Check terminal where backend is running
- Frontend: Press `j` in Expo terminal to open debugger

## Next Steps

- Read [FEATURES.md](FEATURES.md) for feature roadmap
- Check [SETUP.md](SETUP.md) for detailed configuration
- Explore the TypeScript types in `Frontend/src/types/index.ts`
