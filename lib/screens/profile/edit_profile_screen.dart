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
  String _selectedRole = 'STUDENT';
  bool _notificationsEnabled = true;

  bool _isLoading = false;

  final List<String> _roleOptions = ['STUDENT', 'LECTURER', 'STAFF', 'GUEST'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: '${widget.user.id}@kampus.ac.id');
    _bioController = TextEditingController(text: 'Suka ngoding frontend Flutter.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROFIL BERHASIL DIPERBARUI!',
            style: NeoTextStyles.label.copyWith(color: NeoColors.white),
          ),
          backgroundColor: NeoColors.ink,
        ),
      );

      Navigator.pop(context);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoColors.cream,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: NeoColors.ink, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('BATALKAN EDIT?', style: NeoTextStyles.h3),
        content: Text(
          'Semua perubahan yang belum disimpan akan hilang.',
          style: NeoTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('TIDAK', style: NeoTextStyles.button),
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
            child: const Text('YA, BATALKAN'),
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
              _buildLabel('DISPLAY NAME'),
              TextFormField(
                controller: _nameController,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Masukkan nama lengkap'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama tidak boleh kosong!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('EMAIL ADDRESS'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Masukkan email'),
                validator: (val) {
                  if (val == null || !val.contains('@')) {
                    return 'Format email tidak valid!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('USER ROLE'),
              Container(
                decoration: BoxDecoration(
                  color: NeoColors.white,
                  border: NeoBorder.thick,
                  boxShadow: NeoShadows.s,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roleOptions
                        .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r, style: NeoTextStyles.body),
                    ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('BIO / DESKRIPSI'),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Tulis bio singkat...'),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return 'Bio minimal 5 karakter!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

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
                    Text('NOTIFIKASI AKTIF', style: NeoTextStyles.body),
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

              // ── Action Buttons ──────────────────────────────────────────
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
                      child: Text('BATAL', style: NeoTextStyles.button),
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
                          : Text('SIMPAN', style: NeoTextStyles.button),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: NeoTextStyles.label.copyWith(fontSize: 11, color: NeoColors.ink),
      ),
    );
  }

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