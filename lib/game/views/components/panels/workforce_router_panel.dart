/// Hardware Tycoon — Workforce Router Panel
///
/// Split-view employee roster with interactive drag-and-drop assignment.
/// Left: grouped employee list. Right: assignment slots.
/// Friction penalties are displayed as red warning indicators.
library;

import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/game_state_provider.dart';
import '../../../models/company_state.dart';

class WorkforceRouterPanel extends StatelessWidget {
  const WorkforceRouterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);
    final employees = state.employees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: HTColors.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, size: 14.0, color: HTColors.primary),
              const SizedBox(width: 8.0),
              Text('WORKFORCE ROUTER', style: HTTypography.panelHeader),
              const Spacer(),
              Text(
                '${state.activeStaff}/${state.totalStaff} DEPLOYED',
                style: HTTypography.metricLabel.copyWith(color: HTColors.textSecondary),
              ),
            ],
          ),
        ),

        // Split view
        Expanded(
          child: Row(
            children: [
              // Left — Employee Roster
              Expanded(
                flex: 3,
                child: _EmployeeRoster(employees: employees),
              ),

              // Divider
              Container(
                width: 1.0,
                color: HTColors.border,
              ),

              // Right — Assignment Slots
              Expanded(
                flex: 2,
                child: _AssignmentSlots(employees: employees),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Employee Roster (Left Panel)
// ---------------------------------------------------------------------------

class _EmployeeRoster extends StatelessWidget {
  final List<Employee> employees;

  const _EmployeeRoster({required this.employees});

  @override
  Widget build(BuildContext context) {
    final grouped = <EmployeeType, List<Employee>>{};
    for (final emp in employees) {
      grouped.putIfAbsent(emp.type, () => []).add(emp);
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        for (final type in EmployeeType.values)
          if (grouped.containsKey(type)) ...[
            _TypeHeader(type: type, count: grouped[type]!.length),
            for (final emp in grouped[type]!)
              _EmployeeRow(employee: emp),
            const SizedBox(height: 8.0),
          ],
      ],
    );
  }
}

class _TypeHeader extends StatelessWidget {
  final EmployeeType type;
  final int count;

  const _TypeHeader({required this.type, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, top: 4.0),
      child: Row(
        children: [
          Text(
            '${type.icon} ${type.label.toUpperCase()}',
            style: HTTypography.badge.copyWith(
              color: HTColors.textSecondary,
              fontSize: 10.0,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
            decoration: BoxDecoration(
              color: HTColors.surfaceVariant,
              borderRadius: BorderRadius.circular(2.0),
            ),
            child: Text(
              '$count',
              style: HTTypography.badge.copyWith(color: HTColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final Employee employee;

  const _EmployeeRow({required this.employee});

  @override
  Widget build(BuildContext context) {
    final friction = employee.effectiveFriction;
    final hasFriction = friction > 0.0 && employee.assignment != WorkAssignment.idle;

    return Draggable<Employee>(
      data: employee,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: HTDecorations.focusedBox(),
          child: Text(employee.name, style: HTTypography.listTitle),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildRow(hasFriction, friction),
      ),
      child: _buildRow(hasFriction, friction),
    );
  }

  Widget _buildRow(bool hasFriction, double friction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: hasFriction
            ? HTColors.error.withValues(alpha: 0.06)
            : HTColors.surface,
        border: Border.all(
          color: hasFriction ? HTColors.error.withValues(alpha: 0.3) : HTColors.border,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(employee.name, style: HTTypography.listTitle),
          ),
          // Current assignment
          Text(
            employee.assignment.label,
            style: HTTypography.bodySmall.copyWith(
              color: employee.assignment == WorkAssignment.idle
                  ? HTColors.textMuted
                  : HTColors.textSecondary,
            ),
          ),
          if (hasFriction) ...[
            const SizedBox(width: 6.0),
            Tooltip(
              message: 'Friction: ${(friction * 100).round()}%',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                decoration: BoxDecoration(
                  color: HTColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: Text(
                  '⚠ ${(friction * 100).round()}%',
                  style: HTTypography.badge.copyWith(color: HTColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assignment Slots (Right Panel)
// ---------------------------------------------------------------------------

class _AssignmentSlots extends StatelessWidget {
  final List<Employee> employees;

  const _AssignmentSlots({required this.employees});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        for (final assignment in WorkAssignment.values)
          _AssignmentSlot(
            assignment: assignment,
            assignedCount: employees
                .where((e) => e.assignment == assignment)
                .length,
          ),
      ],
    );
  }
}

class _AssignmentSlot extends StatelessWidget {
  final WorkAssignment assignment;
  final int assignedCount;

  const _AssignmentSlot({
    required this.assignment,
    required this.assignedCount,
  });

  @override
  Widget build(BuildContext context) {
    final slotColor = switch (assignment) {
      WorkAssignment.rnd => HTColors.primary,
      WorkAssignment.foundry => HTColors.warning,
      WorkAssignment.qaFloor => HTColors.success,
      WorkAssignment.idle => HTColors.textMuted,
    };

    return DragTarget<Employee>(
      onAcceptWithDetails: (details) {
        GameStateProvider.read(context)
            .reassignEmployee(details.data.id, assignment);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 6.0),
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: isHovering
                ? slotColor.withValues(alpha: 0.1)
                : HTColors.surface,
            border: Border.all(
              color: isHovering ? slotColor : HTColors.border,
              width: isHovering ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: slotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  assignment.label.toUpperCase(),
                  style: HTTypography.listTitle.copyWith(
                    color: slotColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: slotColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3.0),
                ),
                child: Text(
                  '$assignedCount',
                  style: HTTypography.metricValue.copyWith(color: slotColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
