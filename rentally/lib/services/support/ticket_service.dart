import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum TicketStatus { open, pending, resolved, closed }

class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bookingId;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bookingId,
  });

  SupportTicket copyWith({
    String? subject,
    String? description,
    TicketStatus? status,
    DateTime? updatedAt,
  }) => SupportTicket(
        id: id,
        subject: subject ?? this.subject,
        description: description ?? this.description,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        bookingId: bookingId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'description': description,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'bookingId': bookingId,
      };

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        subject: json['subject'] as String,
        description: json['description'] as String,
        status: TicketStatus.values.firstWhere((e) => e.name == json['status']),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        bookingId: json['bookingId'] as String?,
      );
}

class TicketService {
  TicketService._();
  static final TicketService instance = TicketService._();

  static const _storeKey = 'support_tickets_v1';

  Future<List<SupportTicket>> getTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null || raw.isEmpty) return const [];
    final List data = jsonDecode(raw) as List;
    return data.map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _save(List<SupportTicket> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(tickets.map((t) => t.toJson()).toList()));
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    String? bookingId,
  }) async {
    final list = await getTickets();
    final now = DateTime.now();
    final t = SupportTicket(
      id: 'tkt_${now.millisecondsSinceEpoch}',
      subject: subject,
      description: description,
      status: TicketStatus.open,
      createdAt: now,
      updatedAt: now,
      bookingId: bookingId,
    );
    await _save([t, ...list]);
    return t;
  }

  Future<void> updateStatus(String ticketId, TicketStatus status) async {
    final list = await getTickets();
    final updated = list
        .map((t) => t.id == ticketId ? t.copyWith(status: status, updatedAt: DateTime.now()) : t)
        .toList();
    await _save(updated);
  }

  Future<void> deleteTicket(String ticketId) async {
    final list = await getTickets();
    await _save(list.where((t) => t.id != ticketId).toList());
  }
}
