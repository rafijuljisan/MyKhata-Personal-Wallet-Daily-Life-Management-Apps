import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityNotifier extends Notifier<bool> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  bool build() {
    return false; 
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.containsKey('app_pin');
  }

  Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('app_pin');
    return storedPin == inputPin;
  }

  Future<void> setPinWithRecovery(String newPin, String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', newPin);
    await prefs.setString('sec_question', question);
    await prefs.setString('sec_answer', answer.toLowerCase().trim());
    state = true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_pin');
    await prefs.remove('sec_question');
    await prefs.remove('sec_answer');
    state = false;
  }

  Future<String?> getRecoveryQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sec_question');
  }

  Future<bool> verifyRecoveryAnswer(String inputAnswer) async {
    final prefs = await SharedPreferences.getInstance();
    final storedAnswer = prefs.getString('sec_answer');
    return storedAnswer == inputAnswer.toLowerCase().trim();
  }

  // --- FIXED BIOMETRIC AUTH (Version 3.0.0+ Syntax) ---
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      
      if (!isAvailable || !isDeviceSupported) return false;
      
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock MyKhata',
        options: AuthenticationOptions( // Remove 'const' here
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      print("Biometric Error: $e");
      return false;
    }
  }
}

final securityProvider = NotifierProvider<SecurityNotifier, bool>(() {
  return SecurityNotifier();
});