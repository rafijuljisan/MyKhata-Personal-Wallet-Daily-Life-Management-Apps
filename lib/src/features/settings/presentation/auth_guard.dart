import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'pin_screen.dart';
import '../data/security_service.dart';

class AuthGuard extends ConsumerStatefulWidget {
  const AuthGuard({super.key});

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Initialize the provider state
    await ref.read(securityProvider.notifier).loadState();
    
    // Check SharedPrefs directly for immediate decision
    final prefs = await SharedPreferences.getInstance();
    final hasPin = prefs.containsKey('app_pin');

    if (mounted) {
      if (hasPin) {
        // Go to PIN Screen (Unlock Mode)
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const PinScreen(isSetup: false))
        );
      } else {
        // Go to Dashboard directly
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DashboardScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.blue)),
    );
  }
}