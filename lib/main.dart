import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/arrival_screen.dart';
import 'screens/disease_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manage_users_screen.dart';
import 'screens/missed_medications_screen.dart';
import 'screens/my_medications_screen.dart';
import 'screens/pharmacist_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/symptom_history_screen.dart';
import 'screens/symptom_log_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'RespiriCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Primary color scheme - Modern Purple/Violet
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            // Primary - Vibrant Indigo/Purple
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
            primaryContainer: Color(0xFFE0E7FF),
            onPrimaryContainer: Color(0xFF3730A3),
            // Secondary - Teal/Emerald
            secondary: Color(0xFF10B981),
            onSecondary: Colors.white,
            secondaryContainer: Color(0xFFD1FAE5),
            onSecondaryContainer: Color(0xFF065F46),
            // Tertiary - Amber/Orange
            tertiary: Color(0xFFF59E0B),
            onTertiary: Colors.white,
            tertiaryContainer: Color(0xFFFEF3C7),
            onTertiaryContainer: Color(0xFF92400E),
            // Error - Vibrant Red
            error: Color(0xFFEF4444),
            onError: Colors.white,
            errorContainer: Color(0xFFFEE2E2),
            onErrorContainer: Color(0xFFB91C1C),
            // Surface & Background - Subtle blue/purple tint for premium look
            surface: Color(0xFFFAFAFF),
            onSurface: Color(0xFF1F2937),
            surfaceContainerHighest: Color(0xFFF0F0FF),
            onSurfaceVariant: Color(0xFF6B7280),
            // Outline
            outline: Color(0xFFD1D5DB),
            outlineVariant: Color(0xFFE5E7EB),
            // Inverse
            inverseSurface: Color(0xFF1F2937),
            onInverseSurface: Colors.white,
            inversePrimary: Color(0xFFA5B4FC),
            // Misc
            shadow: Colors.black,
            scrim: Colors.black,
          ),
          useMaterial3: true,
          // AppBar Theme
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          // Scaffold Background - Subtle purple/blue tinted background
          scaffoldBackgroundColor: const Color(0xFFF5F5FF),
          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFAFAFF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF6B7280)),
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          // Card Theme
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: const Color(0xFFFAFAFF),
            shadowColor: const Color(0xFF6366F1).withAlpha(40),
            surfaceTintColor: Colors.transparent,
          ),
          // Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Filled Button Theme
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Outlined Button Theme
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              side: const BorderSide(color: Color(0xFF6366F1), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Text Button Theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Floating Action Button Theme
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: CircleBorder(),
          ),
          // Bottom Navigation Bar Theme
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF6366F1),
            unselectedItemColor: Color(0xFF9CA3AF),
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          // Navigation Bar Theme (Material 3)
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF6366F1).withAlpha(30),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                );
              }
              return const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Color(0xFF6366F1));
              }
              return const IconThemeData(color: Color(0xFF9CA3AF));
            }),
          ),
          // List Tile Theme
          listTileTheme: ListTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          // Chip Theme
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF3F4F6),
            selectedColor: const Color(0xFF6366F1),
            labelStyle: const TextStyle(fontSize: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Snack Bar Theme
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF1F2937),
            contentTextStyle: const TextStyle(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
          // Dialog Theme
          dialogTheme: DialogTheme(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titleTextStyle: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Divider Theme
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE5E7EB),
            thickness: 1,
            space: 1,
          ),
          // Switch Theme
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return Colors.white;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6366F1);
              }
              return const Color(0xFFD1D5DB);
            }),
          ),
          // Checkbox Theme
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6366F1);
              }
              return Colors.transparent;
            }),
            checkColor: WidgetStateProperty.all(Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Radio Theme
          radioTheme: RadioThemeData(
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6366F1);
              }
              return const Color(0xFF9CA3AF);
            }),
          ),
          // Progress Indicator Theme
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF6366F1),
            circularTrackColor: Color(0xFFE0E7FF),
          ),
          // Text Theme
          textTheme: const TextTheme(
            displayLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
            displayMedium: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
            displaySmall: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
            headlineLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
            titleLarge: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
            titleMedium: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
            titleSmall: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
            bodyLarge: TextStyle(color: Color(0xFF374151)),
            bodyMedium: TextStyle(color: Color(0xFF4B5563)),
            bodySmall: TextStyle(color: Color(0xFF6B7280)),
            labelLarge: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600),
            labelMedium: TextStyle(color: Color(0xFF6B7280)),
            labelSmall: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
        initialRoute: ArrivalScreen.route,
        routes: {
          ArrivalScreen.route: (_) => const ArrivalScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          SignupScreen.route: (_) => const SignupScreen(),
          HomeScreen.route: (_) => const HomeScreen(),
          ProfileScreen.route: (_) => const ProfileScreen(),
          PharmacistHomeScreen.route: (_) => const PharmacistHomeScreen(),
          AnalyticsScreen.route: (_) => const AnalyticsScreen(),
          ManageUsersScreen.route: (_) => const ManageUsersScreen(),
          DiseaseSelectionScreen.route: (_) => const DiseaseSelectionScreen(),
          MyMedicationsScreen.route: (_) => const MyMedicationsScreen(),
          SymptomLogScreen.route: (_) => const SymptomLogScreen(),
          SymptomHistoryScreen.route: (_) => const SymptomHistoryScreen(),
          SettingsScreen.route: (_) => const SettingsScreen(),
          ReportsScreen.route: (_) => const ReportsScreen(),
          CompleteProfileScreen.route: (_) => const CompleteProfileScreen(),
          MissedMedicationsScreen.route: (_) => const MissedMedicationsScreen(),
        },
      ),
    );
  }
}
