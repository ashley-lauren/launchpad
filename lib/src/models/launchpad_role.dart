enum LaunchpadRole {
  student,
  teacher,
  admin,
}

extension LaunchpadRoleX on LaunchpadRole {
  String get routeName {
    switch (this) {
      case LaunchpadRole.student:
        return '/student';
      case LaunchpadRole.teacher:
        return '/teacher';
      case LaunchpadRole.admin:
        return '/admin';
    }
  }

  String get displayName {
    switch (this) {
      case LaunchpadRole.student:
        return 'Student';
      case LaunchpadRole.teacher:
        return 'Teacher';
      case LaunchpadRole.admin:
        return 'Admin';
    }
  }

  static LaunchpadRole fromRoute(String? route) {
    final normalized = route?.trim().toLowerCase() ?? '/';
    if (normalized == '/teacher') {
      return LaunchpadRole.teacher;
    }
    if (normalized == '/admin') {
      return LaunchpadRole.admin;
    }
    return LaunchpadRole.student;
  }
}
