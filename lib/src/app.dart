import 'package:flutter/material.dart';

import 'services/launchpad_controller.dart';
import 'ui/screens/home_shell.dart';
import 'ui/theme.dart';

class LaunchpadApp extends StatelessWidget {
  const LaunchpadApp({super.key, required this.controller});

  final LaunchpadController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Launchpad',
          theme: buildLaunchpadTheme(),
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}
