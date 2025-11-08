import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify featured endpoints are working
/// Run with: dart run test_featured_endpoints.dart
void main() async {
  const baseUrl = 'http://localhost:3000/api';
  
  print('═══════════════════════════════════════════════════════════');
  print('Testing Featured Endpoints');
  print('═══════════════════════════════════════════════════════════\n');
  
  // Test 1: Featured Properties
  await testEndpoint(
    name: 'Featured Properties',
    url: '$baseUrl/property/featured',
    expectedField: 'results',
  );
  
  print('\n');
  
  // Test 2: Featured Vehicles
  await testEndpoint(
    name: 'Featured Vehicles',
    url: '$baseUrl/vehicle/featured',
    expectedField: 'results',
  );
  
  print('\n');
  
  // Test 3: Featured API (Properties)
  await testEndpoint(
    name: 'Featured API - Properties',
    url: '$baseUrl/featured/properties',
    expectedField: 'data',
  );
  
  print('\n');
  
  // Test 4: Featured API (Vehicles)
  await testEndpoint(
    name: 'Featured API - Vehicles',
    url: '$baseUrl/featured/vehicles',
    expectedField: 'data',
  );
  
  print('\n═══════════════════════════════════════════════════════════');
  print('Test Complete');
  print('═══════════════════════════════════════════════════════════');
}

Future<void> testEndpoint({
  required String name,
  required String url,
  required String expectedField,
}) async {
  print('Testing: $name');
  print('URL: $url');
  
  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 5),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final items = data[expectedField];
        final count = items is List ? items.length : items['total'] ?? 0;
        print('✅ SUCCESS - Found $count items');
        
        if (items is List && items.isNotEmpty) {
          final first = items.first;
          print('   Sample item: ${first['title'] ?? first['Title'] ?? 'No title'}');
        }
      } else {
        print('❌ FAILED - success: false in response');
        print('   Message: ${data['message']}');
      }
    } else {
      print('❌ FAILED - Status ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ ERROR - $e');
    print('   Make sure backend is running: cd backend && node server.js');
  }
}
