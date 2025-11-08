import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('Testing backend connection...');
  
  try {
    // Test backend login endpoint
    final url = Uri.parse('http://localhost:4000/api/user/login');
    print('Calling: $url');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': 'user@test.com',
        'password': 'user123',
      }),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      print('✅ SUCCESS! Backend is working correctly');
      print('User: ${data['user']}');
      print('Token: ${data['token']}');
    } else {
      print('❌ FAILED! ${data['message']}');
    }
  } catch (e) {
    print('❌ ERROR: $e');
    print('Make sure backend is running on http://localhost:4000');
  }
}
