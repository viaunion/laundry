import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'splash/splash_screen.dart';
import 'home/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('AuthWrapper rebuild - isAuthenticated: ${authProvider.isAuthenticated}, user: ${authProvider.user?.uid}'); // Debug log
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const SplashScreen();
        }
      },
    );
  }
}