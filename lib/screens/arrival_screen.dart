import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'pharmacist_home_screen.dart';
import 'signup_screen.dart';

class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key});

  static const route = '/';

  void _navigateByRole(BuildContext context, String role, bool needsProfileCompletion) {
    if (needsProfileCompletion) {
      Navigator.pushReplacementNamed(context, CompleteProfileScreen.route);
      return;
    }
    
    String route;
    switch (role) {
      case 'pharmacist':
        route = PharmacistHomeScreen.route;
        break;
      default:
        route = HomeScreen.route;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Gradient that adapts to theme or stays brand-consistent
    final backgroundGradient = LinearGradient(
      colors: isDark 
          ? [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.surface,
            ]
          : [
              theme.colorScheme.primary,
              Color(0xFF8B5CF6), // Keeping a slight gradient variation for visual interest
              Color(0xFFA78BFA),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Show loading while checking for existing session
    if (auth.isInitializing) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(color: theme.colorScheme.onPrimary),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white70, 
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Auto-navigate if already logged in
    if (auth.isLoggedIn) {
      Future.microtask(() {
        _navigateByRole(context, auth.user?.role ?? 'patient', auth.needsProfileCompletion);
      });
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.onPrimary),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'RespiriCare',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Breathe Better, Live Better',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  height: 54, // Slightly taller for touch targets
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, LoginScreen.route),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      SignupScreen.route,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




