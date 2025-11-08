import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Signup/Registration Backend Connection...\n');
  
  try {
    // Test backend registration endpoint
    final url = Uri.parse('http://localhost:4000/api/user/register');
    print('📍 Calling: $url');
    
    // Generate unique test email to avoid "user exists" error
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'testuser$timestamp@test.com';
    
    final requestBody = {
      'name': 'Test User',
      'email': testEmail,
      'password': 'test123',
      'phone': '1234567890',
    };
    
    print('📤 Request Body:');
    print(jsonEncode(requestBody));
    print('');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    print('📥 Response Status: ${response.statusCode}');
    print('📥 Response Body: ${response.body}');
    print('');
    
    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      print('✅ SUCCESS! Registration endpoint is working correctly!');
      print('👤 User Created:');
      print('   - Email: ${data['user']['email']}');
      print('   - Name: ${data['user']['name']}');
      print('🔑 Token Generated: ${data['token'] != null ? "Yes" : "No"}');
      print('');
      print('✨ Flutter signup page will work perfectly!');
    } else {
      print('❌ FAILED! ${data['message']}');
      if (data['message']?.toString().contains('exists') == true) {
        print('💡 This might be because the user already exists.');
        print('   Try with a different email or delete the user from DB.');
      }
    }
  } catch (e) {
    print('❌ ERROR: $e');
    print('');
    print('⚠️  Make sure:');
    print('   1. Backend is running on http://localhost:4000');
    print('   2. MongoDB is connected');
    print('   3. Run: cd backend && npm start');
  }
}
