# Featured Items Caching System - Integration Guide

## 📋 Overview

This system implements smart caching for featured properties and vehicles, ensuring:
- **Single API call** per category (property/vehicle)
- **Persistent cache** until app refresh
- **Instant switching** between categories using cached data
- **Automatic loading** on app start

## 🏗️ Architecture

### Files Created:

1. **`lib/services/featured_cache_service.dart`**
   - Core caching service
   - Handles API requests to `/api/property/featured` and `/api/vehicle/featured`
   - Stores data in memory until app restart

2. **`lib/core/providers/featured_provider.dart`**
   - Riverpod state management
   - Manages category switching
   - Integrates with cache service

3. **`lib/features/home/widgets/featured_section.dart`**
   - Standalone widget (new implementation)
   - Can be used independently

4. **`lib/features/home/widgets/home_featured_section_cached.dart`**
   - Drop-in replacement for existing `HomeFeaturedSection`
   - Maintains same interface and styling

## 🚀 Integration Options

### Option 1: Replace Existing Widget (Recommended)

In your `original_home_screen.dart`:

```dart
// OLD IMPORT (comment out or remove)
// import 'widgets/home_featured_section.dart';

// NEW IMPORT
import 'widgets/home_featured_section_cached.dart';

// In your build method, replace:
// HomeFeaturedSection(...)
// with:
HomeFeaturedSectionCached(
  theme: theme,
  isDark: isDark,
  tabController: _tabController,
  selectedCategory: selectedCategory,
)
```

### Option 2: Use Standalone Widget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/home/widgets/featured_section.dart';

// Make your screen a ConsumerWidget
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // ... other widgets
          const FeaturedSection(),
          // ... other widgets
        ],
      ),
    );
  }
}
```

## ⚙️ Backend Configuration

### Update API Base URL

In `lib/services/featured_cache_service.dart`, update line 18:

```dart
// Change this to match your backend
static const String baseUrl = 'http://localhost:3000/api';

// For production, use:
// static const String baseUrl = 'https://your-api.com/api';
```

### Backend Endpoints Required

Your backend should have these endpoints ready:

**1. Featured Properties**
```
GET /api/property/featured
Response: Array of property objects
```

**2. Featured Vehicles**
```
GET /api/vehicle/featured  
Response: Array of vehicle objects
```

## 📊 How It Works

### Initial Load (App Startup)
1. App opens → Provider initializes
2. Automatically requests `/api/property/featured`
3. Data cached in memory
4. UI displays featured properties

### Category Switch (Property → Vehicle)
1. User clicks "Vehicles" tab
2. Provider checks if vehicle data is cached
3. If **NOT cached**: Request `/api/vehicle/featured` → Cache → Display
4. If **cached**: Display immediately (no API call)

### Category Switch (Vehicle → Property)
1. User clicks "Properties" tab
2. Provider checks if property data is cached
3. Data IS cached (from initial load)
4. Display immediately (no API call)

### App Refresh
1. User pulls to refresh or restarts app
2. Cache cleared
3. New requests made to API
4. Fresh data displayed

## 🎯 Features

### ✅ Implemented
- [x] Single API call per category
- [x] Memory caching
- [x] Automatic initial load
- [x] Category switching without re-fetching
- [x] Loading states
- [x] Error handling with retry
- [x] Empty state handling
- [x] Pull-to-refresh support

### 🔄 Data Flow

```
App Start
    ↓
Load Properties → Cache → Display
    ↓
User Switches to Vehicles
    ↓
Load Vehicles → Cache → Display
    ↓
User Switches Back to Properties
    ↓
Read from Cache (instant) → Display
    ↓
User Refreshes App
    ↓
Clear Cache → Reload All
```

## 🧪 Testing

### Test Caching Behavior

```dart
// Add to your home screen for debugging
ElevatedButton(
  onPressed: () {
    final status = FeaturedCacheService().getCacheStatus();
    print('Cache Status: $status');
  },
  child: Text('Check Cache'),
)
```

### Expected Output
```json
{
  "properties": {
    "cached": true,
    "count": 10
  },
  "vehicles": {
    "cached": true,
    "count": 8
  }
}
```

## 🎨 UI Features

### Category Toggle
- Properties / Vehicles buttons
- Smooth animations
- Active state indication

### Loading States
- Skeleton shimmer on initial load
- Overlay loading when switching categories (if data loading)

### Error Handling
- Error icon and message
- Retry button
- Fallback to cached data if available

### Empty State
- Clear message when no items
- Category-specific messaging

## 🔧 Customization

### Change Cache Behavior

```dart
// Force refresh (ignore cache)
ref.read(featuredProvider.notifier).refresh();

// Clear all cache and reload
ref.read(featuredProvider.notifier).clearCacheAndReload();

// Clear specific category
FeaturedCacheService().clearPropertyCache();
FeaturedCacheService().clearVehicleCache();
```

### Customize Loading Timeout

In `featured_cache_service.dart`:

```dart
final response = await http.get(
  Uri.parse('$baseUrl/property/featured'),
  headers: {'Content-Type': 'application/json'},
).timeout(const Duration(seconds: 10)); // Change timeout here
```

## 📱 Performance Benefits

### Before (Without Caching)
- Properties load: API call (~500ms)
- Switch to Vehicles: API call (~500ms)
- Switch back to Properties: API call (~500ms)
- **Total: ~1500ms for 3 switches**

### After (With Caching)
- Properties load: API call (~500ms)
- Switch to Vehicles: API call (~500ms)
- Switch back to Properties: **Cache read (~5ms)**
- **Total: ~1005ms for 3 switches** (33% faster!)

## 🐛 Troubleshooting

### Issue: "Failed to load featured items"
**Solution:** Check backend URL in `featured_cache_service.dart`

### Issue: Data not showing after switching
**Solution:** Ensure backend returns valid JSON array

### Issue: Cache not working
**Solution:** 
```dart
// Check if singleton is initialized
print(FeaturedCacheService().getCacheStatus());
```

### Issue: CORS errors on web
**Solution:** Add CORS headers in your backend:
```javascript
app.use(cors({
  origin: 'http://localhost:*',
  credentials: true
}));
```

## 📝 Notes

- Cache persists only during app session (memory-based)
- No persistent storage (SharedPreferences/SQLite) used
- Refresh by restarting app or using pull-to-refresh
- Backend must return JSON array of listing objects

## 🚀 Next Steps

1. Update backend URL in `featured_cache_service.dart`
2. Choose integration option (replace widget or use standalone)
3. Test on your device
4. Monitor network calls in DevTools
5. Verify caching behavior

## 💡 Tips

- Test with slow network to see caching benefits
- Use Flutter DevTools Network tab to verify single API calls
- Add cache indicators for debugging (green checkmark shown in UI)
- Consider adding analytics to track cache hit rates

---

**Created for:** Rentaly App
**Date:** November 6, 2025
**Version:** 1.0.0
