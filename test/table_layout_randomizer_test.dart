import 'package:flutter_test/flutter_test.dart';
import 'package:launchpad/src/models/launchpad_models.dart';
import 'package:launchpad/src/services/table_layout_randomizer.dart';

void main() {
  group('TableLayoutRandomizer', () {
    test('balances students across tables for an even split', () {
      final students = List.generate(
        18,
        (index) => LaunchpadStudentRecord(
          id: index + 1,
          classId: 1,
          firstName: 'Student',
          lastName: '$index',
          displayName: 'Student $index',
        ),
      );

      final result = TableLayoutRandomizer.randomize(
        students: students,
        tableCount: 6,
        options: const RandomizationOptions(
          balanceTableSizes: true,
          preferNewTablemates: false,
          avoidRecentTablemates: 0,
        ),
        constraints: const [],
        history: const [],
        layoutMembersByLayoutId: const {},
      );

      expect(result.assignments.length, students.length);
      expect(result.tableSizes, [3, 3, 3, 3, 3, 3]);
    });

    test('respects avoid constraints', () {
      final students = [
        const LaunchpadStudentRecord(
          id: 1,
          classId: 1,
          firstName: 'Tatum',
          lastName: 'A',
          displayName: 'Tatum',
        ),
        const LaunchpadStudentRecord(
          id: 2,
          classId: 1,
          firstName: 'Iris',
          lastName: 'B',
          displayName: 'Iris',
        ),
        const LaunchpadStudentRecord(
          id: 3,
          classId: 1,
          firstName: 'Quinn',
          lastName: 'C',
          displayName: 'Quinn',
        ),
      ];

      final result = TableLayoutRandomizer.randomize(
        students: students,
        tableCount: 2,
        options: const RandomizationOptions(
          balanceTableSizes: false,
          preferNewTablemates: false,
          avoidRecentTablemates: 0,
        ),
        constraints: const [
          TableLayoutConstraint(type: ConstraintType.avoid, names: ['Tatum', 'Iris']),
        ],
        history: const [],
        layoutMembersByLayoutId: const {},
      );

      expect(result.assignments[1], isNot(result.assignments[2]));
    });
  });
}
