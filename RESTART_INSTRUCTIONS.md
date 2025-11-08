# Flutter App Restart Instructions

## ✅ Backend API Integration Complete

The following files have been updated to use backend authentication:
- `lib/app/app_state.dart` - Login/Register/Logout now call backend API
- `lib/core/constants/api_constants.dart` - Backend URL configured

## 🔄 CRITICAL: You MUST Restart the App

Hot reload (r) or hot restart (R) will NOT work for authentication changes.

### Steps to Test:

1. **Ensure Backend is Running:**
   ```powershell
   cd c:\Users\adich\OneDrive\Documents\projects\Final\rentaly\backend
   npm start
   ```
   You should see: `✅ Server running at http://localhost:4000`

2. **Stop the Flutter App Completely:**
   - Press `q` to quit
   - OR close the browser/emulator

3. **Clean and Rebuild:**
   ```powershell
   cd c:\Users\adich\OneDrive\Documents\projects\Final\rentaly\rentally
   flutter clean
   flutter pub get
   flutter run -d chrome  # or your preferred device
   ```

4. **Test Login:**
   - Email: `user@test.com`
   - Password: `user123`

5. **Verify Backend is Being Called:**
   - Open browser DevTools (F12) → Network tab
   - Look for request to `http://localhost:4000/api/user/login`
   - Check backend terminal for log: `Login function called`

## ✅ Test Confirmation

Run this test to verify backend works:
```powershell
cd c:\Users\adich\OneDrive\Documents\projects\Final\rentaly
dart run test_backend_connection.dart
```

Should output: `✅ SUCCESS! Backend is working correctly`

## 🐛 If Still Not Working:

1. Check backend logs - you should see `Login function called`
2. Check browser console for network errors
3. Try incognito/private browsing mode
4. Clear browser cache
5. Make sure you're not on a cached version

## 📱 For Mobile/Desktop:

Same steps, just use the appropriate device:
```powershell
flutter run -d windows
flutter run -d android
flutter run -d ios
```
