import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/budget_repository.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetStatusProvider(_selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Budget"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              // Simple month picker logic (can be improved)
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _selectedMonth = date;
                });
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Month Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: budgetAsync.when(
              data: (items) {
                if (items.isEmpty) return const Center(child: Text("No expense categories found."));
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _BudgetCard(
                      item: item, 
                      onSetLimit: () => _showSetLimitDialog(context, item),
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

  void _showSetLimitDialog(BuildContext context, BudgetStatus item) {
    final controller = TextEditingController(text: item.limit > 0 ? item.limit.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set Budget: ${item.category.name}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Limit Amount (৳)", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              ref.read(budgetRepositoryProvider.notifier).setBudget(
                categoryId: item.category.id,
                limitAmount: amount,
                month: _selectedMonth.month,
                year: _selectedMonth.year,
              );
              Navigator.pop(ctx);
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final BudgetStatus item;
  final VoidCallback onSetLimit;

  const _BudgetCard({required this.item, required this.onSetLimit});

  @override
  Widget build(BuildContext context) {
    Color progressColor = Colors.green;
    if (item.isNearLimit) progressColor = Colors.orange;
    if (item.isOverBudget) progressColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                  onPressed: onSetLimit,
                )
              ],
            ),
            
            if (item.limit > 0) ...[
              LinearProgressIndicator(
                value: item.progress,
                color: progressColor,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Spent: ৳ ${item.spent.toStringAsFixed(0)}", 
                    style: TextStyle(color: item.isOverBudget ? Colors.red : Colors.black87)
                  ),
                  Text(
                    "Limit: ৳ ${item.limit.toStringAsFixed(0)}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              if (item.isNearLimit)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text("⚠️ Near Budget Limit!", style: TextStyle(color: Colors.orange, fontSize: 12)),
                ),
               if (item.isOverBudget)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text("🚨 Over Budget!", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Spent: ৳ ${item.spent.toStringAsFixed(0)}"),
                  TextButton(
                    onPressed: onSetLimit,
                    child: const Text("Set Limit"),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}