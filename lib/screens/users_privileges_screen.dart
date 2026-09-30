import 'package:flutter/material.dart';
import '../data/app_data_repository.dart';
import '../models/system_user_model.dart';
import '../theme/app_theme.dart';

class UsersPrivilegesScreen extends StatefulWidget {
  const UsersPrivilegesScreen({super.key});

  @override
  State<UsersPrivilegesScreen> createState() => _UsersPrivilegesScreenState();
}

class _UsersPrivilegesScreenState extends State<UsersPrivilegesScreen> {
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

  void _showEditUserModal(SystemUserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditUserModal(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = repository.systemUsers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Users & Role Privileges',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 2),
            const Text(
              'Active system accounts and access credentials for Haya Event Management.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),

            ...users.map((u) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary, width: 2),
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(
                            u.username.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.username,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.email,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: u.role == 'Admin' ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          u.role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: u.role == 'Admin' ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showEditUserModal(u),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _EditUserModal extends StatefulWidget {
  final SystemUserModel user;

  const _EditUserModal({required this.user});

  @override
  State<_EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<_EditUserModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late String selectedRole;
  late String selectedAvatar;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.user.username);
    emailController = TextEditingController(text: widget.user.email);
    selectedRole = widget.user.role;
    selectedAvatar = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit User Profile - ${widget.user.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Display Name / Username *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Role & Privilege'),
              items: ['Admin', 'Manager', 'Accountant']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => selectedRole = v!),
            ),
            const SizedBox(height: 16),

            const Text('Choose Profile Avatar Style:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
            const SizedBox(height: 8),

            Row(
              children: [
                _buildAvatarOption('avatar_1', 'Gold Badge', AppTheme.primary),
                const SizedBox(width: 12),
                _buildAvatarOption('avatar_2', 'Executive Blue', const Color(0xFF2563EB)),
                const SizedBox(width: 12),
                _buildAvatarOption('avatar_3', 'Emerald Green', const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    AppDataRepository.instance.updateUserProfile(
                      widget.user.id,
                      username: usernameController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? '${usernameController.text.trim().toLowerCase()}@hayaevents.com'
                          : emailController.text.trim(),
                      role: selectedRole,
                      avatarUrl: selectedAvatar,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: const Text('Save User Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption(String key, String label, Color color) {
    final bool isSelected = selectedAvatar == key;
    return InkWell(
      onTap: () => setState(() => selectedAvatar = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 10, backgroundColor: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
