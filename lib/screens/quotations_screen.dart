import 'package:flutter/material.dart';
import 'create_quotation_screen.dart';

class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  static void showCreateDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CreateQuotationScreen();
  }
}
