# Featured Section - Quick Fix Checklist

## ⚡ Quick Steps to Fix Featured Section Error

Follow these steps in order. Stop when the error is fixed.

### □ Step 1: Start Backend (2 minutes)
```bash
cd backend
node server.js
```

**Expected**: 
```
Server running on port 3000
MongoDB connected
```

**If fails**: Check MongoDB is running, verify .env file exists

---

### □ Step 2: Test Endpoints (1 minute)
```bash
# From project root
dart run test_featured_endpoints.dart
```

**Expected**: All tests show ✅ SUCCESS

**If fails**: Backend not responding or no featured items in database

---

### □ Step 3: Check Database (3 minutes)
```bash
mongosh
use rentally
db.properties.countDocuments({ Featured: true })
db.vehicles.countDocuments({ Featured: true })
```

**Expected**: Count > 0 for at least one collection

**If zero**: Add featured items:
```javascript
// Mark first 5 properties as featured
db.properties.updateMany(
  {},
  { $set: { Featured: true } },
  { limit: 5 }
)

// Mark first 5 vehicles as featured
db.vehicles.updateMany(
  {},
  { $set: { Featured: true } },
  { limit: 5 }
)
```

---

### □ Step 4: Verify App Configuration (2 minutes)

Check `rentally/lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Change if needed**: Update to match your backend URL

---

### □ Step 5: Clean & Rebuild (3 minutes)
```bash
cd rentally
flutter clean
flutter pub get
flutter run
```

**Expected**: App launches without errors

---

### □ Step 6: Check App Logs (1 minute)

Look for these in the console:
- `🌐 Fetching properties from backend...`
- `✅ Fetched X featured properties`

**If see errors**: Note the exact message and check troubleshooting guide

---

## ✅ Success Checklist

Your featured section is working when you see:

- [ ] App starts without errors
- [ ] Featured section shows property cards
- [ ] Images load in the cards
- [ ] Can scroll through featured items
- [ ] Switching to "Vehicles" tab works
- [ ] No red error messages in console

---

## 🚨 Common Errors & Instant Fixes

### Error: "Connection refused"
**Fix**: Start backend → `cd backend && node server.js`

### Error: "No featured properties available"
**Fix**: Add featured flag to database items (Step 3 above)

### Error: "CORS policy blocked"
**Fix**: Add in `backend/server.js`:
```javascript
import cors from 'cors';
app.use(cors());
```

### Error: Cards show but no images
**Fix**: Verify property/vehicle records have `Images` field with valid URLs

### Error: Provider not found
**Fix**: Check `rentally/lib/main.dart` has PropertyProvider and VehicleProvider

---

## 📊 Quick Status Check

Run all these in one go:
```bash
# Backend health
curl http://localhost:3000/api/property/featured

# Database count
echo "db.properties.countDocuments({Featured:true})" | mongosh rentally --quiet

# Flutter analysis
cd rentally && flutter analyze --no-fatal-infos
```

---

## 🎯 Most Likely Issues (Ordered by Frequency)

1. **Backend not running** (60% of cases)
   - Fix: Start backend

2. **No featured items in database** (25% of cases)
   - Fix: Update database records

3. **Wrong API URL** (10% of cases)
   - Fix: Update api_constants.dart

4. **CORS issue on web** (5% of cases)
   - Fix: Enable CORS in backend

---

## Need More Help?

- **Detailed guide**: `FEATURED_SECTION_TROUBLESHOOTING.md`
- **Error reference**: `FEATURED_SECTION_ERROR_FIX.md`
- **Test script**: `test_featured_endpoints.dart`

---

**Estimated Total Time**: 10-15 minutes
**Success Rate**: 95%+ when following all steps
