import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'pharmacist_home_screen.dart';
import 'signup_screen.dart';

class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key});

  static const route = '/';

  void _navigateByRole(BuildContext context, String role) {
    String route;
    switch (role) {
      case 'pharmacist':
        route = PharmacistHomeScreen.route;
        break;
      case 'admin':
        route = AdminHomeScreen.route;
        break;
      default:
        route = HomeScreen.route;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show loading while checking for existing session
    if (auth.isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/lung_logo.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Auto-navigate if already logged in
    if (auth.isLoggedIn) {
      Future.microtask(() {
        _navigateByRole(context, auth.user?.role ?? 'patient');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lung Logo with Caring Hands
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2962FF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/lung_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'RespiriCare',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2962FF),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Breathe Better, Live Better',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, LoginScreen.route),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    SignupScreen.route,
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



