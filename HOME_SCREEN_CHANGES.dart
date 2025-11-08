// ═══════════════════════════════════════════════════════════════════════════
// EXACT CHANGES NEEDED IN original_home_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────────────────
// STEP 1: UPDATE IMPORTS (at the top of the file)
// ──────────────────────────────────────────────────────────────────────────

// BEFORE (OLD - Line ~12):
// import 'widgets/home_featured_section.dart';

// AFTER (NEW):
import 'widgets/home_featured_section_cached.dart';


// ──────────────────────────────────────────────────────────────────────────
// STEP 2: UPDATE WIDGET USAGE (in the build method)
// ──────────────────────────────────────────────────────────────────────────

// BEFORE (OLD - somewhere around line 200-300):
// HomeFeaturedSection(
//   theme: theme,
//   isDark: isDark,
//   tabController: _tabController,
//   selectedCategory: _getCurrentCategory(),
// ),

// AFTER (NEW - exact same parameters!):
HomeFeaturedSectionCached(
  theme: theme,
  isDark: isDark,
  tabController: _tabController,
  selectedCategory: _getCurrentCategory(),
),

// That's it! No other changes needed!


// ═══════════════════════════════════════════════════════════════════════════
// ALTERNATIVE: If you want to use the standalone widget
// ═══════════════════════════════════════════════════════════════════════════

// OPTION A: Import the standalone widget
// import 'widgets/featured_section.dart';

// OPTION B: Use it without parameters (simpler)
// const FeaturedSection(),

// Note: This option has its own built-in category toggle and doesn't need
// the tabController parameter. It manages its own state.


// ═══════════════════════════════════════════════════════════════════════════
// BONUS: Add Pull-to-Refresh (Optional)
// ═══════════════════════════════════════════════════════════════════════════

// Wrap your ListView/SingleChildScrollView with RefreshIndicator:

RefreshIndicator(
  onRefresh: () async {
    // Clear cache and reload
    ref.read(featuredProvider.notifier).refresh();
  },
  child: ListView(
    children: [
      // Your existing widgets
      HomeFeaturedSectionCached(...),
      // Other sections
    ],
  ),
)


// ═══════════════════════════════════════════════════════════════════════════
// BONUS: Add Cache Debug Button (Optional - for testing)
// ═══════════════════════════════════════════════════════════════════════════

// Add this button temporarily to test caching:

import '../services/featured_cache_service.dart';

// In your build method, add:
FloatingActionButton(
  onPressed: () {
    final status = FeaturedCacheService().getCacheStatus();
    print('═══════════════════════════════════════');
    print('CACHE STATUS:');
    print('Properties Cached: ${status['properties']['cached']}');
    print('Properties Count: ${status['properties']['count']}');
    print('Vehicles Cached: ${status['vehicles']['cached']}');
    print('Vehicles Count: ${status['vehicles']['count']}');
    print('═══════════════════════════════════════');
    
    // Show in UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Properties: ${status['properties']['count']} cached | '
          'Vehicles: ${status['vehicles']['count']} cached'
        ),
      ),
    );
  },
  child: Icon(Icons.info),
);


// ═══════════════════════════════════════════════════════════════════════════
// COMPLETE EXAMPLE - Full build method with the changes
// ═══════════════════════════════════════════════════════════════════════════

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  return Scaffold(
    body: RefreshIndicator(
      onRefresh: () async {
        // Optional: Add refresh functionality
        // ref.read(featuredProvider.notifier).refresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(...),
          
          // Search Bar
          SliverToBoxAdapter(
            child: HomeSearchBar(...),
          ),
          
          // Tabs
          SliverToBoxAdapter(
            child: HomeTabSection(...),
          ),
          
          // Category Navigation
          SliverToBoxAdapter(
            child: HomeCategoryNavigation(...),
          ),
          
          // Featured Section (NEW - WITH CACHING!)
          SliverToBoxAdapter(
            child: HomeFeaturedSectionCached(
              theme: theme,
              isDark: isDark,
              tabController: _tabController,
              selectedCategory: _getCurrentCategory(),
            ),
          ),
          
          // Promo Banner
          SliverToBoxAdapter(
            child: HomePromoBanner(...),
          ),
          
          // Recommended Section
          SliverToBoxAdapter(
            child: HomeRecommendedSection(...),
          ),
          
          // Nearby Section
          SliverToBoxAdapter(
            child: HomeNearbySection(...),
          ),
        ],
      ),
    ),
  );
}


// ═══════════════════════════════════════════════════════════════════════════
// TESTING STEPS
// ═══════════════════════════════════════════════════════════════════════════

/*

1. Make the changes above (import + widget replacement)

2. Start your backend:
   cd backend
   node server.js
   
3. Run the Flutter app:
   flutter run -d chrome
   
4. Open Chrome DevTools:
   - Right-click → Inspect
   - Go to Network tab
   - Filter: "/api/"
   
5. Test sequence:
   a) App loads → Watch for: GET /api/property/featured ✓
   b) Click "Vehicles" tab → Watch for: GET /api/vehicle/featured ✓
   c) Click "Properties" tab → Watch for: NO NEW REQUEST ✓ (using cache!)
   d) Switch back and forth → Should be instant with no API calls!
   
6. Success indicators:
   ✅ Featured items load immediately on app start
   ✅ First switch to vehicles fetches data
   ✅ Switching back to properties is instant
   ✅ No repeated API calls for same category
   ✅ Green checkmark appears next to "Featured Properties"
   
7. Test error handling:
   a) Stop backend (Ctrl+C)
   b) Switch categories
   c) Should see error message with Retry button
   d) Start backend again
   e) Click Retry
   f) Data loads successfully

*/


// ═══════════════════════════════════════════════════════════════════════════
// COMMON ISSUES & SOLUTIONS
// ═══════════════════════════════════════════════════════════════════════════

/*

ISSUE: "Failed to load featured items"
└─ SOLUTION: Update backend URL in lib/services/featured_cache_service.dart
   Line 18: static const String baseUrl = 'http://localhost:3000/api';

ISSUE: CORS error when testing on web
└─ SOLUTION: Add CORS middleware in backend/server.js:
   
   const cors = require('cors');
   app.use(cors());

ISSUE: Data not showing after switching
└─ SOLUTION: Check backend returns valid JSON array:
   
   // Correct format:
   [
     { id: "1", title: "Property 1", ... },
     { id: "2", title: "Property 2", ... }
   ]

ISSUE: Cache not working
└─ SOLUTION: Check console logs:
   
   print(FeaturedCacheService().getCacheStatus());
   
   Should show cached: true after first load

*/


// ═══════════════════════════════════════════════════════════════════════════
// THAT'S ALL YOU NEED! 
// Just these 2 simple changes and you're done! 🎉
// ═══════════════════════════════════════════════════════════════════════════
