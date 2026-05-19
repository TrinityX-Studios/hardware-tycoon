/// Hardware Tycoon — Phase 1 UI Data Models
///
/// Lightweight, strongly-typed data classes consumed by the UI layer.
/// These are intentionally decoupled from the backend simulation models
/// in `lib/game/` so the frontend can evolve independently.
library;

import 'dart:ui';

// ---------------------------------------------------------------------------
// Simulation Speed
// ---------------------------------------------------------------------------

enum SimSpeed {
  paused('Paused', 0),
  normal('1×', 1),
  fast('2×', 2),
  ultrafast('4×', 4);

  const SimSpeed(this.label, this.multiplier);
  final String label;
  final int multiplier;
}

// ---------------------------------------------------------------------------
// Research & Development
// ---------------------------------------------------------------------------

enum ResearchCategory {
  crystallization('Crystallization', Color(0xFF3B82F6)),
  photolithography('Photolithography', Color(0xFFA78BFA)),
  doping('Doping', Color(0xFF34D399)),
  packaging('Packaging', Color(0xFFFBBF24));

  const ResearchCategory(this.label, this.color);
  final String label;
  final Color color;
}

class ResearchGoal {
  final String id;
  final String name;
  final String description;
  final ResearchCategory category;
  double progress; // 0.0 – 1.0
  final int estimatedMonths;

  ResearchGoal({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.progress = 0.0,
    this.estimatedMonths = 6,
  });

  ResearchGoal copyWith({double? progress}) {
    return ResearchGoal(
      id: id,
      name: name,
      description: description,
      category: category,
      progress: progress ?? this.progress,
      estimatedMonths: estimatedMonths,
    );
  }
}

// ---------------------------------------------------------------------------
// Workforce
// ---------------------------------------------------------------------------

enum EmployeeType {
  architect('Architect', '🏗️'),
  driverDev('Driver Dev', '💻'),
  qa('Q/A', '🔍'),
  assemblyStaff('Assembly', '🔧');

  const EmployeeType(this.label, this.icon);
  final String label;
  final String icon;
}

enum WorkAssignment {
  rnd('R&D Lab'),
  foundry('Foundry'),
  qaFloor('QA Floor'),
  idle('Idle');

  const WorkAssignment(this.label);
  final String label;
}

class Employee {
  final String id;
  final String name;
  final EmployeeType type;
  WorkAssignment assignment;
  final double friction; // 0.0 = perfect fit, 1.0 = fully misassigned

  Employee({
    required this.id,
    required this.name,
    required this.type,
    this.assignment = WorkAssignment.idle,
    this.friction = 0.0,
  });

  /// Calculate friction penalty based on type vs assignment mismatch.
  double get effectiveFriction {
    switch (type) {
      case EmployeeType.architect:
        return assignment == WorkAssignment.rnd ? 0.0 : 0.6;
      case EmployeeType.driverDev:
        return assignment == WorkAssignment.rnd ? 0.0 : 0.4;
      case EmployeeType.qa:
        return assignment == WorkAssignment.qaFloor ? 0.0 : 0.5;
      case EmployeeType.assemblyStaff:
        return assignment == WorkAssignment.foundry ? 0.0 : 0.7;
    }
  }

  Employee copyWith({WorkAssignment? assignment}) {
    return Employee(
      id: id,
      name: name,
      type: type,
      assignment: assignment ?? this.assignment,
      friction: friction,
    );
  }
}

// ---------------------------------------------------------------------------
// Foundry Operations
// ---------------------------------------------------------------------------

enum CleanRoomStatus {
  operational('Operational', Color(0xFF34D399)),
  maintenance('Maintenance', Color(0xFFFBBF24)),
  offline('Offline', Color(0xFFF87171));

  const CleanRoomStatus(this.label, this.color);
  final String label;
  final Color color;
}

class CleanRoom {
  final String id;
  final String name;
  CleanRoomStatus status;
  final int capacityMax;
  int capacityUsed;

  CleanRoom({
    required this.id,
    required this.name,
    this.status = CleanRoomStatus.operational,
    required this.capacityMax,
    this.capacityUsed = 0,
  });

  double get utilizationPercent =>
      capacityMax > 0 ? capacityUsed / capacityMax : 0.0;
}

class WaferBatch {
  final String id;
  final String productName;
  double progress; // 0.0 – 1.0
  final int waferCount;
  final double yieldPercent;

  WaferBatch({
    required this.id,
    required this.productName,
    this.progress = 0.0,
    required this.waferCount,
    this.yieldPercent = 0.42,
  });
}

// ---------------------------------------------------------------------------
// Historical Data Point (for fl_chart)
// ---------------------------------------------------------------------------

class YieldDataPoint {
  final int gameDayIndex;
  final double yieldPercent;

  const YieldDataPoint({
    required this.gameDayIndex,
    required this.yieldPercent,
  });
}

// ---------------------------------------------------------------------------
// R&D Automation Policies
// ---------------------------------------------------------------------------

enum AutomationPolicy {
  manual('MANUAL'),
  hybrid('HYBRID'),
  fullyAutomated('FULLY AUTOMATED');

  const AutomationPolicy(this.label);
  final String label;
}

// ---------------------------------------------------------------------------
// R&D Funding Policies
// ---------------------------------------------------------------------------

enum RndFundingTier {
  normal('NORMAL', 1.0, 0.0),
  accelerated('ACCELERATED', 3.0, 0.25),
  crash('CRASH PROGRAM', 8.0, 0.50);

  const RndFundingTier(this.label, this.upkeepMult, this.aotMitigation);
  final String label;
  final double upkeepMult;
  final double aotMitigation;
}
