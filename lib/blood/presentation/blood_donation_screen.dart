import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_khata/src/data/database.dart'; // Ensure this import is correct for your project structure
import 'package:my_khata/blood/data/blood_donation_repository.dart';

class BloodDonationScreen extends ConsumerStatefulWidget {
  const BloodDonationScreen({super.key});

  @override
  ConsumerState<BloodDonationScreen> createState() => _BloodDonationScreenState();
}

class _BloodDonationScreenState extends ConsumerState<BloodDonationScreen> {
  
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(bloodStatsProvider);
final historyAsync = ref.watch(bloodDonationsListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        title: const Text("Blood Bank"),
        backgroundColor: Colors.red, // Theme color for this feature
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 1. HERO SECTION (Progress & Stats) ---
          Container(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 10),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: statsAsync.when(
              data: (stats) => Column(
                children: [
                  // Circular Progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: stats.isEligible ? 1.0 : stats.progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.red.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Column(
                        children: [
                          if (stats.isEligible)
                             const Icon(Icons.favorite, color: Colors.white, size: 40)
                          else
                            Text(
                              "${stats.daysRemaining}",
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          Text(
                            stats.isEligible ? "Ready to\nDonate" : "Days Left",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.2),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Row (Like your Dashboard Summary)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Total Given", "${stats.totalDonations} times"),
                      Container(height: 30, width: 1, color: Colors.white24),
                      _buildStatItem("Next Date", stats.nextEligibleDate == null ? "Now" : DateFormat('dd MMM').format(stats.nextEligibleDate!)),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 150, child: Center(child: CircularProgressIndicator(color: Colors.white))),
              error: (e, s) => const Text("Could not load stats", style: TextStyle(color: Colors.white)),
            ),
          ),

          const SizedBox(height: 16),

          // --- 2. LIST HEADER ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  "Donation History",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey.shade800
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // --- 3. DONATION LIST ---
          Expanded(
            child: historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "No donations recorded yet.",
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.bloodtype, color: Colors.red),
                        ),
                        title: Text(
                          DateFormat('dd MMMM yyyy').format(item.donateDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.location != null && item.location!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.place, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(item.location!, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            if (item.patientName != null && item.patientName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text("Patient: ${item.patientName}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _confirmDelete(context, item.id),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // --- HELPER WIDGETS & METHODS ---

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final locationController = TextEditingController();
    final patientController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.red.shade50, radius: 16, child: const Icon(Icons.add, color: Colors.red, size: 20)),
                const SizedBox(width: 10),
                const Text("Add Donation"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Location Input
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Location / Hospital",
                      hintText: "e.g. Dhaka Medical",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.local_hospital_outlined, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Patient Input
                  TextField(
                    controller: patientController,
                    decoration: InputDecoration(
                      labelText: "Patient Name (Optional)",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Colors.red),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.red),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Donation Date", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              Text(DateFormat('dd MMMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(bloodRepositoryProvider.notifier).addDonation(
                    selectedDate,
                    locationController.text.trim(),
                    patientController.text.trim(),
                    );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save Record"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text("Are you sure you want to remove this donation from your history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              ref.read(bloodRepositoryProvider.notifier).deleteDonation(id);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}