import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'pharmacist_home_screen.dart';
import 'doctor_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const route = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final _opNumberController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureAccessCode = true;
  String _selectedRole = 'patient';
  String? _selectedGender;

  // Access code for pharmacist registration
  static const String _pharmacistAccessCode = 'PHARMA2026';
  static const String _doctorAccessCode = 'DOCTOR2026';

  static const List<Map<String, String>> _roles = [
    {'value': 'patient', 'label': 'Patient'},
    {'value': 'pharmacist', 'label': 'Pharmacist'},
    {'value': 'doctor', 'label': 'Doctor'},
  ];

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _accessCodeController.dispose();
    _opNumberController.dispose();
    super.dispose();
  }

  void _navigateByRole(String role) {
    String route;
    switch (role) {
      case 'pharmacist':
        route = PharmacistHomeScreen.route;
        break;
      case 'doctor':
        route = DoctorHomeScreen.route;
        break;
      default:
        route = HomeScreen.route;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate access code for pharmacist role
    if (_selectedRole == 'pharmacist') {
      if (_accessCodeController.text.trim() != _pharmacistAccessCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid access code'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedRole == 'doctor') {
      if (_accessCodeController.text.trim() != _doctorAccessCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid access code for Doctor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    try {
      final age = int.tryParse(_ageController.text.trim());
      await auth.signup(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        role: _selectedRole,
        age: age,
        gender: _selectedGender,
        opNumber: _opNumberController.text.trim().isNotEmpty ? _opNumberController.text.trim() : null,
      );
      if (!mounted) return;
      _navigateByRole(_selectedRole);
    } catch (e) {
      if (!mounted) return;
      String message = 'Signup failed';
      if (e.toString().contains('email-already-in-use')) {
        message = 'An account with this email already exists';
      } else if (e.toString().contains('weak-password')) {
        message = 'Password is too weak';
      } else if (e.toString().contains('invalid-email')) {
        message = 'Invalid email format';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    // Validate access code for Doctor/Pharmacist
    if (_selectedRole == 'pharmacist') {
      if (_accessCodeController.text != _pharmacistAccessCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Pharmacist Access Code'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_selectedRole == 'doctor') {
      if (_accessCodeController.text != _doctorAccessCode) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid Doctor Access Code'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.signInWithGoogle(role: _selectedRole);
      if (!mounted) return;
      _navigateByRole(auth.user?.role ?? _selectedRole);
    } catch (e) {
      if (!mounted) return;
      String message = 'Sign in failed';
      if (e.toString().contains('cancelled')) {
        message = 'Sign in was cancelled';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/lung_logo.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join RespiriCare',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name field
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age and Gender Row
                Row(
                  children: [
                    // Age field
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Age (optional)',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 1 || age > 120) {
                              return 'Invalid age';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gender field
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _genders
                            .map((g) => DropdownMenuItem(
                                  value: g.toLowerCase(),
                                  child: Text(
                                    g,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // OP Number field - only visible for patients
                if (_selectedRole == 'patient') ...[
                  TextFormField(
                    controller: _opNumberController,
                    decoration: InputDecoration(
                      labelText: 'OP Number (optional)',
                      hintText: 'Outpatient registration number',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                ],

                // Role Dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Sign up as',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _roles
                      .map((role) => DropdownMenuItem(
                            value: role['value'],
                            child: Text(
                              role['label']!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value ?? 'patient';
                      // Clear access code when switching away from pharmacist or doctor
                      if (_selectedRole != 'pharmacist' && _selectedRole != 'doctor') {
                        _accessCodeController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Access Code field - only visible for pharmacist or doctor role
                if (_selectedRole == 'pharmacist' || _selectedRole == 'doctor')
                  TextFormField(
                    controller: _accessCodeController,
                    decoration: InputDecoration(
                      labelText: 'Access Code',
                      hintText: _selectedRole == 'pharmacist' 
                          ? 'Enter pharmacist access code' 
                          : 'Enter doctor access code',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureAccessCode ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureAccessCode = !_obscureAccessCode);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscureAccessCode,
                    validator: (value) {
                      if (_selectedRole == 'pharmacist' || _selectedRole == 'doctor') {
                        if (value == null || value.isEmpty) {
                          return 'Access code is required for ${_selectedRole}';
                        }
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 24),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : _signup,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Sign Up'),
                  ),
                ),

                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _signInWithGoogle,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login link
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            LoginScreen.route,
                          ),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
