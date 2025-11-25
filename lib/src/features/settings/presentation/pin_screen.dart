import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../data/security_service.dart';

class PinScreen extends ConsumerStatefulWidget {
  final bool isSetup; // true = Setting up new PIN, false = Unlocking

  const PinScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _input = "";
  String _title = "Enter PIN";

  @override
  void initState() {
    super.initState();
    if (widget.isSetup) {
      setState(() => _title = "Set New 4-Digit PIN");
    } else {
      // If unlocking, try Biometric immediately
      _tryBiometricAuth();
    }
  }

  // --- NEW: BIOMETRIC LOGIC ---
  Future<void> _tryBiometricAuth() async {
    // Wait a tiny bit for the screen to render first
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Call the security service
    final authenticated = await ref.read(securityProvider.notifier).authenticateWithBiometrics();
    
    if (authenticated && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void _onKeyPressed(String val) {
    if (_input.length < 4) {
      setState(() => _input += val);
      if (_input.length == 4) _submit();
    }
  }

  void _onDelete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  Future<void> _submit() async {
    if (widget.isSetup) {
      // Setup Mode: Ask for Recovery Question
      _showRecoverySetupDialog(_input);
    } else {
      // Unlock Mode: Verify PIN
      final isValid = await ref.read(securityProvider.notifier).verifyPin(_input);
      if (isValid) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() {
          _input = "";
          _title = "Wrong PIN! Try Again";
        });
      }
    }
  }

  // --- 1. SETUP DIALOG ---
  void _showRecoverySetupDialog(String newPin) {
    final questionCtrl = TextEditingController();
    final answerCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Recovery Question"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("If you forget your PIN, you can reset it using this question."),
            const SizedBox(height: 10),
            TextField(
              controller: questionCtrl,
              decoration: const InputDecoration(labelText: "Question (e.g. My first pet?)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: answerCtrl,
              decoration: const InputDecoration(labelText: "Answer", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _input = ""); 
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (questionCtrl.text.isEmpty || answerCtrl.text.isEmpty) return;

              await ref.read(securityProvider.notifier).setPinWithRecovery(
                newPin,
                questionCtrl.text,
                answerCtrl.text
              );

              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Lock Enabled!")));
              }
            },
            child: const Text("SAVE & LOCK"),
          ),
        ],
      ),
    );
  }

  // --- 2. FORGOT PIN DIALOG ---
  Future<void> _showForgotPinDialog() async {
    final question = await ref.read(securityProvider.notifier).getRecoveryQuestion();
    final answerCtrl = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Forgot PIN?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Question: ${question ?? 'No question set'}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: answerCtrl,
              decoration: const InputDecoration(labelText: "Enter Answer", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final isCorrect = await ref.read(securityProvider.notifier).verifyRecoveryAnswer(answerCtrl.text);
              if (isCorrect) {
                await ref.read(securityProvider.notifier).removePin();
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Removed! Stay Safe.")));
                }
              } else {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Wrong Answer!"), backgroundColor: Colors.blue)
                  );
                }
              }
            },
            child: const Text("RESET PIN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Fixed: Use Blue theme
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _input.length ? Colors.white : Colors.white30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 50),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  ...List.generate(9, (i) => _numBtn("${i + 1}")),
                  
                  // --- FINGERPRINT BUTTON (Visible if unlocking) ---
                  if (!widget.isSetup)
                    IconButton(
                      onPressed: _tryBiometricAuth,
                      icon: const Icon(Icons.fingerprint, size: 40, color: Colors.white),
                    )
                  else
                    const SizedBox(),

                  _numBtn("0"),
                  
                  IconButton(
                    onPressed: _onDelete,
                    icon: const Icon(Icons.backspace, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Forgot PIN Button
            if (!widget.isSetup)
              TextButton(
                onPressed: _showForgotPinDialog,
                child: const Text(
                  "Forgot PIN?",
                  style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline)
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _numBtn(String text) {
    return GestureDetector(
      onTap: () => _onKeyPressed(text),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}