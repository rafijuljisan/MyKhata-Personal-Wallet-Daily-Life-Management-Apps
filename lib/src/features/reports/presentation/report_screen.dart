import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../transactions/data/transaction_repository.dart';
import '../data/pdf_service.dart';
import '../../settings/data/language_provider.dart';
import '../../settings/data/shop_profile_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  // Filter State
  DateTimeRange? _selectedDateRange;
  String _filterType = 'ALL'; // Options: ALL, CASH_IN, CASH_OUT, DUE_GIVEN, DUE_RECEIVED

  @override
  void initState() {
    super.initState();
    // Load shop profile for the PDF header
    ref.read(shopProfileProvider.notifier).loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(allTransactionsProvider);
    final lang = ref.watch(languageProvider);
    final shopProfile = ref.watch(shopProfileProvider);

    // Helper to translate dropdown items
    String getLabel(String type) {
      switch(type) {
        case 'ALL': return lang == 'bn' ? 'সকল লেনদেন' : 'All Transactions';
        case 'CASH_IN': return AppStrings.get('cash_in', lang);
        case 'CASH_OUT': return AppStrings.get('cash_out', lang);
        case 'DUE_GIVEN': return AppStrings.get('add_due', lang); // Gave Baki
        case 'DUE_RECEIVED': return AppStrings.get('receive_due', lang); // Got Baki
        default: return type;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('reports', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. FILTER CARD ---
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Filter Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 16),
                    
                    // Date Range Picker
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: BorderSide(color: Colors.blue.shade200),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(primary: Colors.blue),
                              ),
                              child: child!,
                            );
                          }
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                        }
                      },
                      icon: Icon(Icons.date_range, color: Colors.blue[900]),
                      label: Text(
                        _selectedDateRange == null 
                          ? (lang == 'bn' ? "তারিখ নির্বাচন করুন (ঐচ্ছিক)" : "Select Date Range (Optional)")
                          : "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Transaction Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _filterType,
                      decoration: const InputDecoration(
                        labelText: "Transaction Type",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['ALL', 'CASH_IN', 'CASH_OUT', 'DUE_GIVEN', 'DUE_RECEIVED']
                          .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(getLabel(type), style: const TextStyle(fontSize: 14)),
                          )).toList(),
                      onChanged: (val) => setState(() => _filterType = val!),
                    ),
                    
                    // Clear Filters Button (Only shows if filters are active)
                    if (_selectedDateRange != null || _filterType != 'ALL')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                              _filterType = 'ALL';
                            });
                          },
                          icon: Icon(Icons.clear, size: 16, color: Colors.blue[900]),
                          label: Text("Clear Filters", style: TextStyle(color: Colors.blue)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- 2. DOWNLOAD SECTION ---
            const Icon(Icons.picture_as_pdf, size: 70, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              AppStrings.get('download_pdf', lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Generate a PDF based on the filters selected above.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),

            historyAsync.when(
              data: (data) => ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 4,
                ),
                onPressed: () {
                  // --- FILTERING LOGIC ---
                  final filteredData = data.where((item) {
                    // 1. Filter by Date
                    if (_selectedDateRange != null) {
                      final date = item.transaction.date;
                      final start = DateUtils.dateOnly(_selectedDateRange!.start);
                      // Add 1 day to end date to make it inclusive (up to 11:59 PM)
                      final end = DateUtils.dateOnly(_selectedDateRange!.end).add(const Duration(days: 1)); 
                      
                      if (date.isBefore(start) || date.isAfter(end) || date.isAtSameMomentAs(end)) {
                         return false;
                      }
                    }
                    // 2. Filter by Type
                    if (_filterType != 'ALL') {
                      if (item.transaction.txnType != _filterType) return false;
                    }
                    return true;
                  }).toList();

                  if (filteredData.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.get('no_transactions', lang))),
                    );
                    return;
                  }
                  
                  // Generate PDF with Filtered Data
                  PdfService().generateMonthlyReport(filteredData, shopProfile);
                },
                icon: const Icon(Icons.download),
                label: const Text("DOWNLOAD REPORT"),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("${AppStrings.get('error', lang)}: $e"),
            ),
          ],
        ),
      ),
    );
  }
}