import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_overlay.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final repository = AppDataRepository.instance;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController gstinController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: repository.companyName);
    phoneController = TextEditingController(text: repository.companyPhone);
    emailController = TextEditingController(text: repository.companyEmail);
    addressController = TextEditingController(text: repository.companyAddress);
    gstinController = TextEditingController(text: repository.companyGstin);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    gstinController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    await AppLoadingOverlay.run(
      context,
      message: 'Saving company settings...',
      asyncTask: () => repository.updateCompanySettings(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
        gstin: gstinController.text.trim(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company Settings saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Company Profile & Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                const Text('Configure company details printed on invoices and client receipts.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 20),

                // Card Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand Logo Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primary, width: 2),
                            ),
                            child: const Center(
                              child: Text('H', style: TextStyle(color: AppTheme.primary, fontSize: 26, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(repository.companyName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Text('Support Helpline: +91 9747451938', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 32),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Company Name'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(labelText: 'Support Email (Optional)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Company Address'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: gstinController,
                        decoration: const InputDecoration(labelText: 'Tax / GSTIN Number (Optional)'),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Company Settings'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
