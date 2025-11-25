import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../settings/data/shop_profile_provider.dart'; // Import Profile

class PdfService {
  // Modified to accept ShopProfile
  Future<void> generateMonthlyReport(List<TransactionWithParty> transactions, ShopProfile profile) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansBengaliRegular(); 

    double totalIn = 0;
    double totalOut = 0;
    
    for (var item in transactions) {
      if (['CASH_IN', 'DUE_RECEIVED'].contains(item.transaction.txnType)) {
        totalIn += item.transaction.amount;
      } else {
        totalOut += item.transaction.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font), // Apply Bengali Font globally
        build: (pw.Context context) {
          return [
            // 1. Custom Shop Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(profile.name, style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                if (profile.address.isNotEmpty) pw.Text(profile.address, style: const pw.TextStyle(fontSize: 12)),
                if (profile.phone.isNotEmpty) pw.Text("Phone: ${profile.phone}", style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(),
              ],
            ),
            pw.SizedBox(height: 10),

            // 2. Report Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Monthly Report", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('MMMM yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 10),

            // 3. Summary Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text("Total Income: ${totalIn.toStringAsFixed(0)}", style: const pw.TextStyle(color: PdfColors.green)),
                  pw.Text("Total Expense: ${totalOut.toStringAsFixed(0)}", style: const pw.TextStyle(color: PdfColors.red)),
                  pw.Text("Net: ${(totalIn - totalOut).toStringAsFixed(0)}"),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 4. Table
            pw.Table.fromTextArray(
              headers: ['Date', 'Type', 'Party', 'Note', 'Amount'],
              data: transactions.map((item) {
                final t = item.transaction;
                final partyName = item.party?.name ?? '-';
                return [
                  DateFormat('dd/MM').format(t.date),
                  t.txnType.replaceAll('_', ' '), // Clean up text
                  partyName,
                  t.details ?? '',
                  t.amount.toStringAsFixed(0),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}