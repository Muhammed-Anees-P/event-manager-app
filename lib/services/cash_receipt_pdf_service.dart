import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/payment_model.dart';
import '../data/app_data_repository.dart';

class CashReceiptPdfService {
  static Future<void> printPdf(PaymentModel payment, {String customerName = 'Valued Customer'}) async {
    final pdfBytes = await generatePdfBytes(payment, customerName: customerName);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  static Future<Uint8List> generatePdfBytes(PaymentModel payment, {String customerName = 'Valued Customer'}) async {
    final pdf = pw.Document();
    final repo = AppDataRepository.instance;
    final receiptNo = 'RCP-2026-${payment.id.length >= 4 ? payment.id.substring(payment.id.length - 4) : payment.id}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(repo.companyName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                        pw.SizedBox(height: 4),
                        pw.Text(repo.companyAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text('Email: ${repo.companyEmail} | Phone: ${repo.companyPhone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const pw.BoxDecoration(color: PdfColors.green100),
                      child: pw.Text('CASH RECEIPT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Receipt No: $receiptNo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text('Date: ${payment.date}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Received From:', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Description / Event:', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(payment.eventType, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.SizedBox(height: 6),
                          pw.Text('Payment Method: ${payment.method}', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Amount Paid:', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('₹${payment.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Authorized Signature\n${repo.companyName}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Thank you for your payment!', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
