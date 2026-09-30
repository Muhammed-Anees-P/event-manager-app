import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quotation_model.dart';
import '../data/app_data_repository.dart';

class QuotationPdfService {
  static Future<Uint8List> generatePdfBytes(QuotationModel quotation) async {
    final pdf = pw.Document();
    final repo = AppDataRepository.instance;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(repo.companyName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
                    pw.SizedBox(height: 4),
                    pw.Text(repo.companyAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Email: ${repo.companyEmail} | Phone: ${repo.companyPhone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('GSTIN: ${repo.companyGstin}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const pw.BoxDecoration(color: PdfColors.amber100),
                      child: pw.Text('QUOTATION', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Quote #: ${quotation.quoteNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text('Date: ${quotation.quotationDate}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Valid Until: ${quotation.dueDate}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey),
            pw.SizedBox(height: 15),

            // Customer Details
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Prepared For:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(quotation.customerName.isEmpty ? 'Valued Client' : quotation.customerName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Event Venue:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(quotation.venue.isEmpty ? 'TBD' : quotation.venue, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Sections & Items Table
            ...quotation.sections.map((section) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text(section.heading, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.brown900)),
                  ),
                  pw.TableHelper.fromTextArray(
                    headers: ['Description', 'Qty', 'Rate (₹)', 'Amount (₹)'],
                    data: section.items.map((item) {
                      return [
                        item.name,
                        item.qty != null ? item.qty!.toStringAsFixed(0) : '-',
                        item.rate != null ? item.rate!.toStringAsFixed(0) : '-',
                        item.price.toStringAsFixed(0),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellPadding: const pw.EdgeInsets.all(6),
                    columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(1.5)},
                  ),
                  pw.SizedBox(height: 12),
                ],
              );
            }),

            pw.SizedBox(height: 10),

            // Summary Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _buildSummaryRow('Subtotal', '₹${quotation.rawSubtotal.toStringAsFixed(0)}'),
                      if (quotation.showDiscount) _buildSummaryRow('Discount', '- ₹${quotation.calculatedDiscount.toStringAsFixed(0)}'),
                      if (quotation.showTax) _buildSummaryRow('Tax (${quotation.taxPercentage.toStringAsFixed(0)}%)', '+ ₹${quotation.calculatedTax.toStringAsFixed(0)}'),
                      pw.Divider(thickness: 1, color: PdfColors.grey),
                      _buildSummaryRow('Total Quoted', '₹${quotation.grandTotal.toStringAsFixed(0)}', isBold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Authorized Signature\n${repo.companyName}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                pw.Text('Thank you for considering our services!', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static Future<void> printQuotation(QuotationModel quotation) async {
    final pdfBytes = await generatePdfBytes(quotation);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
