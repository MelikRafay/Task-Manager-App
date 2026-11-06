import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/welcome_art.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: WelcomeArt(),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Smart Task\nManagement',
                    style: text.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This smart tool is designed to help you better manage your tasks',
                    style: text.bodyMedium?.copyWith(
                      color: const Color(0xFF9A9CA8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onContinue,
                    child: const Text('CONTINUE'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
