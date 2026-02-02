/// App-wide constants for RespiriCare
/// Centralized configuration for branding, strings, and values

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'RespiriCare';
  static const String appVersion = '1.0.1';
  static const String appDescription = 'Your Complete Respiratory Care Companion';
  static const String appTagline = 'Breathe Better, Live Better';

  // Contact & Support
  static const String supportEmail = 'support@respiricare.com';
  static const String privacyPolicyUrl = 'https://respiricare.com/privacy';
  static const String termsOfServiceUrl = 'https://respiricare.com/terms';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Dimensions
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
  static const int otpLength = 6;
}

/// Error messages for user-friendly display
class AppErrors {
  AppErrors._();

  static const String noInternet = 'No internet connection. Please check your network and try again.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String serverError = 'Something went wrong. Please try again later.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String authFailed = 'Authentication failed. Please check your credentials.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword = 'Password must be at least 6 characters long.';
  static const String emailInUse = 'This email is already registered.';
  static const String userNotFound = 'No account found with this email.';
  static const String wrongPassword = 'Incorrect password. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
}

/// Success messages
class AppSuccess {
  AppSuccess._();

  static const String loginSuccess = 'Welcome back!';
  static const String signupSuccess = 'Account created successfully!';
  static const String passwordReset = 'Password reset email sent. Check your inbox.';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String medicationLogged = 'Medication logged successfully!';
  static const String reminderSet = 'Reminder set successfully!';
  static const String dataSaved = 'Data saved successfully!';
}

/// Loading messages
class AppLoading {
  AppLoading._();

  static const String pleaseWait = 'Please wait...';
  static const String loading = 'Loading...';
  static const String signingIn = 'Signing in...';
  static const String creatingAccount = 'Creating account...';
  static const String sendingEmail = 'Sending email...';
  static const String savingData = 'Saving...';
  static const String refreshing = 'Refreshing...';
}
