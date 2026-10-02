import 'package:flutter/services.dart';
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
    final index = repo.payments.indexWhere((p) => p.id == payment.id);
    final receiptNum = index >= 0 ? index + 1 : 1;
    final receiptNo = 'RCP-2026-${receiptNum.toString().padLeft(3, '0')}';

    final resolvedCustomerName = (payment.customerName != null && payment.customerName!.isNotEmpty)
        ? payment.customerName!
        : customerName;

    pw.MemoryImage? logoImage;
    try {
      final imgBytes = await rootBundle.load('assets/images/logo-no-bg.png');
      logoImage = pw.MemoryImage(imgBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final creamBg = PdfColor.fromHex('#FDFBF7');
    final goldColor = PdfColor.fromHex('#C5A059');
    final brownText = PdfColor.fromHex('#2D241E');
    final boxBg = PdfColor.fromHex('#F2EFE9');
    final lineColor = PdfColor.fromHex('#D4C5B9');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: creamBg,
              border: pw.Border.all(color: goldColor, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Row (Logo Left, Cash Receipt Right)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 90,
                        height: 90,
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Container(
                        width: 90,
                        height: 90,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: brownText, width: 1.5),
                          color: PdfColors.white,
                        ),
                        child: pw.Center(
                          child: pw.Text('HAYA', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
                        ),
                      ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('CASH', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: brownText, letterSpacing: 3.0)),
                        pw.Text('RECEIPT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: goldColor, letterSpacing: 6.0)),
                        pw.SizedBox(height: 4),
                        pw.Container(width: 160, height: 1, color: goldColor),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Receipt No & Date Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Receipt No. :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 180,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: boxBg,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: lineColor),
                          ),
                          child: pw.Text(receiptNo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text('Date :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 180,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: boxBg,
                            borderRadius: pw.BorderRadius.circular(4),
                            border: pw.Border.all(color: lineColor),
                          ),
                          child: pw.Text(payment.date, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Form Fields (Underline style)
                _buildReceiptLine('Received From', resolvedCustomerName),
                pw.SizedBox(height: 18),
                _buildReceiptLine('Amount Received', 'Rs. ${payment.amount.toStringAsFixed(0)} (INR Only)'),
                pw.SizedBox(height: 18),
                _buildReceiptLine('Payment For', payment.eventType),
                pw.SizedBox(height: 18),
                _buildReceiptLine('Payment Method', payment.method),

                pw.Spacer(),

                // Bottom Row: Total Received Box & Signature
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 280,
                      decoration: pw.BoxDecoration(
                        color: boxBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: lineColor),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: pw.BoxDecoration(
                              color: goldColor,
                              borderRadius: const pw.BorderRadius.horizontal(left: pw.Radius.circular(5)),
                            ),
                            child: pw.Text('TOTAL RECEIVED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          ),
                          pw.Expanded(
                            child: pw.Center(
                              child: pw.Text('Rs. ${payment.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brownText)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(width: 200, height: 1, color: brownText),
                        pw.SizedBox(height: 6),
                        pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brownText)),
                      ],
                    ),
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

  static pw.Widget _buildReceiptLine(String label, String value) {
    final brownText = PdfColor.fromHex('#2D241E');
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 130,
          child: pw.Text('$label :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brownText)),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                child: pw.Text(value, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brownText)),
              ),
              pw.Container(height: 1, color: PdfColor.fromHex('#D4C5B9')),
            ],
          ),
        ),
      ],
    );
  }
}
