import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  bool _notificationsEnabled = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController =
        TextEditingController(text: '${widget.user.id}@app.com');
    _bioController =
        TextEditingController(text: 'Enthusiastic Flutter developer.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Fungsi simpan profil
  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulasi delay proses simpan data (async)
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROFILE UPDATED SUCCESSFULLY!',
            style: NeoTextStyles.label.copyWith(color: NeoColors.white),
          ),
          backgroundColor: NeoColors.ink,
        ),
      );

      Navigator.pop(context);
    }
  }

  // Dialog konfirmasi batal edit
  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('DISCARD CHANGES?', style: NeoTextStyles.h3),
        content: Text(
          'All unsaved changes will be lost.',
          style: NeoTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('NO', style: NeoTextStyles.button),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NeoColors.accent,
              foregroundColor: NeoColors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('YES, DISCARD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeoColors.cream,
      appBar: AppBar(
        backgroundColor: NeoColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: NeoColors.ink),
          onPressed: _confirmCancel,
        ),
        title: Text('EDIT PROFILE', style: NeoTextStyles.h2),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: Divider(height: 4, thickness: 4, color: NeoColors.ink),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field Display Name
              _buildLabel('DISPLAY NAME'),
              TextFormField(
                controller: _nameController,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Enter full name'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name cannot be empty!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Email Address
              _buildLabel('EMAIL ADDRESS'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Enter email address'),
                validator: (val) {
                  if (val == null || !val.contains('@')) {
                    return 'Invalid email format!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Field Bio / Description
              _buildLabel('BIO / DESCRIPTION'),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Write a short bio...'),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Bio must be at least 5 characters long!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Switch Notification Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeoColors.white,
                  border: NeoBorder.thick,
                  boxShadow: NeoShadows.s,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ENABLE NOTIFICATIONS', style: NeoTextStyles.body),
                    Switch(
                      value: _notificationsEnabled,
                      activeColor: NeoColors.secondary,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Tombol Action (Cancel & Save)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: NeoColors.ink, width: 4),
                        backgroundColor: NeoColors.muted,
                        foregroundColor: NeoColors.ink,
                      ),
                      onPressed: _isLoading ? null : _confirmCancel,
                      child: Text('CANCEL', style: NeoTextStyles.button),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: NeoColors.secondary,
                        foregroundColor: NeoColors.ink,
                        side: const BorderSide(color: NeoColors.ink, width: 4),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: NeoColors.ink,
                        ),
                      )
                          : Text('SAVE', style: NeoTextStyles.button),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Label Form
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: NeoTextStyles.label.copyWith(fontSize: 11, color: NeoColors.ink),
      ),
    );
  }

  // Helper Decoration gaya Neo-Brutalism
  InputDecoration _neoInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: NeoColors.white,
      contentPadding: const EdgeInsets.all(12),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: NeoColors.ink, width: 3),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: NeoColors.ink, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: NeoColors.accent, width: 3),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: NeoColors.accent, width: 4),
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}