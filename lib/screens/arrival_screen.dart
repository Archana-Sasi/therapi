import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key});

  static const route = '/';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn) {
      Future.microtask(() {
        if (Navigator.canPop(context)) {
          Navigator.popAndPushNamed(context, HomeScreen.route);
        } else {
          Navigator.pushReplacementNamed(context, HomeScreen.route);
        }
      });
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.health_and_safety, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Therap',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
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


