import 'package:flutter/foundation.dart';

/// Booking status enumeration
enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  completed,
}

/// Booking model for property reservations
@immutable
class Booking {
  final String id;
  final String propertyId;
  final String propertyName;
  final String propertyImage;
  final String userId;
  final String userName;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime createdAt;
  final BookingStatus status;
  final double totalAmount;
  final String currency;
  final int guests;
  final String? specialRequests;
  final Map<String, dynamic>? metadata;

  const Booking({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.propertyImage,
    required this.userId,
    required this.userName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.guests,
    this.specialRequests,
    this.metadata,
  });

  /// Create a copy of this booking with updated fields
  Booking copyWith({
    String? id,
    String? propertyId,
    String? propertyName,
    String? propertyImage,
    String? userId,
    String? userName,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    DateTime? createdAt,
    BookingStatus? status,
    double? totalAmount,
    String? currency,
    int? guests,
    String? specialRequests,
    Map<String, dynamic>? metadata,
  }) {
    return Booking(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyName: propertyName ?? this.propertyName,
      propertyImage: propertyImage ?? this.propertyImage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      guests: guests ?? this.guests,
      specialRequests: specialRequests ?? this.specialRequests,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert booking to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyImage': propertyImage,
      'userId': userId,
      'userName': userName,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'totalAmount': totalAmount,
      'currency': currency,
      'guests': guests,
      'specialRequests': specialRequests,
      'metadata': metadata,
    };
  }

  /// Create booking from JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      propertyName: json['propertyName'] as String,
      propertyImage: json['propertyImage'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      guests: json['guests'] as int,
      specialRequests: json['specialRequests'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Get duration of stay in days
  int get durationInDays {
    return checkOutDate.difference(checkInDate).inDays;
  }

  /// Check if booking is active (confirmed or checked in)
  bool get isActive {
    return status == BookingStatus.confirmed || status == BookingStatus.checkedIn;
  }

  /// Check if booking is completed
  bool get isCompleted {
    return status == BookingStatus.completed || status == BookingStatus.checkedOut;
  }

  /// Check if booking is cancelled
  bool get isCancelled {
    return status == BookingStatus.cancelled;
  }

  /// Get status display text
  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.checkedIn:
        return 'Checked In';
      case BookingStatus.checkedOut:
        return 'Checked Out';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking(id: $id, propertyName: $propertyName, status: $status, checkIn: $checkInDate, checkOut: $checkOutDate)';
  }
}
