import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/admin_home_screen.dart';
import 'screens/arrival_screen.dart';
import 'screens/disease_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/my_medications_screen.dart';
import 'screens/pharmacist_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/symptom_history_screen.dart';
import 'screens/symptom_log_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      ],
      child: MaterialApp(
        title: 'RespiriCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2962FF), // Vibrant purple-blue (electric)
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2962FF), width: 2),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
          AdminHomeScreen.route: (_) => const AdminHomeScreen(),
          DiseaseSelectionScreen.route: (_) => const DiseaseSelectionScreen(),
          MyMedicationsScreen.route: (_) => const MyMedicationsScreen(),
          SymptomLogScreen.route: (_) => const SymptomLogScreen(),
          SymptomHistoryScreen.route: (_) => const SymptomHistoryScreen(),
        },
      ),
    );
  }
}
