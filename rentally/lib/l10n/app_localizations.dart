import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

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
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rentaly'**
  String get appTitle;

  /// No description provided for @splashWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rentally'**
  String get splashWelcome;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get country;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Choose Role'**
  String get role;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @listing.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listing;

  /// No description provided for @booking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get booking;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @ownerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Owner Dashboard'**
  String get ownerDashboard;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add Listing'**
  String get addListing;

  /// No description provided for @bookingRequests.
  ///
  /// In en, this message translates to:
  /// **'Booking Requests'**
  String get bookingRequests;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @seeker.
  ///
  /// In en, this message translates to:
  /// **'Seeker'**
  String get seeker;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @themePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme preview'**
  String get themePreview;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Find Rooms, Vehicles, & More Anywhere in the World'**
  String get appTagline;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Find Rentals Across the Globe'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Desc.
  ///
  /// In en, this message translates to:
  /// **'Discover rooms, apartments, and vehicles in any country'**
  String get onboardingSlide1Desc;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Pay in Your Currency, Stay Anywhere'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Desc.
  ///
  /// In en, this message translates to:
  /// **'Automatic currency conversion and local payment methods'**
  String get onboardingSlide2Desc;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Be a Seeker or Become an Owner Instantly'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Desc.
  ///
  /// In en, this message translates to:
  /// **'Switch between finding rentals and listing your properties'**
  String get onboardingSlide3Desc;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search location, property, or vehicle...'**
  String get searchHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @referralAndEarn.
  ///
  /// In en, this message translates to:
  /// **'Referral & Earn'**
  String get referralAndEarn;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @rewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewards;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @totalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total Tokens'**
  String get totalTokens;

  /// No description provided for @totalReferrals.
  ///
  /// In en, this message translates to:
  /// **'Total Referrals'**
  String get totalReferrals;

  /// No description provided for @yourReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get yourReferralCode;

  /// No description provided for @copyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get copyCode;

  /// No description provided for @shareCodeToEarnTokens.
  ///
  /// In en, this message translates to:
  /// **'Share this code with friends to earn tokens'**
  String get shareCodeToEarnTokens;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @shareCode.
  ///
  /// In en, this message translates to:
  /// **'Share Code'**
  String get shareCode;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @availableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// No description provided for @earnTokensFor.
  ///
  /// In en, this message translates to:
  /// **'Earn Tokens For'**
  String get earnTokensFor;

  /// No description provided for @userSignup.
  ///
  /// In en, this message translates to:
  /// **'User Signup'**
  String get userSignup;

  /// No description provided for @firstBooking.
  ///
  /// In en, this message translates to:
  /// **'First Booking'**
  String get firstBooking;

  /// No description provided for @hostRegistration.
  ///
  /// In en, this message translates to:
  /// **'Host Registration'**
  String get hostRegistration;

  /// No description provided for @propertyListing.
  ///
  /// In en, this message translates to:
  /// **'Property Listing'**
  String get propertyListing;

  /// No description provided for @firstReview.
  ///
  /// In en, this message translates to:
  /// **'First Review'**
  String get firstReview;

  /// No description provided for @redeemTokens.
  ///
  /// In en, this message translates to:
  /// **'Redeem Tokens'**
  String get redeemTokens;

  /// No description provided for @tokensToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Tokens to Redeem'**
  String get tokensToRedeem;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @redeemNow.
  ///
  /// In en, this message translates to:
  /// **'Redeem Now'**
  String get redeemNow;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @startReferringToSeeHistory.
  ///
  /// In en, this message translates to:
  /// **'Start referring friends to see your transaction history'**
  String get startReferringToSeeHistory;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @apartments.
  ///
  /// In en, this message translates to:
  /// **'Apartments'**
  String get apartments;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get cars;

  /// No description provided for @bikes.
  ///
  /// In en, this message translates to:
  /// **'Bikes'**
  String get bikes;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @wifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get wifi;

  /// No description provided for @ac.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get ac;

  /// No description provided for @parking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get parking;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List View'**
  String get listView;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @nearYou.
  ///
  /// In en, this message translates to:
  /// **'Near You'**
  String get nearYou;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @perNight.
  ///
  /// In en, this message translates to:
  /// **'per night'**
  String get perNight;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'per day'**
  String get perDay;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonth;

  /// No description provided for @perHour.
  ///
  /// In en, this message translates to:
  /// **'per hour'**
  String get perHour;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get selectDates;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOut;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get checkInTime;

  /// No description provided for @checkOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out time'**
  String get checkOutTime;

  /// No description provided for @guests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guests;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price Breakdown'**
  String get priceBreakdown;

  /// No description provided for @referralCredits.
  ///
  /// In en, this message translates to:
  /// **'Referral credits'**
  String get referralCredits;

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePrice;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get serviceFee;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxes;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @cashOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Cash on arrival'**
  String get cashOnArrival;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @googlePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get googlePay;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// No description provided for @bookYourStay.
  ///
  /// In en, this message translates to:
  /// **'Book Your Stay'**
  String get bookYourStay;

  /// No description provided for @bookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Booking History'**
  String get bookingHistory;

  /// No description provided for @detailsGuests.
  ///
  /// In en, this message translates to:
  /// **'Details & Guests'**
  String get detailsGuests;

  /// No description provided for @addDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates'**
  String get addDates;

  /// No description provided for @specialRequestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Special requests (optional)'**
  String get specialRequestsOptional;

  /// No description provided for @addonsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Add-ons & Preferences'**
  String get addonsPreferences;

  /// No description provided for @insuranceAddOns.
  ///
  /// In en, this message translates to:
  /// **'Insurance Add-ons'**
  String get insuranceAddOns;

  /// No description provided for @noInsurance.
  ///
  /// In en, this message translates to:
  /// **'No Insurance'**
  String get noInsurance;

  /// No description provided for @basicCoverage.
  ///
  /// In en, this message translates to:
  /// **'Basic coverage'**
  String get basicCoverage;

  /// No description provided for @standardCoverage.
  ///
  /// In en, this message translates to:
  /// **'Standard coverage'**
  String get standardCoverage;

  /// No description provided for @maximumCoverage.
  ///
  /// In en, this message translates to:
  /// **'Maximum coverage'**
  String get maximumCoverage;

  /// No description provided for @insuranceNote.
  ///
  /// In en, this message translates to:
  /// **'Note: Insurance add-ons are provided by third-party partners. Terms apply.'**
  String get insuranceNote;

  /// No description provided for @paymentBilling.
  ///
  /// In en, this message translates to:
  /// **'Payment & Billing'**
  String get paymentBilling;

  /// No description provided for @billingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing address'**
  String get billingAddress;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Cancellation Policies'**
  String get agreeTerms;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @tokensToApply.
  ///
  /// In en, this message translates to:
  /// **'Tokens to apply'**
  String get tokensToApply;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @appliedTokens.
  ///
  /// In en, this message translates to:
  /// **'Applied: {count} tokens'**
  String appliedTokens(int count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @tokenUnitEquation.
  ///
  /// In en, this message translates to:
  /// **'1 token = 1 {currency} unit'**
  String tokenUnitEquation(Object currency);

  /// No description provided for @availableTokens.
  ///
  /// In en, this message translates to:
  /// **'Available: {count} tokens'**
  String availableTokens(int count);

  /// No description provided for @hostApprovalNote.
  ///
  /// In en, this message translates to:
  /// **'This listing requires host approval. You will not be charged now. We will notify you when the host approves your request.'**
  String get hostApprovalNote;

  /// No description provided for @basicInsurance.
  ///
  /// In en, this message translates to:
  /// **'Basic Insurance'**
  String get basicInsurance;

  /// No description provided for @standardInsurance.
  ///
  /// In en, this message translates to:
  /// **'Standard Insurance'**
  String get standardInsurance;

  /// No description provided for @premiumInsurance.
  ///
  /// In en, this message translates to:
  /// **'Premium Insurance'**
  String get premiumInsurance;

  /// No description provided for @liabilityNote.
  ///
  /// In en, this message translates to:
  /// **'You accept liability as per host terms.'**
  String get liabilityNote;

  /// No description provided for @couponCode.
  ///
  /// In en, this message translates to:
  /// **'Coupon code'**
  String get couponCode;

  /// No description provided for @enterCouponOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter coupon (optional)'**
  String get enterCouponOptional;

  /// No description provided for @selectedDates.
  ///
  /// In en, this message translates to:
  /// **'Selected Dates'**
  String get selectedDates;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @continueToAddOns.
  ///
  /// In en, this message translates to:
  /// **'Continue to Add-ons'**
  String get continueToAddOns;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @reviewAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Review & Confirm'**
  String get reviewAndConfirm;

  /// No description provided for @reviewRequest.
  ///
  /// In en, this message translates to:
  /// **'Review Request'**
  String get reviewRequest;

  /// No description provided for @payAndConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay & Confirm'**
  String get payAndConfirm;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @infants.
  ///
  /// In en, this message translates to:
  /// **'Infants'**
  String get infants;

  /// No description provided for @ages13OrAbove.
  ///
  /// In en, this message translates to:
  /// **'Ages 13 or above'**
  String get ages13OrAbove;

  /// No description provided for @ages2To12.
  ///
  /// In en, this message translates to:
  /// **'Ages 2-12'**
  String get ages2To12;

  /// No description provided for @under2.
  ///
  /// In en, this message translates to:
  /// **'Under 2'**
  String get under2;

  /// No description provided for @guestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsLabel;

  /// No description provided for @datesLabel.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get datesLabel;

  /// No description provided for @requestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsLabel;

  /// No description provided for @addonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Add-ons'**
  String get addonsLabel;

  /// No description provided for @bookingError.
  ///
  /// In en, this message translates to:
  /// **'Booking Error'**
  String get bookingError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get requestSubmitted;

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Your booking request has been sent to the host.'**
  String get bookingRequestSent;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @couponApplied10.
  ///
  /// In en, this message translates to:
  /// **'Coupon applied: 10% off base'**
  String get couponApplied10;

  /// No description provided for @invalidCoupon.
  ///
  /// In en, this message translates to:
  /// **'Invalid coupon'**
  String get invalidCoupon;

  /// No description provided for @addonAirportPickup.
  ///
  /// In en, this message translates to:
  /// **'Airport pickup'**
  String get addonAirportPickup;

  /// No description provided for @addonAirportPickupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-way pickup from airport'**
  String get addonAirportPickupSubtitle;

  /// No description provided for @addonBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get addonBreakfast;

  /// No description provided for @addonBreakfastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily breakfast for all guests'**
  String get addonBreakfastSubtitle;

  /// No description provided for @addonExtraBed.
  ///
  /// In en, this message translates to:
  /// **'Extra bed'**
  String get addonExtraBed;

  /// No description provided for @addonExtraBedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One additional bed'**
  String get addonExtraBedSubtitle;

  /// No description provided for @bookingConfirmedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmedNotificationTitle;

  /// No description provided for @bookingConfirmedNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking is confirmed! Tap to view details.'**
  String get bookingConfirmedNotificationBody;

  /// No description provided for @bookingRequestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Request Sent'**
  String get bookingRequestSentTitle;

  /// No description provided for @bookingRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Your request has been sent to the host. We will notify you when it\'s approved.'**
  String get bookingRequestSentBody;

  /// No description provided for @kycVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'KYC verification is required for bookings over {amount}.'**
  String kycVerificationRequired(Object amount);

  /// No description provided for @paymentFailedWithReason.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {reason}'**
  String paymentFailedWithReason(Object reason);

  /// No description provided for @paymentErrorWithReason.
  ///
  /// In en, this message translates to:
  /// **'Payment error: {error}'**
  String paymentErrorWithReason(Object error);

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your booking'**
  String get thankYou;

  /// No description provided for @viewBooking.
  ///
  /// In en, this message translates to:
  /// **'View Booking'**
  String get viewBooking;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @listingTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing Title'**
  String get listingTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyType;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// No description provided for @pricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per Night'**
  String get pricePerNight;

  /// No description provided for @pricePerDay.
  ///
  /// In en, this message translates to:
  /// **'Price per Day'**
  String get pricePerDay;

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Price per Month'**
  String get pricePerMonth;

  /// No description provided for @pricePerHour.
  ///
  /// In en, this message translates to:
  /// **'Price per Hour'**
  String get pricePerHour;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'ZIP Code'**
  String get zipCode;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @maxGuests.
  ///
  /// In en, this message translates to:
  /// **'Max Guests'**
  String get maxGuests;

  /// No description provided for @selectAmenities.
  ///
  /// In en, this message translates to:
  /// **'Select Amenities'**
  String get selectAmenities;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @saveListing.
  ///
  /// In en, this message translates to:
  /// **'Save Listing'**
  String get saveListing;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit Listing'**
  String get editListing;

  /// No description provided for @deleteListing.
  ///
  /// In en, this message translates to:
  /// **'Delete Listing'**
  String get deleteListing;

  /// No description provided for @listingStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get listingStatus;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @guestName.
  ///
  /// In en, this message translates to:
  /// **'Guest Name'**
  String get guestName;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Request Date'**
  String get requestDate;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @noListings.
  ///
  /// In en, this message translates to:
  /// **'No listings yet'**
  String get noListings;

  /// No description provided for @createFirstListing.
  ///
  /// In en, this message translates to:
  /// **'Create your first listing'**
  String get createFirstListing;

  /// No description provided for @noBookingRequests.
  ///
  /// In en, this message translates to:
  /// **'No booking requests'**
  String get noBookingRequests;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get avgRating;

  /// No description provided for @simulateTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Simulate Test Notification'**
  String get simulateTestNotification;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification to verify the system is working correctly.'**
  String get testNotificationBody;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get lastSeen;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessages;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get startConversation;

  /// No description provided for @newBooking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get newBooking;

  /// No description provided for @bookingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Booking Update'**
  String get bookingUpdate;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @listingViewed.
  ///
  /// In en, this message translates to:
  /// **'Listing Viewed'**
  String get listingViewed;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @youreAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get youreAllCaughtUp;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @older.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get older;

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with'**
  String get chatWith;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noUpcomingBookings.
  ///
  /// In en, this message translates to:
  /// **'No Upcoming Bookings'**
  String get noUpcomingBookings;

  /// No description provided for @noUpcomingBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any upcoming bookings at the moment.'**
  String get noUpcomingBookingsDesc;

  /// No description provided for @noCompletedBookings.
  ///
  /// In en, this message translates to:
  /// **'No Completed Bookings'**
  String get noCompletedBookings;

  /// No description provided for @noCompletedBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t completed any bookings yet.'**
  String get noCompletedBookingsDesc;

  /// No description provided for @noCancelledBookings.
  ///
  /// In en, this message translates to:
  /// **'No Cancelled Bookings'**
  String get noCancelledBookings;

  /// No description provided for @noCancelledBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any cancelled bookings.'**
  String get noCancelledBookingsDesc;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @nights.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get nights;

  /// No description provided for @bookingDate.
  ///
  /// In en, this message translates to:
  /// **'Booking Date'**
  String get bookingDate;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @emptyWishlist.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get emptyWishlist;

  /// No description provided for @emptyWishlistDesc.
  ///
  /// In en, this message translates to:
  /// **'Save your favorite listings to see them here'**
  String get emptyWishlistDesc;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start Exploring'**
  String get startExploring;

  /// No description provided for @clearWishlist.
  ///
  /// In en, this message translates to:
  /// **'Clear Wishlist'**
  String get clearWishlist;

  /// No description provided for @clearWishlistConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your entire wishlist?'**
  String get clearWishlistConfirm;

  /// No description provided for @wishlistCleared.
  ///
  /// In en, this message translates to:
  /// **'Wishlist cleared'**
  String get wishlistCleared;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get titleRequired;

  /// No description provided for @titleTooShort.
  ///
  /// In en, this message translates to:
  /// **'Title is too short'**
  String get titleTooShort;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title is too long'**
  String get titleTooLong;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get descriptionRequired;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get descriptionTooShort;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a price'**
  String get priceRequired;

  /// No description provided for @priceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get priceInvalid;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get addressRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a city'**
  String get cityRequired;

  /// No description provided for @stateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a state'**
  String get stateRequired;

  /// No description provided for @zipRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a ZIP code'**
  String get zipRequired;

  /// No description provided for @zipInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid ZIP code'**
  String get zipInvalid;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneInvalid;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// No description provided for @selectAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image'**
  String get selectAtLeastOneImage;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviews;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @advancedSearch.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advancedSearch;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @cityOrAddress.
  ///
  /// In en, this message translates to:
  /// **'City or Address'**
  String get cityOrAddress;

  /// No description provided for @keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get keywords;

  /// No description provided for @minimumRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum Rating'**
  String get minimumRating;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @searchProperties.
  ///
  /// In en, this message translates to:
  /// **'Search Properties'**
  String get searchProperties;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @otpVerification.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @maxImagesExceeded.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} images allowed'**
  String maxImagesExceeded(Object count);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @addToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Add to Wishlist'**
  String get addToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from Wishlist'**
  String get removeFromWishlist;

  /// No description provided for @shareProperty.
  ///
  /// In en, this message translates to:
  /// **'Share Property'**
  String get shareProperty;

  /// No description provided for @contactOwner.
  ///
  /// In en, this message translates to:
  /// **'Contact Owner'**
  String get contactOwner;

  /// No description provided for @reportProperty.
  ///
  /// In en, this message translates to:
  /// **'Report Property'**
  String get reportProperty;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @readAllReviews.
  ///
  /// In en, this message translates to:
  /// **'Read All Reviews'**
  String get readAllReviews;

  /// No description provided for @bookingPending.
  ///
  /// In en, this message translates to:
  /// **'Booking Pending'**
  String get bookingPending;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking Cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Booking Completed'**
  String get bookingCompleted;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminNotifications.
  ///
  /// In en, this message translates to:
  /// **'Admin Notifications'**
  String get adminNotifications;

  /// No description provided for @highServerLoad.
  ///
  /// In en, this message translates to:
  /// **'High server load detected'**
  String get highServerLoad;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @newUserReports.
  ///
  /// In en, this message translates to:
  /// **'new user reports'**
  String get newUserReports;

  /// No description provided for @systemBackupCompleted.
  ///
  /// In en, this message translates to:
  /// **'System backup completed'**
  String get systemBackupCompleted;

  /// No description provided for @hourAgo.
  ///
  /// In en, this message translates to:
  /// **'hour ago'**
  String get hourAgo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dynamicPricing.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Pricing'**
  String get dynamicPricing;

  /// No description provided for @priceOptimization.
  ///
  /// In en, this message translates to:
  /// **'Price Optimization'**
  String get priceOptimization;

  /// No description provided for @marketAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Market Analysis'**
  String get marketAnalysis;

  /// No description provided for @demandForecast.
  ///
  /// In en, this message translates to:
  /// **'Demand Forecast'**
  String get demandForecast;

  /// No description provided for @competitorAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Competitor Analysis'**
  String get competitorAnalysis;

  /// No description provided for @seasonalTrends.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Trends'**
  String get seasonalTrends;

  /// No description provided for @recommendedPrice.
  ///
  /// In en, this message translates to:
  /// **'Recommended Price'**
  String get recommendedPrice;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get currentPrice;

  /// No description provided for @potentialIncrease.
  ///
  /// In en, this message translates to:
  /// **'Potential Increase'**
  String get potentialIncrease;

  /// No description provided for @applyRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Apply Recommendation'**
  String get applyRecommendation;

  /// No description provided for @priceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Price updated successfully!'**
  String get priceUpdated;

  /// No description provided for @smartRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Smart Recommendations'**
  String get smartRecommendations;

  /// No description provided for @personalizedForYou.
  ///
  /// In en, this message translates to:
  /// **'Personalized for You'**
  String get personalizedForYou;

  /// No description provided for @basedOnPreferences.
  ///
  /// In en, this message translates to:
  /// **'Based on your preferences and search history'**
  String get basedOnPreferences;

  /// No description provided for @trendingNow.
  ///
  /// In en, this message translates to:
  /// **'Trending Now'**
  String get trendingNow;

  /// No description provided for @popularThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Popular this week in your area'**
  String get popularThisWeek;

  /// No description provided for @similarProperties.
  ///
  /// In en, this message translates to:
  /// **'Similar Properties'**
  String get similarProperties;

  /// No description provided for @basedOnViewed.
  ///
  /// In en, this message translates to:
  /// **'Based on properties you\'ve viewed'**
  String get basedOnViewed;

  /// No description provided for @priceDrops.
  ///
  /// In en, this message translates to:
  /// **'Price Drops'**
  String get priceDrops;

  /// No description provided for @recentPriceReductions.
  ///
  /// In en, this message translates to:
  /// **'Recent price reductions you might like'**
  String get recentPriceReductions;

  /// No description provided for @newListings.
  ///
  /// In en, this message translates to:
  /// **'New Listings'**
  String get newListings;

  /// No description provided for @freshProperties.
  ///
  /// In en, this message translates to:
  /// **'Fresh properties matching your criteria'**
  String get freshProperties;

  /// No description provided for @refreshRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Refresh Recommendations'**
  String get refreshRecommendations;

  /// No description provided for @recommendationsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recommendations updated!'**
  String get recommendationsUpdated;

  /// No description provided for @splitPayment.
  ///
  /// In en, this message translates to:
  /// **'Split Payment'**
  String get splitPayment;

  /// No description provided for @paymentSplitting.
  ///
  /// In en, this message translates to:
  /// **'Payment Splitting'**
  String get paymentSplitting;

  /// No description provided for @splitBetweenGuests.
  ///
  /// In en, this message translates to:
  /// **'Split between guests'**
  String get splitBetweenGuests;

  /// No description provided for @addGuest.
  ///
  /// In en, this message translates to:
  /// **'Add Guest'**
  String get addGuest;

  /// No description provided for @guestEmail.
  ///
  /// In en, this message translates to:
  /// **'Guest Email'**
  String get guestEmail;

  /// No description provided for @shareAmount.
  ///
  /// In en, this message translates to:
  /// **'Share Amount'**
  String get shareAmount;

  /// No description provided for @sendInvitations.
  ///
  /// In en, this message translates to:
  /// **'Send Invitations'**
  String get sendInvitations;

  /// No description provided for @paymentInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'Payment invitations sent successfully!'**
  String get paymentInvitationsSent;

  /// No description provided for @paymentSplit.
  ///
  /// In en, this message translates to:
  /// **'Payment Split'**
  String get paymentSplit;

  /// No description provided for @yourShare.
  ///
  /// In en, this message translates to:
  /// **'Your Share'**
  String get yourShare;

  /// No description provided for @totalSplit.
  ///
  /// In en, this message translates to:
  /// **'Total Split'**
  String get totalSplit;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @completedPayments.
  ///
  /// In en, this message translates to:
  /// **'Completed Payments'**
  String get completedPayments;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment completed!'**
  String get paymentCompleted;

  /// No description provided for @roleSwitch.
  ///
  /// In en, this message translates to:
  /// **'Role Switch'**
  String get roleSwitch;

  /// No description provided for @switchToOwner.
  ///
  /// In en, this message translates to:
  /// **'Switch to Owner'**
  String get switchToOwner;

  /// No description provided for @switchToSeeker.
  ///
  /// In en, this message translates to:
  /// **'Switch to Seeker'**
  String get switchToSeeker;

  /// No description provided for @currentRole.
  ///
  /// In en, this message translates to:
  /// **'Current Role'**
  String get currentRole;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch Role'**
  String get switchRole;

  /// No description provided for @roleSwitched.
  ///
  /// In en, this message translates to:
  /// **'Role switched successfully!'**
  String get roleSwitched;

  /// No description provided for @systemOverview.
  ///
  /// In en, this message translates to:
  /// **'System Overview'**
  String get systemOverview;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @activeListings.
  ///
  /// In en, this message translates to:
  /// **'Active Listings'**
  String get activeListings;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @viewAllUsers.
  ///
  /// In en, this message translates to:
  /// **'View All Users'**
  String get viewAllUsers;

  /// No description provided for @manageListings.
  ///
  /// In en, this message translates to:
  /// **'Manage Listings'**
  String get manageListings;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReports;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @recentUsers.
  ///
  /// In en, this message translates to:
  /// **'Recent Users'**
  String get recentUsers;

  /// No description provided for @viewAllUsersAction.
  ///
  /// In en, this message translates to:
  /// **'View All Users'**
  String get viewAllUsersAction;

  /// No description provided for @listingManagement.
  ///
  /// In en, this message translates to:
  /// **'Listing Management'**
  String get listingManagement;

  /// No description provided for @recentListings.
  ///
  /// In en, this message translates to:
  /// **'Recent Listings'**
  String get recentListings;

  /// No description provided for @viewAllListings.
  ///
  /// In en, this message translates to:
  /// **'View All Listings'**
  String get viewAllListings;

  /// No description provided for @systemHealth.
  ///
  /// In en, this message translates to:
  /// **'System Health'**
  String get systemHealth;

  /// No description provided for @serverStatus.
  ///
  /// In en, this message translates to:
  /// **'Server Status'**
  String get serverStatus;

  /// No description provided for @databaseStatus.
  ///
  /// In en, this message translates to:
  /// **'Database Status'**
  String get databaseStatus;

  /// No description provided for @apiStatus.
  ///
  /// In en, this message translates to:
  /// **'API Status'**
  String get apiStatus;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @operational.
  ///
  /// In en, this message translates to:
  /// **'Operational'**
  String get operational;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @checkAvailability.
  ///
  /// In en, this message translates to:
  /// **'Check availability'**
  String get checkAvailability;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'en',
        'es',
        'fr',
        'gu',
        'hi',
        'mr',
        'pt',
        'ru',
        'ta',
        'te',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
