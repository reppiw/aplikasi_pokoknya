import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
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

class App extends ConsumerWidget {
  const App({super.key, this.firebaseInitializationError});

  final Object? firebaseInitializationError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (firebaseInitializationError case final error?) {
      return MaterialApp(
        title: 'Koboted',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _FirebaseStartupErrorScreen(error: error),
      );
    }

    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Koboted',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _Root(authState: authState),
    );
  }
}

/// Root routing widget — reacts to auth state from the [authProvider] stream.
///
/// Shows the opening animation once on startup, then routes to
/// [ShellScreen] (authenticated) or [LoginScreen] (unauthenticated)
/// based on the current [authProvider] value.
class _Root extends StatefulWidget {
  const _Root({required this.authState});

  final AsyncValue<User?> authState;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _showOpening = true;

  @override
  Widget build(BuildContext context) {
    if (_showOpening) {
      return OpeningScreen(
        onFinished: () => setState(() => _showOpening = false),
      );
    }

    return widget.authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      data: (user) => user != null
          ? const ShellScreen()
          : const LoginScreen(),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Auth error: $error')),
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
