import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../data/app_data_repository.dart';

class InvoicePdfService {
  static Future<void> printInvoice(InvoiceModel invoice) async {
    final pdfBytes = await generatePdfBytes(invoice);
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  static Future<Uint8List> generatePdfBytes(InvoiceModel invoice) async {
    final pdf = pw.Document();
    final repo = AppDataRepository.instance;

    pw.MemoryImage? logoImage;
    try {
      final imgBytes = await rootBundle.load('assets/images/logo-no-bg.png');
      logoImage = pw.MemoryImage(imgBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final primaryColor = PdfColor.fromHex('#1A1A1A');
    final goldColor = PdfColor.fromHex('#C5A059');
    final cardBg = PdfColor.fromHex('#FBF9F5');
    final borderColor = PdfColor.fromHex('#E0D6C3');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          buildBackground: (context) {
            if (logoImage == null) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.08,
                  child: pw.Image(logoImage, width: 380, height: 380),
                ),
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            // Luxury Header & Logo Image
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        width: 75,
                        height: 75,
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Container(
                        width: 44,
                        height: 44,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: goldColor, width: 2),
                          color: primaryColor,
                        ),
                        child: pw.Center(
                          child: pw.Text('H', style: pw.TextStyle(color: goldColor, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          repo.companyName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'LUXURY EVENT CURATION',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: goldColor,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Email: ${repo.companyEmail} | Phone: ${repo.companyPhone}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text('Address: ${repo.companyAddress}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: goldColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Invoice #: ${invoice.invoiceNumber}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.Text('Date: ${invoice.invoiceDate}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Due Date: ${invoice.dueDate}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('GSTIN: ${repo.companyGstin}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1.5, color: goldColor),
            pw.SizedBox(height: 14),

            // Customer & Venue Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor, width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PREPARED FOR (CLIENT)',
                          style: pw.TextStyle(fontSize: 8, color: goldColor, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.customerName.isEmpty ? 'Valued Client' : invoice.customerName,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('EVENT VENUE / LOCATION',
                          style: pw.TextStyle(fontSize: 8, color: goldColor, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.venue.isEmpty ? 'TBD' : invoice.venue,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Grouped Item Sections
            ...invoice.sections.map((section) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(color: primaryColor),
                    child: pw.Text(
                      section.heading.toUpperCase(),
                      style: pw.TextStyle(color: goldColor, fontWeight: pw.FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
                    ),
                  ),
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(color: borderColor, width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3.5),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1.5),
                      3: const pw.FlexColumnWidth(1.8),
                    },
                    headers: ['Item Description', 'Qty', 'Rate (Rs.)', 'Amount (Rs.)'],
                    data: section.items.map((item) {
                      return [
                        item.name,
                        item.qty != null ? item.qty!.toStringAsFixed(0) : '-',
                        item.rate != null ? item.rate!.toStringAsFixed(0) : '-',
                        item.price.toStringAsFixed(0),
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2D2D2D')),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.all(8),
                  ),
                  pw.SizedBox(height: 14),
                ],
              );
            }),

            pw.SizedBox(height: 10),

            // Summary Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 240,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderColor, width: 1),
                  ),
                  child: pw.Column(
                    children: [
                      _buildSummaryRow('Subtotal', 'Rs. ${invoice.rawSubtotal.toStringAsFixed(0)}', primaryColor),
                      if (invoice.showDiscount) ...[
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Discount', '- Rs. ${invoice.calculatedDiscount.toStringAsFixed(0)}', primaryColor),
                      ],
                      if (invoice.showTax) ...[
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Tax (${invoice.taxPercentage.toStringAsFixed(0)}%)', '+ Rs. ${invoice.calculatedTax.toStringAsFixed(0)}', primaryColor),
                      ],
                      pw.Divider(thickness: 1, color: goldColor),
                      _buildSummaryRow('Grand Total', 'Rs. ${invoice.grandTotal.toStringAsFixed(0)}', primaryColor, isBold: true),
                      if (invoice.showAdvancePaid) ...[
                        pw.SizedBox(height: 4),
                        _buildSummaryRow('Advance Paid', 'Rs. ${invoice.calculatedAdvance.toStringAsFixed(0)}', PdfColors.green800),
                        pw.Divider(thickness: 0.5, color: borderColor),
                        _buildSummaryRow('Balance Due', 'Rs. ${invoice.balanceDue.toStringAsFixed(0)}', PdfColors.red800, isBold: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // Footer / Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.SizedBox(height: 20),
                    pw.Text('___________________________', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                    pw.Text(repo.companyName, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Turning Moments Into Unforgettable Memories',
                        style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: goldColor)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryRow(String label, String value, PdfColor color, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, color: color, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }
}
