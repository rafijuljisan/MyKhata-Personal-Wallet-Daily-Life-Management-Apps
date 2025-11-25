import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/bike_repository.dart';

class BikeScreen extends ConsumerWidget {
  const BikeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(bikeLogsProvider);
    final statsAsync = ref.watch(bikeStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("My Bike Manager")),
      body: Column(
        children: [
          // --- 1. DASHBOARD CARD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: statsAsync.when(
              data: (stats) {
                final mileage = stats['mileage'] as double;
                final currentKm = stats['current_km'] as double;
                final nextTask = stats['next_task'] as String;
                final remainingKm = stats['remaining_km'] as double;
                final isDue = stats['is_due'] as bool;

                return Column(
                  children: [
                    const Text("Average Mileage", style: TextStyle(color: Colors.white70)),
                    Text("${mileage.toStringAsFixed(1)} km/L", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatItem("Odometer", "${currentKm.toStringAsFixed(0)} km"),
                        // Dynamic Reminder Display
                        _StatItem(
                          "Next: $nextTask", 
                          isDue ? "DUE NOW!" : "${remainingKm.toStringAsFixed(0)} km left", 
                          isWarning: isDue
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (e, s) => const Text("Error loading stats", style: TextStyle(color: Colors.white)),
            ),
          ),

          // --- 2. ACTION BUTTONS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: _ActionButton(Icons.local_gas_station, "Fuel", Colors.orange, () => _showAddDialog(context, ref, 'FUEL'))),
                const SizedBox(width: 10),
                Expanded(child: _ActionButton(Icons.build, "Service/Oil", Colors.red, () => _showAddDialog(context, ref, 'SERVICE'))),
                const SizedBox(width: 10),
                Expanded(child: _ActionButton(Icons.settings_suggest, "Parts", Colors.teal, () => _showAddDialog(context, ref, 'PART'))),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(alignment: Alignment.centerLeft, child: Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ),

          // --- 3. HISTORY LIST ---
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) return const Center(child: Text("No records yet."));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    IconData icon;
                    Color color;
                    
                    switch(log.logType) {
                      case 'FUEL': icon = Icons.local_gas_station; color = Colors.orange; break;
                      case 'SERVICE': icon = Icons.build; color = Colors.red; break;
                      default: icon = Icons.settings; color = Colors.teal;
                    }

                    // Subtitle shows when it's due next
                    String dueInfo = "";
                    if (log.nextDueKm != null) dueInfo = " | Next: ${log.nextDueKm!.toStringAsFixed(0)} km";
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                        title: Text(log.logType == 'FUEL' ? "${log.quantity}L Fuel" : (log.note ?? log.logType), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${DateFormat('dd MMM').format(log.date)} • ${log.odometer.toStringAsFixed(0)} km$dueInfo"),
                        trailing: Text("৳ ${log.cost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        onLongPress: () {
                           showDialog(context: context, builder: (ctx) => AlertDialog(
                             title: const Text("Delete?"),
                             actions: [
                               TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                               TextButton(onPressed: () {
                                 ref.read(bikeRepositoryProvider.notifier).deleteLog(log.id);
                                 Navigator.pop(ctx);
                               }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
                             ],
                           ));
                        },
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
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String type) {
    final odoCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    
    // Inputs for variable intervals
    final intervalKmCtrl = TextEditingController(text: type == 'SERVICE' ? "1000" : ""); 
    final intervalMonthCtrl = TextEditingController(); 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add $type"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: odoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Current Odometer (km)")),
              const SizedBox(height: 10),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Cost (৳)")),
              const SizedBox(height: 10),
              
              if (type == 'FUEL')
                TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Fuel Quantity (Liters)")),
              
              if (type != 'FUEL') ...[
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note (e.g. Synthetic Oil, Air Filter)")),
                const SizedBox(height: 15),
                const Text("Set Reminder (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: intervalKmCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Change after (KM)", hintText: "e.g 1200 or 5000"))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: intervalMonthCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Or Months", hintText: "e.g 6"))),
                  ],
                ),
              ]
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (odoCtrl.text.isEmpty || costCtrl.text.isEmpty) return;
              
              final currentOdo = double.parse(odoCtrl.text);
              double? nextDueKm;
              DateTime? nextDueDate;

              // Calculate Targets
              if (type != 'FUEL') {
                 if (intervalKmCtrl.text.isNotEmpty) {
                   nextDueKm = currentOdo + double.parse(intervalKmCtrl.text);
                 }
                 if (intervalMonthCtrl.text.isNotEmpty) {
                   nextDueDate = DateTime.now().add(Duration(days: int.parse(intervalMonthCtrl.text) * 30));
                 }
              }
              
              ref.read(bikeRepositoryProvider.notifier).addLog(
                type: type,
                odometer: currentOdo,
                cost: double.parse(costCtrl.text),
                quantity: type == 'FUEL' ? double.tryParse(qtyCtrl.text) : null,
                note: noteCtrl.text,
                date: DateTime.now(),
                nextDueKm: nextDueKm,
                nextDueDate: nextDueDate,
              );
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;

  const _StatItem(this.label, this.value, {this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: isWarning ? Colors.redAccent : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color)),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}