import 'dart:math';

import '../models/launchpad_models.dart';

enum ConstraintType { avoid, together, lock }

class TableLayoutConstraint {
  const TableLayoutConstraint({
    required this.type,
    required this.names,
    this.tableNumber,
  });

  final ConstraintType type;
  final List<String> names;
  final int? tableNumber;
}

class ConstraintParseResult {
  const ConstraintParseResult({
    required this.constraints,
    required this.errors,
  });

  final List<TableLayoutConstraint> constraints;
  final List<String> errors;
}

class RandomizationOptions {
  const RandomizationOptions({
    required this.balanceTableSizes,
    required this.preferNewTablemates,
    required this.avoidRecentTablemates,
  });

  final bool balanceTableSizes;
  final bool preferNewTablemates;
  final int avoidRecentTablemates;
}

class RandomizationResult {
  const RandomizationResult({
    required this.assignments,
    required this.tableSizes,
    required this.summary,
    required this.usedConstraintCount,
  });

  final Map<int, int> assignments;
  final List<int> tableSizes;
  final String summary;
  final int usedConstraintCount;
}

class TableLayoutRandomizer {
  static ConstraintParseResult parseConstraints({
    required String rawText,
    required List<LaunchpadStudentRecord> students,
    required int tableCount,
  }) {
    final constraints = <TableLayoutConstraint>[];
    final errors = <String>[];
    final studentNames = {
      for (final student in students) student.label.trim().toLowerCase(): student
    };

    final seenLocks = <String, int>{};
    final avoidPairs = <String>{};
    final togetherPairs = <String>{};

    final lines = rawText.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      if (line.toLowerCase().startsWith('avoid:')) {
        final names = _parseNameList(line.substring('avoid:'.length));
        if (names.isEmpty) {
          errors.add('Avoid rule is missing student names.');
          continue;
        }
        final normalized = names.map((name) => name.trim()).where((name) => name.isNotEmpty).toList();
        if (normalized.length < 2) {
          errors.add('Avoid rules need at least two students.');
          continue;
        }
        for (final name in normalized) {
          if (!studentNames.containsKey(name.toLowerCase())) {
            errors.add('Unknown student: "$name"');
          }
        }
        if (errors.any((item) => item.contains('Unknown student'))) {
          continue;
        }
        for (final pair in _pairwise(normalized)) {
          final key = _pairKey(pair.first, pair.last);
          if (togetherPairs.contains(key)) {
            errors.add('Conflicting constraints: ${pair.first} is required both together with and apart from ${pair.last}.');
            continue;
          }
          avoidPairs.add(key);
        }
        constraints.add(TableLayoutConstraint(type: ConstraintType.avoid, names: normalized));
      } else if (line.toLowerCase().startsWith('together:')) {
        final names = _parseNameList(line.substring('together:'.length));
        if (names.isEmpty) {
          errors.add('Together rule is missing student names.');
          continue;
        }
        final normalized = names.map((name) => name.trim()).where((name) => name.isNotEmpty).toList();
        if (normalized.length < 2) {
          errors.add('Together rules need at least two students.');
          continue;
        }
        for (final name in normalized) {
          if (!studentNames.containsKey(name.toLowerCase())) {
            errors.add('Unknown student: "$name"');
          }
        }
        if (errors.any((item) => item.contains('Unknown student'))) {
          continue;
        }
        for (final pair in _pairwise(normalized)) {
          final key = _pairKey(pair.first, pair.last);
          if (avoidPairs.contains(key)) {
            errors.add('Conflicting constraints: ${pair.first} is required both together with and apart from ${pair.last}.');
            continue;
          }
          togetherPairs.add(key);
        }
        constraints.add(TableLayoutConstraint(type: ConstraintType.together, names: normalized));
      } else if (line.toLowerCase().startsWith('lock:')) {
        final remainder = line.substring('lock:'.length).trim();
        final parts = remainder.split('->');
        if (parts.length != 2) {
          errors.add('Lock rule should look like: lock: Quinn -> Table 2');
          continue;
        }
        final studentName = parts.first.trim();
        final tableNumber = int.tryParse(parts.last.trim().replaceFirst('Table', '').trim());
        if (tableNumber == null) {
          errors.add('Unknown table: ${parts.last.trim()}');
          continue;
        }
        if (tableNumber < 1 || tableNumber > tableCount) {
          errors.add('Unknown table: Table $tableNumber');
          continue;
        }
        if (!studentNames.containsKey(studentName.toLowerCase())) {
          errors.add('Unknown student: "$studentName"');
          continue;
        }
        if (seenLocks.containsKey(studentName.toLowerCase()) && seenLocks[studentName.toLowerCase()] != tableNumber) {
          errors.add('Student $studentName is locked to two different tables.');
          continue;
        }
        seenLocks[studentName.toLowerCase()] = tableNumber;
        constraints.add(TableLayoutConstraint(
          type: ConstraintType.lock,
          names: [studentName],
          tableNumber: tableNumber,
        ));
      }
    }

    return ConstraintParseResult(constraints: constraints, errors: errors);
  }

  static RandomizationResult randomize({
    required List<LaunchpadStudentRecord> students,
    required int tableCount,
    required RandomizationOptions options,
    required List<TableLayoutConstraint> constraints,
    required List<LaunchpadTableLayoutRecord> history,
    required Map<int, List<LaunchpadTableLayoutMember>> layoutMembersByLayoutId,
  }) {
    if (students.isEmpty) {
      return const RandomizationResult(
        assignments: {},
        tableSizes: [],
        summary: 'No students to assign.',
        usedConstraintCount: 0,
      );
    }

    final random = Random();
    final studentMap = {for (final student in students) student.id: student};
    final studentLabels = {for (final student in students) student.id: student.label.trim()};

    final togetherGroups = <List<int>>[];
    final usedStudents = <int>{};
    final constraintByStudent = <int, List<TableLayoutConstraint>>{};

    for (final constraint in constraints) {
      if (constraint.type == ConstraintType.together) {
        final resolved = constraint.names
            .map((name) => studentMap.values.where((student) => student.label.trim().toLowerCase() == name.trim().toLowerCase()).firstOrNull())
            .whereType<LaunchpadStudentRecord>()
            .map((student) => student.id)
            .toList();
        if (resolved.length >= 2) {
          togetherGroups.add(resolved);
          usedStudents.addAll(resolved);
        }
      }
      for (final name in constraint.names) {
        final candidate = studentMap.values.where((student) => student.label.trim().toLowerCase() == name.trim().toLowerCase()).firstOrNull();
        if (candidate == null) {
          continue;
        }
        constraintByStudent.putIfAbsent(candidate.id, () => []).add(constraint);
      }
    }

    final singles = students.where((student) => !usedStudents.contains(student.id)).map((student) => <int>[student.id]).toList();
    final entities = [...togetherGroups, ...singles];
    final historyPairs = _buildHistoryPairs(
      history: history,
      layoutMembersByLayoutId: layoutMembersByLayoutId,
      limit: options.avoidRecentTablemates,
    );

    final assignments = <int, int>{};
    final tableSizes = List.filled(tableCount, 0);

    final solution = _searchSolution(
      entities: entities,
      studentLabels: studentLabels,
      tableCount: tableCount,
      assignments: assignments,
      tableSizes: tableSizes,
      constraints: constraints,
      constraintByStudent: constraintByStudent,
      options: options,
      historyPairs: historyPairs,
      random: random,
      depth: 0,
    );

    if (solution == null) {
      throw StateError('Launchpad could not generate a valid layout with the current constraints.');
    }

    final pairMatches = _countRecentPairMatches(
      assignments: solution.assignments,
      historyPairs: historyPairs,
    );
    final fullSummary =
        'Generated layout\n• ${students.length} students assigned\n• table sizes: ${solution.tableSizes.join(' / ')}\n• avoided $pairMatches recent tablemate pairs\n• ${constraints.length} seating constraints applied';

    return RandomizationResult(
      assignments: solution.assignments,
      tableSizes: solution.tableSizes,
      summary: fullSummary,
      usedConstraintCount: constraints.length,
    );
  }

  static _SearchSolution? _searchSolution({
    required List<List<int>> entities,
    required Map<int, String> studentLabels,
    required int tableCount,
    required Map<int, int> assignments,
    required List<int> tableSizes,
    required List<TableLayoutConstraint> constraints,
    required Map<int, List<TableLayoutConstraint>> constraintByStudent,
    required RandomizationOptions options,
    required Map<String, int> historyPairs,
    required Random random,
    required int depth,
  }) {
    if (entities.isEmpty) {
      return _SearchSolution(assignments: Map<int, int>.from(assignments), tableSizes: [...tableSizes]);
    }

    final entity = entities.first;
    final remainingEntities = entities.sublist(1);

    final candidateTables = List.generate(tableCount, (index) => index + 1).toList()
      ..shuffle(random);

    final scoredTables = <_ScoredTable>[];
    for (final table in candidateTables) {
      if (!_isTableCompatible(
        table: table,
        entity: entity,
        assignments: assignments,
        tableSizes: tableSizes,
        constraints: constraints,
        constraintByStudent: constraintByStudent,
        studentLabels: studentLabels,
      )) {
        continue;
      }
      var score = 0.0;
      if (options.balanceTableSizes) {
        score += tableSizes[table - 1] * 2.5;
      }
      if (options.preferNewTablemates) {
        for (final existingStudentId in assignments.keys) {
          if (assignments[existingStudentId] != table) {
            continue;
          }
          final penalty = historyPairs[_pairKeyInt(existingStudentId, entity.first)] ?? 0;
          score += penalty * 0.25;
        }
      }
      score += (tableSizes[table - 1] + entity.length - (studentLabels.length / tableCount)).abs() * 0.2;
      scoredTables.add(_ScoredTable(table: table, score: score));
    }

    if (scoredTables.isEmpty) {
      return null;
    }

    scoredTables.sort((a, b) => a.score.compareTo(b.score));
    final bestScore = scoredTables.first.score;
    final bestCandidates = scoredTables.where((item) => item.score <= bestScore + 0.5).toList();
    bestCandidates.shuffle(random);

    for (final candidate in bestCandidates) {
      final nextAssignments = Map<int, int>.from(assignments);
      final nextTableSizes = [...tableSizes];
      for (final studentId in entity) {
        nextAssignments[studentId] = candidate.table;
      }
      nextTableSizes[candidate.table - 1] += entity.length;
      final result = _searchSolution(
        entities: remainingEntities,
        studentLabels: studentLabels,
        tableCount: tableCount,
        assignments: nextAssignments,
        tableSizes: nextTableSizes,
        constraints: constraints,
        constraintByStudent: constraintByStudent,
        options: options,
        historyPairs: historyPairs,
        random: random,
        depth: depth + 1,
      );
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  static bool _isTableCompatible({
    required int table,
    required List<int> entity,
    required Map<int, int> assignments,
    required List<int> tableSizes,
    required List<TableLayoutConstraint> constraints,
    required Map<int, List<TableLayoutConstraint>> constraintByStudent,
    required Map<int, String> studentLabels,
  }) {
    for (final studentId in entity) {
      final constraintsForStudent = constraintByStudent[studentId] ?? const <TableLayoutConstraint>[];
      for (final constraint in constraintsForStudent) {
        if (constraint.type == ConstraintType.lock && constraint.tableNumber != null && constraint.tableNumber != table) {
          return false;
        }
      }
    }

    for (final assignedStudentId in assignments.keys) {
      if (assignments[assignedStudentId] != table) {
        continue;
      }
      for (final studentId in entity) {
        for (final constraint in constraints) {
          if (constraint.type == ConstraintType.avoid) {
            final studentName = studentLabels[studentId]?.trim().toLowerCase();
            final assignedName = studentLabels[assignedStudentId]?.trim().toLowerCase();
            if (studentName == null || assignedName == null) {
              continue;
            }
            if (constraint.names.any((name) => name.trim().toLowerCase() == studentName) && constraint.names.any((name) => name.trim().toLowerCase() == assignedName)) {
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  static Map<String, int> _buildHistoryPairs({
    required List<LaunchpadTableLayoutRecord> history,
    required Map<int, List<LaunchpadTableLayoutMember>> layoutMembersByLayoutId,
    required int limit,
  }) {
    final penalties = <String, int>{};
    for (var index = 0; index < history.length && index < limit; index++) {
      final layout = history[index];
      final members = layoutMembersByLayoutId[layout.id] ?? const <LaunchpadTableLayoutMember>[];
      final groupedByTable = <int, List<int>>{};
      for (final member in members) {
        groupedByTable.putIfAbsent(member.tableNumber, () => []).add(member.studentId);
      }
      final weight = limit - index;
      for (final tableMembers in groupedByTable.values) {
        for (var first = 0; first < tableMembers.length; first++) {
          for (var second = first + 1; second < tableMembers.length; second++) {
            final key = _pairKeyInt(tableMembers[first], tableMembers[second]);
            penalties[key] = (penalties[key] ?? 0) + weight;
          }
        }
      }
    }
    return penalties;
  }

  static int _countRecentPairMatches({
    required Map<int, int> assignments,
    required Map<String, int> historyPairs,
  }) {
    var count = 0;
    final studentIds = assignments.keys.toList();
    for (var first = 0; first < studentIds.length; first++) {
      for (var second = first + 1; second < studentIds.length; second++) {
        final firstStudentId = studentIds[first];
        final secondStudentId = studentIds[second];
        if (assignments[firstStudentId] == assignments[secondStudentId] && historyPairs.containsKey(_pairKeyInt(firstStudentId, secondStudentId))) {
          count += 1;
        }
      }
    }
    return count;
  }
}

class _SearchSolution {
  const _SearchSolution({required this.assignments, required this.tableSizes});

  final Map<int, int> assignments;
  final List<int> tableSizes;
}

class _ScoredTable {
  const _ScoredTable({required this.table, required this.score});

  final int table;
  final double score;
}

String _pairKey(String first, String second) {
  final ordered = [first, second]..sort();
  return '${ordered.first}|${ordered.last}';
}

String _pairKeyInt(int first, int second) {
  final ordered = [first, second]..sort();
  return '${ordered.first}|${ordered.last}';
}

List<String> _parseNameList(String value) {
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<List<T>> _pairwise<T>(List<T> items) {
  final result = <List<T>>[];
  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      result.add([items[i], items[j]]);
    }
  }
  return result;
}

extension on Iterable<LaunchpadStudentRecord> {
  LaunchpadStudentRecord? firstOrNull() {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
