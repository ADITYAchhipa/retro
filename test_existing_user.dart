import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing "User Already Exists" Notification Feature\n');
  
  // First, register a new user
  final testEmail = 'existing.user@test.com';
  
  print('📝 Step 1: Creating a test user...');
  await registerUser(testEmail, 'Test User', 'password123', '1234567890');
  
  print('\n📝 Step 2: Trying to register the SAME user again...');
  await registerUser(testEmail, 'Test User', 'password123', '1234567890');
  
  print('\n✅ Test Complete!');
  print('\n📋 Expected Behavior in Flutter App:');
  print('   1. Toast notification: "Account Already Exists!"');
  print('   2. Dialog appears with login option');
  print('   3. User can click "Go to Login" button');
  print('   4. Navigates to login screen');
}

Future<void> registerUser(String email, String name, String password, String phone) async {
  try {
    final url = Uri.parse('http://localhost:4000/api/user/register');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      }),
    );

    final data = jsonDecode(response.body);
    
    if (data['success'] == true) {
      print('   ✅ User created successfully: $email');
    } else {
      if (data['message'] == 'User exists') {
        print('   ⚠️  USER ALREADY EXISTS! (This triggers the toast notification)');
        print('   📧 Email: $email');
        print('   💬 Backend Message: "${data['message']}"');
        print('   ');
        print('   🎯 In Flutter App, this will:');
        print('      - Show toast: "⚠️ Account Already Exists!"');
        print('      - Show dialog: "Would you like to login instead?"');
        print('      - Provide "Go to Login" button');
      } else {
        print('   ❌ Error: ${data['message']}');
      }
    }
  } catch (e) {
    print('   ❌ ERROR: $e');
  }
}
