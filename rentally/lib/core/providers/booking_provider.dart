import 'package:flutter/foundation.dart';
import '../services/mock_api_service.dart';
import '../database/models/booking_model.dart';

/// ========================================
/// 📅 BOOKING PROVIDER - REAL BACKEND INTEGRATION
/// ========================================
/// 
/// This provider handles all booking-related operations using your real backend API.
/// Make sure your backend implements all required endpoints before using this provider.
/// 
/// REQUIRED BACKEND ENDPOINTS:
/// - GET /bookings/user/{userId} - Get user's bookings
/// - POST /bookings - Create new booking
/// - GET /bookings/owner/{ownerId} - Get owner's property bookings
/// 
class BookingProvider with ChangeNotifier {
  final RealApiService _realApiService = RealApiService();

  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;
  final List<BookingModel> _ownerBookings = [];
  BookingModel? _selectedBooking;

  // Getters
  List<BookingModel> get userBookings => _bookings;
  List<BookingModel> get ownerBookings => _ownerBookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;

  /// Initialize the provider
  Future<void> initialize() async {
    // Provider ready to use real backend API
  }

  /// Load user bookings from real backend
  Future<void> loadUserBookings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _realApiService.getUserBookings(userId);
      _bookings = response.map((json) => BookingModel.fromJson(json)).toList();
        } catch (e) {
      _error = 'Failed to load bookings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new booking using real backend
  Future<BookingModel?> createBooking(BookingModel booking) async {
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final bookingData = booking.toJson();
      final response = await _realApiService.createBooking(bookingData);
      if (response['success'] == true && response['bookingId'] != null) {
        final newBooking = BookingModel.fromJson({
          'id': response['bookingId'],
          'propertyId': booking.propertyId,
          'guestId': booking.guestId,
          'ownerId': booking.ownerId,
          'checkInDate': booking.checkInDate.toIso8601String(),
          'checkOutDate': booking.checkOutDate.toIso8601String(),
          'guests': booking.guests,
          'totalAmount': booking.totalAmount,
          'serviceFee': booking.serviceFee,
          'taxes': booking.taxes,
          'status': booking.status.toString(),
          'paymentStatus': booking.paymentStatus.toString(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'details': booking.details,
        });
        _bookings.add(newBooking);
        return newBooking;
      } else {
        _error = response['message'] ?? 'Failed to create booking';
        return null;
      }
    } catch (e) {
      _error = 'Failed to create booking: $e';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selected booking
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }
}
