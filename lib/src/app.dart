import 'package:flutter/material.dart';

import 'services/launchpad_controller.dart';
import 'ui/screens/admin_shell.dart';
import 'ui/screens/student_shell.dart';
import 'ui/screens/teacher_shell.dart';
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
          routes: {
            '/student': (context) => StudentShell(controller: controller),
            '/teacher': (context) => TeacherShell(controller: controller),
            '/admin': (context) => AdminShell(controller: controller),
            '/': (context) => StudentShell(controller: controller),
          },
        );
      },
    );
  }
}
