import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Need this for saving settings
import '../../../data/database.dart'; // Import Database for Factory Reset
import '../../dashboard/presentation/dashboard_screen.dart'; // Import Dashboard for navigation
import '../data/backup_service.dart';
import '../data/language_provider.dart'; 
import '../data/shop_profile_provider.dart'; 
import '../data/security_service.dart'; 
import 'pin_screen.dart'; 
import '../../categories/presentation/category_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoBackupEnabled = true;
  double _retentionDays = 30;
  String? _lastBackupTime; // New State for Last Backup

  @override
  void initState() {
    super.initState();
    ref.read(shopProfileProvider.notifier).loadProfile();
    ref.read(securityProvider.notifier).loadState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? true;
      _retentionDays = (prefs.getInt('backup_retention_days') ?? 30).toDouble();
      // Load last backup time
      final lastTs = prefs.getString('last_backup_timestamp');
      if (lastTs != null) {
        final date = DateTime.tryParse(lastTs);
        if (date != null) {
          _lastBackupTime = DateFormat('dd MMM yyyy, hh:mm a').format(date);
        }
      }
    });
  }

  Future<void> _saveBackupSettings(bool enabled, double days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_backup_enabled', enabled);
    await prefs.setInt('backup_retention_days', days.toInt());
    setState(() {
      _autoBackupEnabled = enabled;
      _retentionDays = days;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final profile = ref.watch(shopProfileProvider);
    final hasPin = ref.watch(securityProvider); 

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('settings', currentLang))),
      body: ListView( 
        padding: const EdgeInsets.all(20.0),
        children: [
          // --- LANGUAGE ---
          const Text("Language / ভাষা", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text("English"),
                selected: currentLang == 'en',
                onSelected: (val) => ref.read(languageProvider.notifier).setLanguage('en'),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("বাংলা"),
                selected: currentLang == 'bn',
                onSelected: (val) => ref.read(languageProvider.notifier).setLanguage('bn'),
              ),
            ],
          ),
          const Divider(height: 30),

          // --- APP SECURITY ---
          const Text("App Security", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("App Lock (PIN)", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(hasPin ? "Tap to Remove PIN" : "Tap to Set PIN"),
            value: hasPin,
            activeColor: Colors.blue,
            onChanged: (val) {
              if (val) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen(isSetup: true)));
              } else {
                ref.read(securityProvider.notifier).removePin();
              }
            },
          ),
          const Divider(height: 30),

          const SizedBox(height: 20), // Add some spacing

          _SettingsTile(
            icon: Icons.category,
            title: "Manage Categories",
            subtitle: "Add, edit or delete income/expense categories",
            color: Colors.purple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
            },
          ),

          const Divider(height: 30), // Existing Divider

          // --- BUSINESS PROFILE ---
          const Text("Business Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (profile.address.isNotEmpty) Text(profile.address, style: const TextStyle(color: Colors.grey)),
                  if (profile.phone.isNotEmpty) Text(profile.phone, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, profile),
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Shop Info"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 30),

          // --- BACKUP SETTINGS (UPDATED) ---
          Text(AppStrings.get('backup', currentLang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),
          
          // Auto Backup Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Auto Backup to Phone", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Automatically save backup when app opens"),
                if (_lastBackupTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("Last Backup: $_lastBackupTime", style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            value: _autoBackupEnabled,
            activeColor: Colors.green,
            onChanged: (val) => _saveBackupSettings(val, _retentionDays),
          ),

          // Retention Slider (Only if enabled)
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 10),
            Text("Keep backups for: ${_retentionDays.toInt()} days", style: const TextStyle(color: Colors.grey)),
            Slider(
              value: _retentionDays,
              min: 7,
              max: 60,
              divisions: 4, 
              label: "${_retentionDays.toInt()} Days",
              activeColor: Colors.green,
              onChanged: (val) => _saveBackupSettings(_autoBackupEnabled, val),
            ),
          ],

          const SizedBox(height: 20),
          
          // Manual Actions
          _SettingsTile(
            icon: Icons.share,
            title: "Share Backup File",
            subtitle: "Send to WhatsApp or Email",
            color: Colors.blue,
            onTap: () async {
              await ref.read(backupServiceProvider).createBackup();
            },
          ),
          
          const SizedBox(height: 16),

          _SettingsTile(
            icon: Icons.add_to_drive,
            title: "Backup to Google Drive",
            subtitle: "Upload manually to cloud",
            color: Colors.indigo,
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connecting to Google Drive...")));
              final success = await ref.read(backupServiceProvider).uploadToDrive();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? "Backup Uploaded!" : "Upload Failed."),
                  backgroundColor: success ? Colors.green : Colors.blue,
                ));
              }
            },
          ),

          const SizedBox(height: 16),

          _SettingsTile(
            icon: Icons.cloud_download,
            title: AppStrings.get('restore', currentLang),
            subtitle: "Import data from file",
            color: Colors.orange,
            onTap: () => _confirmRestore(context, ref),
          ),

          const Divider(height: 40),

          // --- SUPPORT & DANGER ZONE ---
          const Text("Support & Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.email,
            title: "Contact Support",
            subtitle: "Report issues or suggest features",
            color: Colors.teal,
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Contact Us"),
                  content: const SelectableText("Email: rafijuljisan@gmail.com\nPhone: +880 01957-850240"),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          _SettingsTile(
            icon: Icons.delete_forever,
            title: "Erase All Data (Factory Reset)",
            subtitle: "Permanently delete everything",
            color: Colors.red,
            onTap: () => _confirmFactoryReset(context, ref),
          ),

          const SizedBox(height: 40),
          const Center(child: Text("MyKhata v1.3.0", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // --- Helper Dialogs ---
  void _showEditProfileDialog(BuildContext context, ShopProfile current) {
    final nameCtrl = TextEditingController(text: current.name);
    final addressCtrl = TextEditingController(text: current.address);
    final phoneCtrl = TextEditingController(text: current.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Shop Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Shop Name")),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Phone")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              ref.read(shopProfileProvider.notifier).updateProfile(
                nameCtrl.text, addressCtrl.text, phoneCtrl.text
              );
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Warning!"),
        content: const Text("This will DELETE current data. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(backupServiceProvider).restoreBackup();
            },
            child: const Text("RESTORE"),
          ),
        ],
      ),
    );
  }

  void _confirmFactoryReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Factory Reset", style: TextStyle(color: Colors.red)),
        content: const Text("Are you ABSOLUTELY sure?\n\nThis will delete:\n- All Transactions\n- All Contacts\n- Budgets & Goals\n- App Lock PIN\n\nThis action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _performFactoryReset(ref);
            },
            child: const Text("ERASE EVERYTHING"),
          ),
        ],
      ),
    );
  }

  Future<void> _performFactoryReset(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final prefs = await SharedPreferences.getInstance();

    // 1. Clear DB (Delete all rows)
    await db.transaction(() async {
      await db.delete(db.transactions).go();
      await db.delete(db.recurringTransactions).go();
      await db.delete(db.budgets).go();
      await db.delete(db.savingGoals).go();
      await db.delete(db.parties).go();
      await db.delete(db.categories).go();
      try { await db.delete(db.shoppingItems).go(); } catch (_) {} // Optional tables
      try { await db.delete(db.bikeLogs).go(); } catch (_) {}
    });

    // 2. Clear Prefs (Resets PIN, Profile, etc.)
    await prefs.clear();

    // 3. Reset UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("App Reset Successfully. Restarting...")));
      await Future.delayed(const Duration(seconds: 2));
      
      // Navigate to Dashboard (which will act as fresh start since AuthGuard checks prefs)
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const DashboardScreen()), 
        (route) => false
      );
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}