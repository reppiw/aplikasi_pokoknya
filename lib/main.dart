import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: App()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late bool _isAuthenticated = AuthService.instance.isSignedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koboted',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _isAuthenticated
          ? ShellScreen(
              onSignOut: () {
                AuthService.instance.signOut();
                setState(() => _isAuthenticated = false);
              },
            )
          : LoginScreen(
              onAuthenticated: () => setState(() => _isAuthenticated = true),
            ),
    );
  }
}
