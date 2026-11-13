import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});
  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = UserProfileService();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.updateProfile(
        uid: uid,
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PROFILE UPDATED!',
            style: NeoTextStyles.label.copyWith(color: NeoColors.white),
          ),
          backgroundColor: NeoColors.ink,
        ),
      );
      // The StreamProvider in ProfileScreen will re-emit with the new data
      // automatically — no need to pass anything back.
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'FAILED TO SAVE: $e',
            style: NeoTextStyles.label.copyWith(color: NeoColors.white),
          ),
          backgroundColor: NeoColors.accent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          onPressed: _isLoading ? null : _confirmCancel,
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
              // Read-only username chip
              if (widget.user.username.isNotEmpty) ...[
                _buildLabel('USERNAME'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeoColors.muted,
                    border: NeoBorder.thick,
                  ),
                  child: Text(
                    '@${widget.user.username}',
                    style: NeoTextStyles.body.copyWith(color: NeoColors.ink),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    'Username cannot be changed.',
                    style: NeoTextStyles.label.copyWith(
                      fontSize: 10,
                      color: NeoColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],

              _buildLabel('DISPLAY NAME'),
              TextFormField(
                controller: _nameController,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Enter display name'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name cannot be empty!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('BIO'),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: NeoTextStyles.body,
                decoration: _neoInputDecoration('Write a short bio...'),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty && val.trim().length < 5) {
                    return 'Bio must be at least 5 characters or empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

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
