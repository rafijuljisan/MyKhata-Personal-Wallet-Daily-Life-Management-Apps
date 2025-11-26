import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../settings/data/shop_profile_provider.dart';

class PdfService {
  Future<void> generateMonthlyReport(List<TransactionWithDetails> transactions, ShopProfile profile) async {
    final pdf = pw.Document();
    
    // Use NotoSansBengali for text to support Bengali characters
    final font = await PdfGoogleFonts.notoSansBengaliRegular(); 

    // Calculate Totals dynamically
    double totalIn = 0;
    double totalOut = 0;
    
    for (var item in transactions) {
      final type = item.transaction.txnType;
      if (['CASH_IN', 'DUE_RECEIVED', 'TRANSFER_IN'].contains(type)) {
        totalIn += item.transaction.amount;
      } else {
        totalOut += item.transaction.amount;
      }
    }
    
    final netBalance = totalIn - totalOut;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font),
        header: (context) => _buildHeader(profile),
        footer: (context) => _buildFooter(context),

        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),

            // 1. Report Title & Date Range
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Transaction Report", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text("Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 15),

            // 2. Financial Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard("Total Income", totalIn, PdfColors.green),
                _buildSummaryCard("Total Expense", totalOut, PdfColors.red),
                _buildSummaryCard("Net Balance", netBalance, netBalance >= 0 ? PdfColors.blue : PdfColors.orange),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. Detailed Table
            pw.Table.fromTextArray(
              headers: ['Date', 'Type', 'Category', 'Party', 'Note', 'Amount'],
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
              },
              cellStyle: const pw.TextStyle(fontSize: 9),
              data: transactions.map((item) {
                final t = item.transaction;
                
                final categoryName = item.category?.name ?? 'General';
                final partyName = item.party?.name ?? '-';
                
                return [
                  DateFormat('dd/MM/yy').format(t.date),
                  _formatType(t.txnType),
                  categoryName,
                  partyName,
                  t.details ?? '',
                  t.amount.toStringAsFixed(0),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- Helper Widgets ---

  pw.Widget _buildHeader(ShopProfile profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(profile.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
        if (profile.address.isNotEmpty) 
          pw.Text(profile.address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        if (profile.phone.isNotEmpty) 
          pw.Text("Contact: ${profile.phone}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 10),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        "Page ${context.pageNumber} of ${context.pagesCount}",
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, double amount, PdfColor color) {
    // Manually creating a lighter version of the color (opacity ~0.1)
    final PdfColor bg = PdfColor(color.red, color.green, color.blue, 0.1);

    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(5),
        color: bg,
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Text(
            "Tk ${amount.abs().toStringAsFixed(0)}", 
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'CASH_IN': return 'In';
      case 'CASH_OUT': return 'Out';
      case 'DUE_GIVEN': return 'Due Given';
      case 'DUE_RECEIVED': return 'Due Recv';
      case 'TRANSFER_IN': return 'Transfer In';
      case 'TRANSFER_OUT': return 'Transfer Out';
      default: return type.replaceAll('_', ' ');
    }
  }
}