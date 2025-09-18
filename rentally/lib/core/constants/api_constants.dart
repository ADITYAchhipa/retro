/// API Configuration Constants
/// 
/// ========================================
/// 🔧 BACKEND CONNECTION SETUP GUIDE
/// ========================================
/// 
/// TO CONNECT TO YOUR REAL BACKEND:
/// 1. Replace 'https://your-backend-api.com' with your actual backend URL
/// 2. Set useDummyData = false to use real API calls
/// 3. Add your API key if your backend requires authentication
/// 4. Ensure your backend endpoints match the ones defined below
/// 
/// EXAMPLE SETUP:
/// - baseUrl: 'https://api.myrentapp.com/api/v1'
/// - authBaseUrl: 'https://api.myrentapp.com/auth'
/// - useDummyData: false
/// - apiKey: 'your-actual-api-key-from-backend'
/// 
class ApiConstants {
  // ========================================
  // 🌐 BACKEND URLs - CHANGE THESE TO YOUR ACTUAL BACKEND
  // ========================================
  static const String baseUrl = 'https://your-backend-api.com/api/v1';
  static const String authBaseUrl = 'https://your-backend-api.com/auth';
  
  // ========================================
  // 🔄 DATA SOURCE - NOW USES REAL BACKEND ONLY
  // ========================================
  // Dummy database has been removed - app now uses real backend API only
  static const bool useDummyData = false; // Always false - dummy database removed
  
  // ========================================
  // 🛠️ API ENDPOINTS - YOUR BACKEND MUST IMPLEMENT THESE
  // ========================================
  
  // Authentication endpoints - implement these in your backend
  static const String loginEndpoint = '/login';           // POST: email, password
  static const String registerEndpoint = '/register';     // POST: user data
  static const String refreshTokenEndpoint = '/refresh';  // POST: refresh token
  static const String logoutEndpoint = '/logout';         // POST: logout user
  
  // Property endpoints - implement these in your backend
  static const String propertiesEndpoint = '/properties';                    // GET: ?page=1&limit=10
  static const String featuredPropertiesEndpoint = '/properties/featured';   // GET: featured properties
  static const String searchPropertiesEndpoint = '/properties/search';       // GET: ?query=...&location=...
  static const String propertyDetailsEndpoint = '/properties';               // GET: /properties/{id}
  
  // Booking endpoints - implement these in your backend
  static const String bookingsEndpoint = '/bookings';                        // GET: all bookings
  static const String userBookingsEndpoint = '/bookings/user';               // GET: /bookings/user/{userId}
  static const String ownerBookingsEndpoint = '/bookings/owner';             // GET: /bookings/owner/{ownerId}
  static const String createBookingEndpoint = '/bookings';                   // POST: create new booking
  
  // User endpoints - implement these in your backend
  static const String userProfileEndpoint = '/users/profile';                // GET: user profile
  static const String updateProfileEndpoint = '/users/profile';              // PUT: update profile
  
  // ========================================
  // ⏱️ NETWORK SETTINGS - ADJUST AS NEEDED
  // ========================================
  static const int connectionTimeout = 30000; // 30 seconds - increase if backend is slow
  static const int receiveTimeout = 30000; // 30 seconds - increase if backend is slow
  
  // ========================================
  // 📋 HTTP HEADERS - MODIFY IF YOUR BACKEND REQUIRES DIFFERENT HEADERS
  // ========================================
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add custom headers here if your backend requires them
    // 'X-Client-Version': '1.0.0',
    // 'X-Platform': 'mobile',
  };
  
  // ========================================
  // 🔑 API AUTHENTICATION - ADD YOUR API KEY HERE
  // ========================================
  // If your backend requires an API key, replace 'your-api-key-here' with actual key
  // Leave empty string if no API key needed
  static const String apiKey = 'your-api-key-here'; // 🔥 REPLACE WITH REAL API KEY
  
  // Error messages
  static const String networkErrorMessage = 'Network connection failed';
  static const String serverErrorMessage = 'Server error occurred';
  static const String timeoutErrorMessage = 'Request timeout';
  static const String unauthorizedErrorMessage = 'Unauthorized access';
}
