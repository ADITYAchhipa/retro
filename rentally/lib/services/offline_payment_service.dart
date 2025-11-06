import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'rent_reminder_service.dart';

enum OfflinePaymentStatus { pending, approved, rejected }

// =====================
// In-person code models
// =====================
enum OfflineHandshakeStatus { active, used, cancelled }

class OfflinePaymentHandshake {
  final String id;
  final String listingId;
  final DateTime dueAt;
  final String ownerId;
  final String code; // 6-digit numeric as string
  final OfflineHandshakeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;

  const OfflinePaymentHandshake({
    required this.id,
    required this.listingId,
    required this.dueAt,
    required this.ownerId,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
  });

  OfflinePaymentHandshake copyWith({
    String? id,
    String? listingId,
    DateTime? dueAt,
    String? ownerId,
    String? code,
    OfflineHandshakeStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
  }) {
    return OfflinePaymentHandshake(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      dueAt: dueAt ?? this.dueAt,
      ownerId: ownerId ?? this.ownerId,
      code: code ?? this.code,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'ownerId': ownerId,
        'code': code,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'usedAt': usedAt?.millisecondsSinceEpoch,
      };

  static OfflinePaymentHandshake fromJson(Map<String, dynamic> json) => OfflinePaymentHandshake(
        id: (json['id'] ?? '').toString(),
        listingId: (json['listingId'] ?? '').toString(),
        dueAt: DateTime.fromMillisecondsSinceEpoch(json['dueAt'] as int),
        ownerId: (json['ownerId'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        status: OfflineHandshakeStatus.values.firstWhere(
          (e) => e.name == (json['status'] ?? 'active'),
          orElse: () => OfflineHandshakeStatus.active,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
        usedAt: json['usedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['usedAt'] as int) : null,
      );
}

class OfflinePaymentClaim {
  final String id;
  final String listingId;
  final DateTime dueAt; // the cycle due date this claim covers
  final double amount;
  final String currency;
  final String tenantId;
  final String ownerId;
  final String? note;
  final OfflinePaymentStatus status;
  final DateTime submittedAt;
  final DateTime? decidedAt;
  final String? rejectionReason;

  const OfflinePaymentClaim({
    required this.id,
    required this.listingId,
    required this.dueAt,
    required this.amount,
    required this.currency,
    required this.tenantId,
    required this.ownerId,
    this.note,
    this.status = OfflinePaymentStatus.pending,
    required this.submittedAt,
    this.decidedAt,
    this.rejectionReason,
  });

  OfflinePaymentClaim copyWith({
    String? id,
    String? listingId,
    DateTime? dueAt,
    double? amount,
    String? currency,
    String? tenantId,
    String? ownerId,
    String? note,
    OfflinePaymentStatus? status,
    DateTime? submittedAt,
    DateTime? decidedAt,
    String? rejectionReason,
  }) {
    return OfflinePaymentClaim(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      dueAt: dueAt ?? this.dueAt,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      tenantId: tenantId ?? this.tenantId,
      ownerId: ownerId ?? this.ownerId,
      note: note ?? this.note,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      decidedAt: decidedAt ?? this.decidedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'dueAt': dueAt.millisecondsSinceEpoch,
        'amount': amount,
        'currency': currency,
        'tenantId': tenantId,
        'ownerId': ownerId,
        'note': note,
        'status': status.name,
        'submittedAt': submittedAt.millisecondsSinceEpoch,
        'decidedAt': decidedAt?.millisecondsSinceEpoch,
        'rejectionReason': rejectionReason,
      };

  static OfflinePaymentClaim fromJson(Map<String, dynamic> json) => OfflinePaymentClaim(
        id: (json['id'] ?? '').toString(),
        listingId: (json['listingId'] ?? '').toString(),
        dueAt: DateTime.fromMillisecondsSinceEpoch(json['dueAt'] as int),
        amount: (json['amount'] as num).toDouble(),
        currency: (json['currency'] ?? 'USD').toString(),
        tenantId: (json['tenantId'] ?? '').toString(),
        ownerId: (json['ownerId'] ?? '').toString(),
        note: json['note'] as String?,
        status: OfflinePaymentStatus.values.firstWhere(
          (e) => e.name == (json['status'] ?? 'pending'),
          orElse: () => OfflinePaymentStatus.pending,
        ),
        submittedAt: DateTime.fromMillisecondsSinceEpoch(json['submittedAt'] as int),
        decidedAt: json['decidedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['decidedAt'] as int) : null,
        rejectionReason: json['rejectionReason'] as String?,
      );
}

class OfflinePaymentService {
  static const String _storageKey = 'offline_payment_claims_v1';
  static const String _handshakeStorageKey = 'offline_payment_handshakes_v1';

  static Future<List<OfflinePaymentClaim>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const <String>[];
    final List<OfflinePaymentClaim> out = [];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(OfflinePaymentClaim.fromJson(map));
      } catch (_) {}
    }
    // newest first
    out.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return out;
  }

  static Future<void> _saveAll(List<OfflinePaymentClaim> list) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, strings);
  }

  static Future<List<OfflinePaymentHandshake>> _loadAllHandshakes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_handshakeStorageKey) ?? const <String>[];
    final List<OfflinePaymentHandshake> out = [];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(OfflinePaymentHandshake.fromJson(map));
      } catch (_) {}
    }
    // newest first
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  static Future<void> _saveAllHandshakes(List<OfflinePaymentHandshake> list) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_handshakeStorageKey, strings);
  }

  static String _random6() {
    final r = Random();
    final n = 100000 + r.nextInt(900000);
    return n.toString();
  }

  /// Owner generates a 6-digit code. Expires after [ttlMinutes].
  static Future<OfflinePaymentHandshake> generateHandshake({
    required String listingId,
    required DateTime dueAt,
    required String ownerId,
    int ttlMinutes = 30,
  }) async {
    final all = await _loadAllHandshakes();
    String code;
    // Ensure code uniqueness among active handshakes
    while (true) {
      code = _random6();
      final exists = all.any((h) => h.code == code && h.status == OfflineHandshakeStatus.active);
      if (!exists) break;
    }
    final now = DateTime.now();
    final hs = OfflinePaymentHandshake(
      id: 'hs_${listingId}_${dueAt.millisecondsSinceEpoch}_$code',
      listingId: listingId,
      dueAt: dueAt,
      ownerId: ownerId,
      code: code,
      status: OfflineHandshakeStatus.active,
      createdAt: now,
      expiresAt: now.add(Duration(minutes: ttlMinutes)),
    );
    all.insert(0, hs);
    await _saveAllHandshakes(all);
    return hs;
  }

  /// Return active handshake for this listing and dueAt day, if any.
  static Future<OfflinePaymentHandshake?> getActiveHandshake(String listingId, DateTime dueAt) async {
    final all = await _loadAllHandshakes();
    for (final h in all) {
      if (h.listingId == listingId && _sameDay(h.dueAt, dueAt) && h.status == OfflineHandshakeStatus.active) {
        // Also ensure not expired
        if (DateTime.now().isBefore(h.expiresAt)) return h;
      }
    }
    return null;
  }

  static Future<void> cancelHandshake(String id) async {
    final all = await _loadAllHandshakes();
    for (int i = 0; i < all.length; i++) {
      if (all[i].id == id) {
        all[i] = all[i].copyWith(status: OfflineHandshakeStatus.cancelled);
        await _saveAllHandshakes(all);
        return;
      }
    }
  }

  /// Tenant enters owner-provided code. If valid and active, this will
  /// auto-approve the cycle: approves existing pending claim or creates
  /// an approved claim, then advances the rent reminder.
  static Future<OfflinePaymentClaim> validateAndConsumeCode({
    required String code,
    required String tenantId,
    required double amount,
    required String currency,
  }) async {
    final allHs = await _loadAllHandshakes();
    for (int i = 0; i < allHs.length; i++) {
      final h = allHs[i];
      if (h.code != code) continue;
      // Check validity
      final now = DateTime.now();
      if (h.status != OfflineHandshakeStatus.active) {
        throw StateError('Code has already been used or cancelled');
      }
      if (now.isAfter(h.expiresAt)) {
        throw StateError('Code has expired');
      }
      // Approve cycle: if a claim exists, approve; else create approved claim
      final existing = await getForListingAndDue(h.listingId, h.dueAt);
      OfflinePaymentClaim claim;
      if (existing != null) {
        if (existing.status == OfflinePaymentStatus.approved) {
          // Mark handshake used and return existing
          allHs[i] = h.copyWith(status: OfflineHandshakeStatus.used, usedAt: now);
          await _saveAllHandshakes(allHs);
          return existing;
        }
        // Approve existing pending/rejected claim
        final updated = OfflinePaymentClaim(
          id: existing.id,
          listingId: existing.listingId,
          dueAt: existing.dueAt,
          amount: existing.amount,
          currency: existing.currency,
          tenantId: existing.tenantId,
          ownerId: existing.ownerId,
          note: (existing.note == null || existing.note!.isEmpty)
              ? 'In-person code verified'
              : existing.note,
          status: OfflinePaymentStatus.approved,
          submittedAt: existing.submittedAt,
          decidedAt: now,
          rejectionReason: null,
        );
        final allClaims = await _loadAll();
        for (int j = 0; j < allClaims.length; j++) {
          if (allClaims[j].id == existing.id) {
            allClaims[j] = updated;
            break;
          }
        }
        await _saveAll(allClaims);
        claim = updated;
      } else {
        // Create an approved claim directly
        final id = 'claim_${h.listingId}_${h.dueAt.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
        final newClaim = OfflinePaymentClaim(
          id: id,
          listingId: h.listingId,
          dueAt: h.dueAt,
          amount: amount,
          currency: currency,
          tenantId: tenantId,
          ownerId: h.ownerId,
          note: 'In-person code verified',
          status: OfflinePaymentStatus.approved,
          submittedAt: now,
          decidedAt: now,
        );
        final allClaims = await _loadAll();
        allClaims.insert(0, newClaim);
        await _saveAll(allClaims);
        claim = newClaim;
      }

      // Advance reminder and mark handshake as used
      await RentReminderService.markDuePaid(h.listingId, dueAt: h.dueAt);
      allHs[i] = h.copyWith(status: OfflineHandshakeStatus.used, usedAt: now);
      await _saveAllHandshakes(allHs);
      return claim;
    }
    throw StateError('Invalid code');
  }

  static Future<List<OfflinePaymentClaim>> listForListing(String listingId) async {
    final all = await _loadAll();
    return all.where((c) => c.listingId == listingId).toList();
  }

  static Future<OfflinePaymentClaim?> getForListingAndDue(String listingId, DateTime dueAt) async {
    final all = await _loadAll();
    for (final c in all) {
      if (c.listingId == listingId && _sameDay(c.dueAt, dueAt)) {
        return c;
      }
    }
    return null;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static Future<OfflinePaymentClaim> submitClaim({
    required String listingId,
    required DateTime dueAt,
    required double amount,
    required String currency,
    required String tenantId,
    required String ownerId,
    String? note,
  }) async {
    final all = await _loadAll();
    final exists = all.any((c) => c.listingId == listingId && _sameDay(c.dueAt, dueAt) && c.status != OfflinePaymentStatus.rejected);
    if (exists) {
      throw StateError('A claim already exists for this due date.');
    }
    // Anti-fraud: if an in-person code is active for this cycle, force using the code
    final activeHs = await getActiveHandshake(listingId, dueAt);
    if (activeHs != null) {
      throw StateError('An in-person confirmation code is active for this cycle. Please use the code to confirm payment.');
    }
    final id = 'claim_${listingId}_${dueAt.millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}';
    final claim = OfflinePaymentClaim(
      id: id,
      listingId: listingId,
      dueAt: dueAt,
      amount: amount,
      currency: currency,
      tenantId: tenantId,
      ownerId: ownerId,
      note: note,
      status: OfflinePaymentStatus.pending,
      submittedAt: DateTime.now(),
    );
    all.insert(0, claim);
    await _saveAll(all);
    return claim;
  }

  static Future<OfflinePaymentClaim> approveClaim(String claimId) async {
    final all = await _loadAll();
    for (int i = 0; i < all.length; i++) {
      if (all[i].id == claimId) {
        final c = all[i].copyWith(
          status: OfflinePaymentStatus.approved,
          decidedAt: DateTime.now(),
          rejectionReason: null,
        );
        all[i] = c;
        await _saveAll(all);
        // Advance the reminder to the next cycle and reschedule notifications
        try {
          await RentReminderService.markDuePaid(c.listingId);
        } catch (_) {}
        return c;
      }
    }
    throw StateError('Claim not found');
  }

  static Future<OfflinePaymentClaim> rejectClaim(String claimId, {String? reason}) async {
    final all = await _loadAll();
    for (int i = 0; i < all.length; i++) {
      if (all[i].id == claimId) {
        final c = all[i].copyWith(
          status: OfflinePaymentStatus.rejected,
          decidedAt: DateTime.now(),
          rejectionReason: reason,
        );
        all[i] = c;
        await _saveAll(all);
        return c;
      }
    }
    throw StateError('Claim not found');
  }
}
