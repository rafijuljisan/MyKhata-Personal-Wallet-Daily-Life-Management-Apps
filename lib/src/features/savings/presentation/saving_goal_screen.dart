import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/saving_repository.dart';
import '../../../data/database.dart'; // For SavingGoal type

class SavingGoalScreen extends ConsumerStatefulWidget {
  const SavingGoalScreen({super.key});

  @override
  ConsumerState<SavingGoalScreen> createState() => _SavingGoalScreenState();
}

class _SavingGoalScreenState extends ConsumerState<SavingGoalScreen> {
  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Savings Goals")),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Text("No goals yet.\nStart saving for a Dream!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) => _GoalCard(goal: goals[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        label: const Text("New Goal"),
        icon: const Icon(Icons.flag),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Set New Goal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Goal Name (e.g. Laptop)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Target Amount", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(selectedDate == null ? "Target Date (Optional)" : DateFormat('dd MMM yyyy').format(selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (date != null) setDialogState(() => selectedDate = date);
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                ref.read(savingRepositoryProvider.notifier).addGoal(
                  name: nameCtrl.text,
                  targetAmount: double.parse(amountCtrl.text),
                  targetDate: selectedDate,
                );
                Navigator.pop(ctx);
              },
              child: const Text("Create Goal"),
            )
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final SavingGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (progress * 100).toStringAsFixed(1);
    final remaining = goal.targetAmount - goal.currentAmount;
    
    // Suggestion Logic
    String suggestion = "Keep going!";
    if (goal.targetDate != null && remaining > 0) {
      final daysLeft = goal.targetDate!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        final dailySave = remaining / daysLeft;
        suggestion = "Save ৳ ${dailySave.toStringAsFixed(0)} / day to reach goal on time.";
      } else {
        suggestion = "Target date passed.";
      }
    } else if (remaining <= 0) {
      suggestion = "Goal Reached! 🎉";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (goal.targetDate != null)
                        Text("Target: ${DateFormat('dd MMM yyyy').format(goal.targetDate!)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => ref.read(savingRepositoryProvider.notifier).deleteGoal(goal.id),
                )
              ],
            ),
            const SizedBox(height: 15),
            
            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: progress >= 1 ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 10),
                Text("$percentage%", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Saved: ৳ ${goal.currentAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text("Target: ৳ ${goal.targetAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            
            const Divider(height: 20),
            Text("💡 $suggestion", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700])),
            const SizedBox(height: 10),
            
            if (remaining > 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Add Savings"),
                  onPressed: () => _showDepositDialog(context, ref),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    bool deductFromWallet = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Add to ${goal.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount", prefixText: "৳ ", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: deductFromWallet, 
                    onChanged: (val) => setDialogState(() => deductFromWallet = val!),
                  ),
                  const Expanded(child: Text("Deduct from Wallet Balance?", style: TextStyle(fontSize: 12))),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text) ?? 0;
                if (amt > 0) {
                  ref.read(savingRepositoryProvider.notifier).depositToGoal(
                    goalId: goal.id,
                    amount: amt,
                    createTransaction: deductFromWallet,
                    goalName: goal.name,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Deposit"),
            )
          ],
        ),
      ),
    );
  }
}