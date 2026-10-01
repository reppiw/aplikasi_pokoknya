import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onRegistered});

  final VoidCallback onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  int _age = 18;
  bool _showAgeError = false;
  bool _isPhotoStep = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueToPhoto() {
    if (!_formKey.currentState!.validate()) return;
    if (_age < 16) {
      setState(() => _showAgeError = true);
      return;
    }
    setState(() {
      _showAgeError = false;
      _isPhotoStep = true;
    });
  }

  void _finishRegistration() {
    try {
      AuthService.instance.register(
        name: _nameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        age: _age,
      );
      widget.onRegistered();
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => _isPhotoStep
              ? setState(() => _isPhotoStep = false)
              : Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(_isPhotoStep ? 'FOTO PROFIL' : 'BUAT AKUN'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/Homepage_Background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: NeoColors.cream.withValues(alpha: 0.88)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: NeoColors.cream,
                      border: NeoBorder.thick,
                      boxShadow: NeoShadows.l,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isPhotoStep
                          ? _buildPhotoStep()
                          : _buildDetailsStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('register-details'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gabung ke Koboted',
            style: NeoTextStyles.h2.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text('Isi data akunmu untuk melanjutkan.', style: NeoTextStyles.body),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Nama wajib diisi.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (value) {
              final username = value?.trim() ?? '';
              if (username.length < 3) return 'Username minimal 3 karakter.';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
                return 'Gunakan huruf, angka, atau garis bawah.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => value == null || value.length < 8
                ? 'Password minimal 8 karakter.'
                : null,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Umur', style: NeoTextStyles.bodyLarge)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _age < 16 ? NeoColors.accent : NeoColors.secondary,
                  border: NeoBorder.thin,
                ),
                child: Text('$_age tahun', style: NeoTextStyles.button),
              ),
            ],
          ),
          Slider(
            key: const ValueKey('age-slider'),
            value: _age.toDouble(),
            min: 10,
            max: 80,
            divisions: 70,
            label: '$_age tahun',
            onChanged: (value) => setState(() {
              _age = value.round();
              _showAgeError = false;
            }),
          ),
          if (_showAgeError || _age < 16)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Pendaftaran hanya untuk pengguna berusia minimal 16 tahun.',
                style: NeoTextStyles.body.copyWith(color: NeoColors.accent),
              ),
            ),
          ElevatedButton(
            onPressed: _continueToPhoto,
            child: const Text('LANJUT'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      key: const ValueKey('register-photo'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Foto profil', style: NeoTextStyles.h2.copyWith(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          'Kamu bisa menambahkannya nanti.',
          textAlign: TextAlign.center,
          style: NeoTextStyles.body,
        ),
        const SizedBox(height: 24),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: NeoColors.cardInner,
            shape: BoxShape.circle,
            border: Border.all(color: NeoColors.ink, width: 4),
          ),
          child: const Icon(Icons.person_outline, size: 64),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pilihan foto profil belum tersedia.'),
            ),
          ),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('PILIH FOTO'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _finishRegistration,
          child: const Text('LEWATI'),
        ),
      ],
    );
  }
}
