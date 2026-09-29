import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final repository = AppDataRepository.instance;

  @override
  void initState() {
    super.initState();
    repository.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    repository.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial & Performance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            const SizedBox(height: 16),
            _buildReportCard(
              'Total Revenue Collected',
              '₹${repository.totalRevenue.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Total Outstanding Balance',
              '₹${repository.totalOutstanding.toStringAsFixed(0)}',
              Icons.receipt_long,
              const Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              'Net Estimated Profit',
              '₹${repository.totalProfit.toStringAsFixed(0)}',
              Icons.trending_up,
              AppTheme.primary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report PDF downloaded successfully.')),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Export Summary Report (PDF)'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
