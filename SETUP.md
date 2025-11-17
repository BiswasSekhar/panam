# Setup Guide

## Prerequisites

- Go 1.21 or higher
- Node.js 18+ and npm
- Expo CLI (`npm install -g expo-cli`)
- iOS Simulator (Mac) or Android Studio (for mobile development)

## Backend Setup

1. Navigate to Backend directory:
```bash
cd Backend
```

2. Install Go dependencies:
```bash
go mod download
```

3. Run the server:
```bash
go run main.go
```

The server will start on `http://localhost:8080`

## Frontend Setup

1. Navigate to Frontend directory:
```bash
cd Frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the Expo development server:
```bash
npm start
```

4. Run on your preferred platform:
   - Press `i` for iOS simulator
   - Press `a` for Android emulator
   - Scan QR code with Expo Go app on your phone

## Configuration

### Backend
- Database: SQLite (auto-created as `panam.db`)
- Port: 8080
- JWT Secret: Change in `Backend/api/auth.go` for production

### Frontend
- API URL: Update in `Frontend/src/api/api.ts` if backend is not on localhost
- For physical device testing, replace `localhost` with your computer's IP address

## TypeScript

The frontend is fully typed with TypeScript. Type definitions are in:
- `Frontend/src/types/index.ts` - Core data models
- Component props are typed inline

## Development Tips

1. **Hot Reload**: Both backend (with `air` tool) and frontend support hot reload
2. **API Testing**: Use Postman or curl to test backend endpoints
3. **Type Safety**: Run `npx tsc --noEmit` to check TypeScript errors
4. **Database Reset**: Delete `panam.db` to reset the database

## Troubleshooting

**Backend won't start:**
- Check if port 8080 is available
- Verify Go version: `go version`

**Frontend connection issues:**
- Update API_URL in `api.ts` to your machine's IP
- Check if backend is running
- Disable firewall for local development

**TypeScript errors:**
- Run `npm install` to ensure all type definitions are installed
- Check `tsconfig.json` configuration
