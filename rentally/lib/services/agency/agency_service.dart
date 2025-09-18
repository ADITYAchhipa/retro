import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AgencyMember {
  final String id;
  final String name;
  final String email;
  final String role; // owner|manager|staff

  const AgencyMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  AgencyMember copyWith({String? name, String? email, String? role}) => AgencyMember(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      };

  factory AgencyMember.fromJson(Map<String, dynamic> json) => AgencyMember(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );
}

class AgencyService {
  AgencyService._();
  static final AgencyService instance = AgencyService._();

  static const _key = 'agency_members_v1';

  Future<List<AgencyMember>> getMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final List data = jsonDecode(raw) as List;
    return data.map((e) => AgencyMember.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveMembers(List<AgencyMember> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(members.map((e) => e.toJson()).toList()));
  }

  Future<void> inviteMember({required String name, required String email, String role = 'staff'}) async {
    final members = await getMembers();
    final newMember = AgencyMember(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
    await _saveMembers([newMember, ...members]);
  }

  Future<void> removeMember(String id) async {
    final members = await getMembers();
    await _saveMembers(members.where((m) => m.id != id).toList());
  }

  Future<void> updateRole(String id, String role) async {
    final members = await getMembers();
    final updated = members.map((m) => m.id == id ? m.copyWith(role: role) : m).toList();
    await _saveMembers(updated);
  }
}
