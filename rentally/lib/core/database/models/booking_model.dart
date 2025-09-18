/// Booking model representing rental bookings in the database
class BookingModel {
  final String id;
  final String propertyId;
  final String guestId;
  final String ownerId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalAmount;
  final double serviceFee;
  final double taxes;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BookingDetails details;

  BookingModel({
    required this.id,
    required this.propertyId,
    required this.guestId,
    required this.ownerId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalAmount,
    required this.serviceFee,
    required this.taxes,
    required this.status,
    required this.paymentStatus,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
  });

  int get nights => checkOutDate.difference(checkInDate).inDays;
  double get subtotal => totalAmount - serviceFee - taxes;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      propertyId: json['propertyId'] as String,
      guestId: json['guestId'] as String,
      ownerId: json['ownerId'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      guests: json['guests'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      taxes: (json['taxes'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      specialRequests: json['specialRequests'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      details: BookingDetails.fromJson(json['details'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'guestId': guestId,
      'ownerId': ownerId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'guests': guests,
      'totalAmount': totalAmount,
      'serviceFee': serviceFee,
      'taxes': taxes,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'specialRequests': specialRequests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'details': details.toJson(),
    };
  }
}

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  completed,
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
  failed,
}

class BookingDetails {
  final String propertyTitle;
  final String propertyLocation;
  final String propertyImage;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String ownerName;
  final String ownerEmail;

  BookingDetails({
    required this.propertyTitle,
    required this.propertyLocation,
    required this.propertyImage,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.ownerName,
    required this.ownerEmail,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      propertyTitle: json['propertyTitle'] as String,
      propertyLocation: json['propertyLocation'] as String,
      propertyImage: json['propertyImage'] as String,
      guestName: json['guestName'] as String,
      guestEmail: json['guestEmail'] as String,
      guestPhone: json['guestPhone'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyTitle': propertyTitle,
      'propertyLocation': propertyLocation,
      'propertyImage': propertyImage,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
    };
  }
}
