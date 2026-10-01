import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'auth/login_screen.dart';

class OpeningScreen extends StatefulWidget {
  final bool isAuthenticated;
  final VoidCallback onFinished;

  const OpeningScreen({
    super.key,
    required this.isAuthenticated,
    required this.onFinished,
  });

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _curtainController;

  bool _startCurtain = false;

  @override
  void initState() {
    super.initState();

    // Animasi titik bouncing
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // Animasi gorden naik
    _curtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;

      setState(() {
        _startCurtain = true;
      });

      _curtainController.forward().then((_) {
        if (mounted) {
          widget.onFinished();
        }
      });
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _curtainController.dispose();
    super.dispose();
  }

  double dotPosition(int index) {
    final value = (_loadingController.value + index * 0.2) % 1.0;

    if (value < 0.5) {
      return -10 * (value / 0.5);
    }

    return -10 * ((1 - value) / 0.5);
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Koboted',
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        dotPosition(index),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningScreen() {
    return AnimatedBuilder(
      animation: _curtainController,
      builder: (context, child) {
        final value = Curves.easeInOutCubic.transform(
          _curtainController.value,
        );

        // Geser seluruh opening ke atas
        final screenHeight = MediaQuery.of(context).size.height;

        return Transform.translate(
          offset: Offset(
            0,
            -screenHeight * value,
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/Homepage_Background.jpg',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: ColoredBox(
                color: NeoColors.cream.withValues(
                  alpha: 0.88,
                ),
              ),
            ),

            _buildLoadingContent(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LOGIN SCREEN DI BELAKANG
          Positioned.fill(
            child: LoginScreen(
              onAuthenticated: widget.onFinished,
            ),
          ),

          // OPENING SCREEN
          Positioned.fill(
            child: _buildOpeningScreen(),
          ),
        ],
      ),
    );
  }
}