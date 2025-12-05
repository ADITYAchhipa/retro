import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../core/constants/api_constants.dart';
import '../core/models/booking.dart' as core_booking;
import 'token_storage_service.dart';

// Booking model
class Booking {
  final String id;
  final String listingId;
  final String userId;
  final String ownerId;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final BookingStatus status;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PaymentInfo paymentInfo;
  final String? seekerIdImage; // optional path/url to seeker-provided ID

  const Booking({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.ownerId,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.status,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentInfo,
    this.seekerIdImage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'listingId': listingId,
    'userId': userId,
    'ownerId': ownerId,
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut.toIso8601String(),
    'totalPrice': totalPrice,
    'status': status.name,
    'specialRequests': specialRequests,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'paymentInfo': paymentInfo.toJson(),
    'seekerIdImage': seekerIdImage,
  };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'],
    listingId: json['listingId'],
    userId: json['userId'],
    ownerId: json['ownerId'],
    checkIn: DateTime.parse(json['checkIn']),
    checkOut: DateTime.parse(json['checkOut']),
    totalPrice: json['totalPrice'].toDouble(),
    status: BookingStatus.values.firstWhere((s) => s.name == json['status']),
    specialRequests: json['specialRequests'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    paymentInfo: PaymentInfo.fromJson(json['paymentInfo']),
    seekerIdImage: json['seekerIdImage'],
  );

  Booking copyWith({
    BookingStatus? status,
    String? specialRequests,
    PaymentInfo? paymentInfo,
    String? seekerIdImage,
  }) => Booking(
    id: id,
    listingId: listingId,
    userId: userId,
    ownerId: ownerId,
    checkIn: checkIn,
    checkOut: checkOut,
    totalPrice: totalPrice,
    status: status ?? this.status,
    specialRequests: specialRequests ?? this.specialRequests,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    paymentInfo: paymentInfo ?? this.paymentInfo,
    seekerIdImage: seekerIdImage ?? this.seekerIdImage,
  );
}

enum BookingStatus {
  pending,
  confirmed,
  checkedIn,
  checkedOut,
  cancelled,
  completed
}

class PaymentInfo {
  final String method;
  final String? transactionId;
  final bool isPaid;
  final DateTime? paidAt;

  const PaymentInfo({
    required this.method,
    this.transactionId,
    required this.isPaid,
    this.paidAt,
  });

  Map<String, dynamic> toJson() => {
    'method': method,
    'transactionId': transactionId,
    'isPaid': isPaid,
    'paidAt': paidAt?.toIso8601String(),
  };

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
    method: json['method'],
    transactionId: json['transactionId'],
    isPaid: json['isPaid'],
    paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
  );
}

// Booking state
class BookingState {
  final List<Booking> userBookings;
  final List<Booking> ownerBookings;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const BookingState({
    this.userBookings = const [],
    this.ownerBookings = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  BookingState copyWith({
    List<Booking>? userBookings,
    List<Booking>? ownerBookings,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => BookingState(
    userBookings: userBookings ?? this.userBookings,
    ownerBookings: ownerBookings ?? this.ownerBookings,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

// Booking service
class BookingService extends StateNotifier<BookingState> {
  BookingService() : super(const BookingState()) {
    _loadBookings();
    _startPeriodicSync();
  }

  Timer? _syncTimer;
  static const String _userBookingsKey = 'user_bookings';
  static const String _ownerBookingsKey = 'owner_bookings';

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // Load bookings from cache
  Future<void> _loadBookings() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user bookings
      final userBookingsJson = prefs.getString(_userBookingsKey);
      if (userBookingsJson != null) {
        final List<dynamic> decoded = json.decode(userBookingsJson);
        final userBookings = decoded.map((item) => Booking.fromJson(item)).toList();
        state = state.copyWith(userBookings: userBookings);
      }

      // Load owner bookings
      final ownerBookingsJson = prefs.getString(_ownerBookingsKey);
      if (ownerBookingsJson != null) {
        final List<dynamic> decoded = json.decode(ownerBookingsJson);
        final ownerBookings = decoded.map((item) => Booking.fromJson(item)).toList();
        state = state.copyWith(ownerBookings: ownerBookings);
      }

      // Simulate fetching fresh data
      await _fetchBookings();
      
    } catch (e) {
      state = state.copyWith(error: 'Failed to load bookings: $e', isLoading: false);
    }
  }

  // Fetch bookings from backend API
  Future<void> _fetchBookings() async {
    try {
      final bookings = await fetchUserBookingsFromApi();
      
      if (bookings != null) {
        state = state.copyWith(
          userBookings: bookings,
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        await _cacheBookings();
      } else {
        // Fallback to mock data if API fails
        if (state.userBookings.isEmpty && state.ownerBookings.isEmpty) {
          final mockBookings = _generateMockBookings();
          state = state.copyWith(
            userBookings: mockBookings['user']!,
            ownerBookings: mockBookings['owner']!,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
          await _cacheBookings();
        } else {
          state = state.copyWith(
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch bookings: $e', isLoading: false);
    }
  }

  // Fetch user bookings from API
  Future<List<Booking>?> fetchUserBookingsFromApi() async {
    try {
      final token = await TokenStorageService.getToken();
      
      if (token == null) {
        print('No auth token found');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/user/bookings');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['bookings'] != null) {
          final bookingsData = data['bookings'];
          final List<Booking> allBookings = [];

          // Parse confirmed bookings
          if (bookingsData['confirmed'] != null) {
            for (var item in bookingsData['confirmed']) {
              allBookings.add(_parseBookingFromApi(item));
            }
          }

          // Parse completed bookings
          if (bookingsData['completed'] != null) {
            for (var item in bookingsData['completed']) {
              allBookings.add(_parseBookingFromApi(item));
            }
          }

          // Parse cancelled bookings
          if (bookingsData['cancelled'] != null) {
            for (var item in bookingsData['cancelled']) {
              allBookings.add(_parseBookingFromApi(item));
            }
          }

          return allBookings;
        }
      } else {
        print('Failed to fetch bookings: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('Error fetching bookings from API: $e');
      return null;
    }
  }

  // Parse booking from API response
  Booking _parseBookingFromApi(Map<String, dynamic> data) {
    // Determine if it's a property or vehicle booking
    final isProperty = data['type'] == 'property';
    final itemData = isProperty ? data['property'] : data['vehicle'];

    // Map backend status to frontend BookingStatus
    BookingStatus status;
    switch (data['status']) {
      case 'confirmed':
        status = BookingStatus.confirmed;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      default:
        status = BookingStatus.pending;
    }

    return Booking(
      id: data['id'],
      listingId: itemData['id'] ?? '',
      userId: data['userId'] ?? '',
      ownerId: '', // Not provided by backend
      checkIn: DateTime.parse(data['startDate']),
      checkOut: DateTime.parse(data['endDate']),
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: status,
      specialRequests: null,
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      paymentInfo: PaymentInfo(
        method: data['paymentStatus'] == 'paid' ? 'Paid' : 'Pending',
        transactionId: null,
        isPaid: data['paymentStatus'] == 'paid',
        paidAt: data['paymentStatus'] == 'paid' ? DateTime.now() : null,
      ),
    );
  }

  // Cache bookings locally
  Future<void> _cacheBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userBookingsJson = json.encode(state.userBookings.map((b) => b.toJson()).toList());
      await prefs.setString(_userBookingsKey, userBookingsJson);
      
      final ownerBookingsJson = json.encode(state.ownerBookings.map((b) => b.toJson()).toList());
      await prefs.setString(_ownerBookingsKey, ownerBookingsJson);
    } catch (e) {
      // Handle caching error silently
    }
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _fetchBookings();
    });
  }

  // Public methods
  Future<void> refreshBookings() async {
    await _fetchBookings();
  }

  Future<void> createBooking(Booking booking) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      final updatedUserBookings = [...state.userBookings, booking];
      
      state = state.copyWith(
        userBookings: updatedUserBookings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheBookings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to create booking: $e', isLoading: false);
    }
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus newStatus) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final updatedUserBookings = state.userBookings.map((b) => 
        b.id == bookingId ? b.copyWith(status: newStatus) : b).toList();
      final updatedOwnerBookings = state.ownerBookings.map((b) => 
        b.id == bookingId ? b.copyWith(status: newStatus) : b).toList();
      
      state = state.copyWith(
        userBookings: updatedUserBookings,
        ownerBookings: updatedOwnerBookings,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
      
      await _cacheBookings();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update booking: $e', isLoading: false);
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Generate mock bookings
  Map<String, List<Booking>> _generateMockBookings() {
    final now = DateTime.now();
    
    final userBookings = [
      Booking(
        id: 'booking1',
        listingId: '1',
        userId: 'user1',
        ownerId: 'owner1',
        checkIn: now.add(const Duration(days: 7)),
        checkOut: now.add(const Duration(days: 10)),
        totalPrice: 360.0,
        status: BookingStatus.confirmed,
        specialRequests: 'Late check-in please',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        paymentInfo: const PaymentInfo(
          method: 'Credit Card',
          transactionId: 'txn_123456',
          isPaid: true,
          paidAt: null,
        ),
      ),
      Booking(
        id: 'booking2',
        listingId: '2',
        userId: 'user1',
        ownerId: 'owner2',
        checkIn: now.subtract(const Duration(days: 5)),
        checkOut: now.subtract(const Duration(days: 2)),
        totalPrice: 600.0,
        status: BookingStatus.completed,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
        paymentInfo: const PaymentInfo(
          method: 'PayPal',
          transactionId: 'txn_789012',
          isPaid: true,
        ),
      ),
    ];

    final ownerBookings = [
      Booking(
        id: 'booking3',
        listingId: '3',
        userId: 'user2',
        ownerId: 'user1', // Current user as owner
        checkIn: now.add(const Duration(days: 14)),
        checkOut: now.add(const Duration(days: 17)),
        totalPrice: 450.0,
        status: BookingStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        paymentInfo: const PaymentInfo(
          method: 'Credit Card',
          isPaid: false,
        ),
      ),
    ];

    return {
      'user': userBookings,
      'owner': ownerBookings,
    };
  }
}

// Provider
final bookingProvider = StateNotifierProvider<BookingService, BookingState>((ref) {
  return BookingService();
});

// Filtered bookings providers
final upcomingBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(bookingProvider).userBookings;
  final now = DateTime.now();
  
  return bookings.where((booking) => 
    booking.checkIn.isAfter(now) && 
    (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending)
  ).toList()..sort((a, b) => a.checkIn.compareTo(b.checkIn));
});

final completedBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(bookingProvider).userBookings;
  
  return bookings.where((booking) => 
    booking.status == BookingStatus.completed || booking.status == BookingStatus.checkedOut
  ).toList()..sort((a, b) => b.checkOut.compareTo(a.checkOut));
});

final cancelledBookingsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(bookingProvider).userBookings;
  
  return bookings.where((booking) => 
    booking.status == BookingStatus.cancelled
  ).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final ownerBookingRequestsProvider = Provider<List<Booking>>((ref) {
  final bookings = ref.watch(bookingProvider).ownerBookings;
  
  return bookings.where((booking) => 
    booking.status == BookingStatus.pending
  ).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
