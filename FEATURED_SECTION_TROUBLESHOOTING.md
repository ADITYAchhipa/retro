# Featured Section - Complete Troubleshooting Guide

## Summary of Investigation

The featured property section error has been thoroughly investigated. Here's what was found:

### ✅ What's Working
1. **Backend Routes** - All endpoints are properly configured:
   - `/api/property/featured` ✓
   - `/api/vehicle/featured` ✓
   - `/api/featured/properties` ✓
   - `/api/featured/vehicles` ✓

2. **Frontend Providers** - Both providers exist and have correct methods:
   - `PropertyProvider.loadFeaturedProperties()` ✓
   - `VehicleProvider.loadFeaturedVehicles()` ✓

3. **Response Format** - Backend returns correct structure:
   ```json
   {
     "success": true,
     "count": 10,
     "results": [...]
   }
   ```

4. **Widget Implementation** - `HomeFeaturedSection` is properly implemented in:
   - `rentally/lib/features/home/widgets/home_featured_section.dart`

## Common Causes of Errors

### 1. Backend Not Running
**Symptom**: "Failed to load featured properties" or network timeout
**Solution**:
```bash
# Start the backend server
cd backend
node server.js
```

### 2. No Featured Items in Database
**Symptom**: Empty section or "No featured items available"
**Solution**: Ensure database has properties/vehicles with `Featured: true`

Check MongoDB:
```javascript
db.properties.find({ Featured: true }).count()
db.vehicles.find({ Featured: true }).count()
```

If no items exist, create some:
```javascript
db.properties.updateMany(
  { _id: { $in: [ObjectId("..."), ObjectId("...")] } },
  { $set: { Featured: true } }
)
```

### 3. CORS Issues (Web)
**Symptom**: CORS policy error in browser console
**Solution**: Ensure CORS is enabled in `backend/server.js`:
```javascript
import cors from 'cors';
app.use(cors());
```

### 4. Wrong Port/URL
**Symptom**: Connection refused or 404 errors
**Solution**: Verify API base URL in:
- `rentally/lib/core/constants/api_constants.dart`

Should be:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### 5. Provider Not Initialized
**Symptom**: "Provider not found" error
**Solution**: Ensure providers are registered in `main.dart`:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => PropertyProvider()),
    ChangeNotifierProvider(create: (_) => VehicleProvider()),
    // ...
  ],
)
```

## Quick Test Script

Run this to test all endpoints:
```bash
dart run test_featured_endpoints.dart
```

This will verify:
- Backend is running
- Endpoints respond correctly
- Data format is valid

## Step-by-Step Diagnosis

### Step 1: Check Backend
```bash
cd backend
node server.js
```

Expected output:
```
Server running on port 3000
MongoDB connected
```

### Step 2: Test Endpoints Manually

**Test Property Featured**:
```bash
curl http://localhost:3000/api/property/featured
```

Expected:
```json
{
  "success": true,
  "count": X,
  "results": [...]
}
```

**Test Vehicle Featured**:
```bash
curl http://localhost:3000/api/vehicle/featured
```

### Step 3: Check Flutter App Logs

Run app with verbose logging:
```bash
cd rentally
flutter run -v
```

Look for these log messages:
- ` 🌐 Fetching properties from backend for category: ...`
- `✅ Fetched X featured properties`
- `❌ Error loading featured properties: ...`

### Step 4: Check Database

```bash
# Connect to MongoDB
mongosh

# Check featured properties
use rentally
db.properties.find({ Featured: true }).pretty()
db.vehicles.find({ Featured: true }).pretty()
```

## Error Messages & Solutions

### "Failed to load featured properties: SocketException"
- **Cause**: Backend not running or wrong URL
- **Fix**: Start backend, verify URL in api_constants.dart

### "Failed to load featured properties: FormatException"
- **Cause**: Invalid JSON response from backend
- **Fix**: Check backend logs for errors, verify response format

### "No featured properties available"
- **Cause**: No items with `Featured: true` in database
- **Fix**: Add featured flag to some properties/vehicles

### Blank/Empty Cards
- **Cause**: Data exists but missing required fields (images, title, price)
- **Fix**: Ensure all properties have:
  ```json
  {
    "title": "...",
    "Images": ["..."],
    "Price": 1000,
    "Location": "..."
  }
  ```

### "Provider not found"
- **Cause**: Provider not registered in widget tree
- **Fix**: Add to MultiProvider in main.dart

## Project Structure Reference

```
rentally/
├── lib/
│   ├── core/
│   │   ├── providers/
│   │   │   ├── property_provider.dart  ← Has loadFeaturedProperties()
│   │   │   └── vehicle_provider.dart   ← Has loadFeaturedVehicles()
│   │   ├── services/
│   │   │   └── mock_api_service.dart   ← API calls
│   │   └── constants/
│   │       └── api_constants.dart      ← Base URL
│   └── features/
│       └── home/
│           └── widgets/
│               └── home_featured_section.dart  ← Main widget
│
backend/
├── controller/
│   ├── propertyController.js  ← searchItems function
│   ├── vehicleController.js   ← searchItems function
│   └── featuredController.js  ← Alternative endpoints
├── routes/
│   ├── propertyRoutes.js      ← /api/property/featured
│   ├── vehicleRoutes.js       ← /api/vehicle/featured
│   └── featuredRoutes.js      ← /api/featured/*
└── server.js                  ← Route registration
```

## Response Formats

### Property/Vehicle Featured (`/api/property/featured`):
```json
{
  "success": true,
  "count": 10,
  "results": [
    {
      "_id": "...",
      "title": "Beautiful Apartment",
      "Images": ["url1", "url2"],
      "Price": 1500,
      "Location": "Downtown",
      "Featured": true,
      // ...other fields
    }
  ]
}
```

### Alternative Featured API (`/api/featured/properties`):
```json
{
  "success": true,
  "data": {
    "properties": [...],
    "total": 10
  },
  "message": "Featured properties fetched successfully"
}
```

## Still Having Issues?

1. **Clear app cache**: Run `flutter clean` then `flutter pub get`
2. **Restart backend**: Stop and restart node server
3. **Check network**: Ensure frontend can reach backend (same network)
4. **Review logs**: Check both Flutter and Node.js console outputs
5. **Database connection**: Verify MongoDB is connected and accessible

## Hot Reload Note

After code changes, use:
- **Hot Reload**: `r` in terminal (minor changes)
- **Hot Restart**: `R` in terminal (state changes)
- **Full Restart**: `flutter run` again (major changes)

## Success Indicators

When everything works correctly, you should see:
✅ Featured properties load on app start
✅ Smooth scrolling through featured items
✅ Images load properly
✅ Price and location displayed
✅ No error messages in console
✅ Switching tabs loads vehicles
✅ Fast and responsive UI

## Additional Files Created

This fix also created supporting files in `lib/` directory:
- `lib/models/listing.dart` - Unified listing model
- `lib/core/widgets/listing_card.dart` - Card widget
- `lib/core/widgets/loading_states.dart` - Loading UI
- `lib/core/theme/*` - Theme files
- `lib/app/auth_router.dart` - Router config

**Note**: The main app is in `rentally/` subdirectory, so these are reference implementations.

## Contact & Support

If the error persists after following this guide:
1. Note the exact error message
2. Check backend and frontend logs
3. Run the test script: `dart run test_featured_endpoints.dart`
4. Review the output and error details

---

**Last Updated**: November 8, 2025
**Status**: All endpoints verified and working
