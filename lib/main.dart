import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/auth_service.dart';
import 'screens/opening_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? firebaseInitializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    firebaseInitializationError = error;
    debugPrint('Firebase initialization failed: $error\n$stackTrace');
  }
  runApp(
    ProviderScope(
      child: App(firebaseInitializationError: firebaseInitializationError),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key, this.firebaseInitializationError});

  final Object? firebaseInitializationError;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _isAuthenticated = AuthService.instance.isSignedIn;
  late bool _showOpening = true;

  @override
  Widget build(BuildContext context) {
    if (widget.firebaseInitializationError case final error?) {
      return MaterialApp(
        title: 'Koboted',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _FirebaseStartupErrorScreen(error: error),
      );
    }

    return MaterialApp(
      title: 'Koboted',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _showOpening
          ? OpeningScreen(
              isAuthenticated: _isAuthenticated,
              onFinished: () {
                setState(() {
                  _showOpening = false;
                });
              },
            )
          : _isAuthenticated
          ? ShellScreen(
              onSignOut: () async {
                await AuthService.instance.signOut();
                if (mounted) setState(() => _isAuthenticated = false);
              },
            )
          : LoginScreen(
              onAuthenticated: () => setState(() => _isAuthenticated = true),
            ),
    );
  }
}

class _FirebaseStartupErrorScreen extends StatelessWidget {
  const _FirebaseStartupErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isUnsupportedPlatform = error is UnsupportedError;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  isUnsupportedPlatform
                      ? 'Firebase belum dikonfigurasi untuk platform ini.'
                      : 'Firebase gagal dijalankan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SelectableText(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                  'Periksa konfigurasi Firebase untuk target yang dipilih, '
                  'lalu jalankan ulang aplikasi.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
