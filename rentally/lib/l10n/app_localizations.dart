import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Make sure to add the following packages to your pubspec.yaml file:
/// - flutter_localizations
/// - intl: any # Use the pinned version from flutter_localizations
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you'll need to edit this
/// file.
///
/// First, open your project's ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project's Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// Common strings
  String get appName => 'Rentaly';
  String get welcome => 'Welcome';
  String get login => 'Login';
  String get register => 'Register';
  String get logout => 'Logout';
  String get cancel => 'Cancel';
  String get save => 'Save';
  String get delete => 'Delete';
  String get edit => 'Edit';
  String get search => 'Search';
  String get filter => 'Filter';
  String get sort => 'Sort';
  String get loading => 'Loading...';
  String get error => 'Error';
  String get success => 'Success';
  String get retry => 'Retry';
  String get close => 'Close';
  String get next => 'Next';
  String get previous => 'Previous';
  String get done => 'Done';
  String get skip => 'Skip';
  String get continue_ => 'Continue';
  String get back => 'Back';
  String get home => 'Home';
  String get profile => 'Profile';
  String get settings => 'Settings';
  String get help => 'Help';
  String get about => 'About';
  String get share => 'Share';
  String get goBack => 'Go Back';

  /// Authentication
  String get email => 'Email';
  String get password => 'Password';
  String get confirmPassword => 'Confirm Password';
  String get forgotPassword => 'Forgot Password?';
  String get resetPassword => 'Reset Password';
  String get createAccount => 'Create Account';
  String get alreadyHaveAccount => 'Already have an account?';
  String get dontHaveAccount => "Don't have an account?";
  String get signInWithGoogle => 'Sign in with Google';
  String get signInWithApple => 'Sign in with Apple';
  String get signInWithFacebook => 'Sign in with Facebook';

  /// Property related
  String get properties => 'Properties';
  String get property => 'Property';
  String get propertyType => 'Property Type';
  String get apartment => 'Apartment';
  String get house => 'House';
  String get villa => 'Villa';
  String get studio => 'Studio';
  String get office => 'Office';
  String get warehouse => 'Warehouse';
  String get land => 'Land';
  String get commercial => 'Commercial';
  String get residential => 'Residential';
  String get rent => 'Rent';
  String get sale => 'Sale';
  String get price => 'Price';
  String get priceRange => 'Price Range';
  String get location => 'Location';
  String get address => 'Address';
  String get city => 'City';
  String get state => 'State';
  String get country => 'Country';
  String get zipCode => 'ZIP Code';
  String get bedrooms => 'Bedrooms';
  String get bathrooms => 'Bathrooms';
  String get area => 'Area';
  String get squareFeet => 'Square Feet';
  String get squareMeters => 'Square Meters';
  String get furnished => 'Furnished';
  String get unfurnished => 'Unfurnished';
  String get semifurnished => 'Semi-furnished';
  String get available => 'Available';
  String get unavailable => 'Unavailable';
  String get featured => 'Featured';
  String get recommended => 'Recommended';
  String get nearby => 'Nearby';
  String get amenities => 'Amenities';
  String get description => 'Description';
  String get images => 'Images';
  String get virtualTour => 'Virtual Tour';
  String get contactOwner => 'Contact Owner';
  String get bookNow => 'Book Now';
  String get addToWishlist => 'Add to Wishlist';
  String get removeFromWishlist => 'Remove from Wishlist';
  String get viewDetails => 'View Details';

  /// Booking
  String get booking => 'Booking';
  String get bookings => 'Bookings';
  String get bookingHistory => 'Booking History';
  String get bookingDetails => 'Booking Details';
  String get checkIn => 'Check In';
  String get checkOut => 'Check Out';
  String get guests => 'Guests';
  String get totalAmount => 'Total Amount';
  String get bookingConfirmed => 'Booking Confirmed';
  String get bookingPending => 'Booking Pending';
  String get bookingCancelled => 'Booking Cancelled';
  String get cancelBooking => 'Cancel Booking';
  String get modifyBooking => 'Modify Booking';

  /// Payment
  String get payment => 'Payment';
  String get paymentMethod => 'Payment Method';
  String get creditCard => 'Credit Card';
  String get debitCard => 'Debit Card';
  String get paypal => 'PayPal';
  String get bankTransfer => 'Bank Transfer';
  String get cardNumber => 'Card Number';
  String get expiryDate => 'Expiry Date';
  String get cvv => 'CVV';
  String get cardHolderName => 'Cardholder Name';
  String get billingAddress => 'Billing Address';
  String get paymentSuccessful => 'Payment Successful';
  String get paymentFailed => 'Payment Failed';
  String get processPayment => 'Process Payment';

  /// User roles
  String get seeker => 'Seeker';
  String get owner => 'Owner';
  String get admin => 'Admin';
  String get selectRole => 'Select Role';
  String get roleDescription => 'Choose your role to get started';

  /// Navigation
  String get dashboard => 'Dashboard';
  String get listings => 'Listings';
  String get favorites => 'Favorites';
  String get wishlist => 'Wishlist';
  String get messages => 'Messages';
  String get notifications => 'Notifications';
  String get account => 'Account';

  /// Forms
  String get firstName => 'First Name';
  String get lastName => 'Last Name';
  String get fullName => 'Full Name';
  String get phoneNumber => 'Phone Number';
  String get dateOfBirth => 'Date of Birth';
  String get gender => 'Gender';
  String get male => 'Male';
  String get female => 'Female';
  String get other => 'Other';
  String get preferNotToSay => 'Prefer not to say';

  /// Validation messages
  String get fieldRequired => 'This field is required';
  String get invalidEmail => 'Please enter a valid email';
  String get passwordTooShort => 'Password must be at least 8 characters';
  String get passwordsDoNotMatch => 'Passwords do not match';
  String get invalidPhoneNumber => 'Please enter a valid phone number';

  /// Status messages
  String get noDataFound => 'No data found';
  String get noPropertiesFound => 'No properties found';
  String get noBookingsFound => 'No bookings found';
  String get noNotificationsFound => 'No notifications found';
  String get connectionError => 'Connection error. Please try again.';
  String get serverError => 'Server error. Please try again later.';
  String get unknownError => 'An unknown error occurred';

  /// Time and dates
  String get today => 'Today';
  String get yesterday => 'Yesterday';
  String get tomorrow => 'Tomorrow';
  String get thisWeek => 'This Week';
  String get lastWeek => 'Last Week';
  String get thisMonth => 'This Month';
  String get lastMonth => 'Last Month';
  String get thisYear => 'This Year';
  String get lastYear => 'Last Year';

  /// Units
  String get currency => 'Currency';
  String get usd => 'USD';
  String get eur => 'EUR';
  String get gbp => 'GBP';
  String get inr => 'INR';
  String get perMonth => 'per month';
  String get perDay => 'per day';
  String get perNight => 'per night';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  // Default to English for unsupported locales
  return AppLocalizationsEn();
}
