import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../settings/data/language_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseData = ref.watch(categoryExpensesProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('analytics', lang))),
      body: expenseData.when(
        data: (data) {
          if (data.isEmpty || data.values.every((val) => val == 0)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(AppStrings.get('no_expenses', lang), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          // Sort categories by amount (High to Low)
          final sortedEntries = data.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Calculate Total for percentage
          final totalExpense = sortedEntries.fold(0.0, (sum, item) => sum + item.value);

          // Colors for the chart
          final List<Color> colors = [
            Colors.blue, Colors.red, Colors.orange, Colors.green, Colors.purple, Colors.teal, Colors.amber
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Title
                Text(
                  AppStrings.get('expense_breakdown', lang), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)
                ),
                const SizedBox(height: 30),

                // --- PIE CHART ---
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(sortedEntries.length, (i) {
                        final entry = sortedEntries[i];
                        final color = colors[i % colors.length];
                        final percentage = (entry.value / totalExpense * 100).toStringAsFixed(1);
                        
                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: '$percentage%',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // --- LEGEND (LIST) ---
                ...List.generate(sortedEntries.length, (i) {
                  final entry = sortedEntries[i];
                  final color = colors[i % colors.length];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: color, radius: 8),
                      title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text("৳ ${entry.value.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}