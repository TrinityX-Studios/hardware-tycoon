/// Hardware Tycoon — Game State Notifier
///
/// Central state management using vanilla ChangeNotifier with a sub-second
/// tick engine (100ms per tick, 10 ticks = 1 game day at 1× speed).
/// Financial scaffolding values are encapsulated for global multiplier
/// adjustment later.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/company_state.dart';
import '../models/silicon_project.dart';
import '../models/research_node.dart';

// ---------------------------------------------------------------------------
// Financial Configuration (adjustable macroeconomic scaffolding)
// ---------------------------------------------------------------------------

class FinancialConfig {
  final double startingLiquidity;
  final double startingCashflow;
  final double startingStockValuation;
  final double baseOperatingCost;

  const FinancialConfig({
    this.startingLiquidity = 500000.0,
    this.startingCashflow = 0.0,
    this.startingStockValuation = 4.20,
    this.baseOperatingCost = 1200.0,
  });

  /// Apply a global economic multiplier to all values.
  FinancialConfig withMultiplier(double multiplier) => FinancialConfig(
        startingLiquidity: startingLiquidity * multiplier,
        startingCashflow: startingCashflow * multiplier,
        startingStockValuation: startingStockValuation,
        baseOperatingCost: baseOperatingCost * multiplier,
      );
}

// ---------------------------------------------------------------------------
// Simulation Tick Constants
// ---------------------------------------------------------------------------

/// Engine runs at 100ms per tick. 10 ticks = 1 game day at 1× speed.
const Duration kTickInterval = Duration(milliseconds: 100);
const int kTicksPerGameDay = 10;

// ---------------------------------------------------------------------------
// Game State Notifier
// ---------------------------------------------------------------------------

class GameStateNotifier extends ChangeNotifier {
  GameStateNotifier({
    FinancialConfig? config,
  }) : _config = config ?? const FinancialConfig() {
    _initializeState();
  }

  final FinancialConfig _config;

  // -- Time --
  late DateTime _gameDate;
  DateTime get gameDate => _gameDate;
  int get currentGameYear => _gameDate.year;

  int _tickAccumulator = 0;
  int _totalGameDays = 0;
  int get totalGameDays => _totalGameDays;

  // -- Simulation Speed --
  SimSpeed _simSpeed = SimSpeed.normal;
  SimSpeed get simSpeed => _simSpeed;
  bool get isPaused => _simSpeed == SimSpeed.paused;

  Timer? _tickTimer;

  // -- Financials --
  late double _liquidity;
  double get liquidity => _liquidity;

  late double _netCashflow;
  double get netCashflow => _netCashflow;

  late double _stockValuation;
  double get stockValuation => _stockValuation;

  bool _isPublic = false;
  bool get isPublic => _isPublic;

  // -- Workforce --
  int get activeStaff => _employees.where((e) => e.assignment != WorkAssignment.idle).length;
  int get totalStaff => _employees.length;

  double _corporateMood = 0.78;
  double get corporateMood => _corporateMood;

  // -- R&D Automation Policies --
  AutomationPolicy _automationPolicy = AutomationPolicy.manual;
  AutomationPolicy get automationPolicy => _automationPolicy;

  String? _activeResearchNodeId;
  String? get activeResearchNodeId => _activeResearchNodeId;

  RndFundingTier _rndFunding = RndFundingTier.normal;
  RndFundingTier get rndFunding => _rndFunding;

  void setRndFunding(RndFundingTier tier) {
    _rndFunding = tier;
    notifyListeners();
  }

  // -- Collections --
  final List<ResearchGoal> _activeResearch = [];
  List<ResearchGoal> get activeResearch => List.unmodifiable(_activeResearch);

  final List<Employee> _employees = [];
  List<Employee> get employees => List.unmodifiable(_employees);

  final List<CleanRoom> _cleanRooms = [];
  List<CleanRoom> get cleanRooms => List.unmodifiable(_cleanRooms);

  final List<WaferBatch> _productionQueue = [];
  List<WaferBatch> get productionQueue => List.unmodifiable(_productionQueue);

  final List<WaferBatch> _completedProductionQueue = [];
  List<WaferBatch> get completedProductionQueue => List.unmodifiable(_completedProductionQueue);

  final List<String> _pendingCompletedAlerts = [];
  List<String> get pendingCompletedAlerts => List.unmodifiable(_pendingCompletedAlerts);

  void clearCompletedAlerts() {
    _pendingCompletedAlerts.clear();
  }

  // -- Foundry --
  double _waferYield = 0.42;
  double get waferYield => _waferYield;

  final List<YieldDataPoint> _yieldHistory = [];
  List<YieldDataPoint> get yieldHistory => List.unmodifiable(_yieldHistory);

  // -- Design Mode --
  bool _isDesigningArchitecture = false;
  bool get isDesigningArchitecture => _isDesigningArchitecture;

  SiliconProject? _currentDesigningProject;
  SiliconProject? get currentDesigningProject => _currentDesigningProject;

  final List<SiliconProject> _activeProductsRegistry = [];
  List<SiliconProject> get activeProductsRegistry => List.unmodifiable(_activeProductsRegistry);

  final List<SiliconProject> _savedArchitectures = [];
  List<SiliconProject> get savedArchitectures => List.unmodifiable(_savedArchitectures);

  /// Returns true if the player has taped out at least one Architecture-scope design.
  bool get hasCompletedArchitecture =>
      _savedArchitectures.isNotEmpty ||
      _activeProductsRegistry.any(
        (p) => p.scope == DesignScope.architecture && p.isTapedOut,
      );

  ResearchDepartment get researchDepartment => ResearchDepartment(this);

  /// Returns the dynamic historical maximum clock frequency in Hz based on completed research nodes on the R&D timeline.
  double get unlockedMaxFrequencyHz {
    double freq = 100000.0; // 100 KHz starting baseline

    if (isNodeUnlocked('fab_ttl')) {
      freq = 1000000.0; // 1 MHz
    }
    if (isNodeUnlocked('fab_mosfet')) {
      freq = 10000000.0; // 10 MHz
    }
    if (isNodeUnlocked('arch_8bit')) {
      freq = 20000000.0; // 20 MHz
    }
    if (isNodeUnlocked('arch_16bit')) {
      freq = 50000000.0; // 50 MHz
    }
    if (isNodeUnlocked('arch_risc')) {
      freq = 100000000.0; // 100 MHz
    }
    if (isNodeUnlocked('arch_32bit')) {
      freq = 250000000.0; // 250 MHz
    }
    if (isNodeUnlocked('arch_pipeline')) {
      freq = 1200000000.0; // 1.2 GHz
    }
    if (isNodeUnlocked('fab_cmos')) {
      freq = 3000000000.0; // 3.0 GHz
    }
    if (isNodeUnlocked('fab_euv_early')) {
      freq = 5000000000.0; // 5.0 GHz
    }

    return freq;
  }

  // -- Dynamic Sandbox Layouts Exports --
  final List<CustomDieLayout> _playerVerifiedLayouts = [];
  List<CustomDieLayout> get playerVerifiedLayouts => List.unmodifiable(_playerVerifiedLayouts);

  void addCustomLayout(CustomDieLayout layout) {
    _playerVerifiedLayouts.add(layout);
    notifyListeners();
  }

  // -- Dynamic State Notifier Bridge --
  bool isNodeUnlocked(String id) {
    try {
      final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == id);
      return node.progress >= 1.0;
    } catch (_) {
      return false;
    }
  }

  double get globalYieldMultiplier {
    double mult = 1.0;
    if (isNodeUnlocked('fab_phosphorus')) mult *= 1.12;
    if (isNodeUnlocked('fab_float_zone')) mult *= 1.15;
    return mult;
  }

  double get globalPerformanceMultiplier {
    double mult = 1.0;
    if (isNodeUnlocked('logic_rtl')) mult *= 1.20;
    if (isNodeUnlocked('logic_dtl')) mult *= 1.25;
    return mult;
  }

  void toggleDesignMode() {
    _isDesigningArchitecture = !_isDesigningArchitecture;
    notifyListeners();
  }

  void startDesigningProject(SiliconProject project) {
    _currentDesigningProject = project;
    _isDesigningArchitecture = true;
    notifyListeners();
  }

  void cancelDesigningProject() {
    _currentDesigningProject = null;
    _isDesigningArchitecture = false;
    notifyListeners();
  }

  void tapeoutProject(SiliconProject project) {
    final updated = SiliconProject(
      projectName: project.projectName,
      type: project.type,
      paradigm: project.paradigm,
      scope: project.scope,
      casing: project.casing,
      bitWidth: project.bitWidth,
      targetLithography: project.targetLithography,
      isRefresh: project.isRefresh,
      refreshedFromProjectName: project.refreshedFromProjectName,
      technicalDebtFactor: project.technicalDebtFactor,
      projectedFlops: project.projectedFlops,
      powerWatts: project.powerWatts,
      clockSpeedMhz: project.clockSpeedMhz,
      projectedYieldPct: project.projectedYieldPct,
      tapeoutCostTicks: project.tapeoutCostTicks,
      isTapedOut: true,
      ihs: project.ihs,
      customLayoutName: project.customLayoutName,
      parentArchitectureName: project.parentArchitectureName,
      hasFpu: project.hasFpu,
      hasMmx: project.hasMmx,
      hasSse: project.hasSse,
      hasDsp: project.hasDsp,
      hasCustomIsa: project.hasCustomIsa,
    );

    if (updated.scope == DesignScope.architecture) {
      _savedArchitectures.add(updated);
    } else {
      _activeProductsRegistry.add(updated);
      if (updated.paradigm == LicensingModel.proprietary) {
        _productionQueue.add(WaferBatch(
          id: 'wb_${DateTime.now().millisecondsSinceEpoch}',
          productName: updated.projectName,
          progress: 0.0,
          waferCount: 100, // standard batch
        ));
      }
    }

    _liquidity -= updated.tapeoutCostTicks;
    _currentDesigningProject = null;
    _isDesigningArchitecture = false;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Initialization
  // -------------------------------------------------------------------------

  void _initializeState() {
    _gameDate = DateTime(1960, 1, 1);
    _liquidity = _config.startingLiquidity;
    _netCashflow = _config.startingCashflow;
    _stockValuation = _config.startingStockValuation;

    // Seed initial research goals
    _activeResearch.addAll([
      ResearchGoal(
        id: 'rg_001',
        name: 'SILICON INGOT CRYSTALLIZATION',
        description: 'Czochralski process refinement for single-crystal ingots',
        category: ResearchCategory.crystallization,
        progress: 0.12,
        estimatedMonths: 8,
      ),
      ResearchGoal(
        id: 'rg_002',
        name: 'CONTACT PHOTOLITHOGRAPHY',
        description: 'UV mask alignment for 25μm feature resolution',
        category: ResearchCategory.photolithography,
        progress: 0.34,
        estimatedMonths: 12,
      ),
      ResearchGoal(
        id: 'rg_003',
        name: 'BORON DIFFUSION DOPING',
        description: 'P-type substrate doping uniformity improvement',
        category: ResearchCategory.doping,
        progress: 0.05,
        estimatedMonths: 6,
      ),
      ResearchGoal(
        id: 'rg_004',
        name: 'CERAMIC DIP PACKAGING',
        description: 'Dual inline package with gold wire bonding',
        category: ResearchCategory.packaging,
        progress: 0.67,
        estimatedMonths: 4,
      ),
    ]);

    // Seed employees
    _employees.addAll([
      Employee(id: 'emp_001', name: 'Dr. Nakamura', type: EmployeeType.architect, assignment: WorkAssignment.rnd),
      Employee(id: 'emp_002', name: 'M. Richardson', type: EmployeeType.architect, assignment: WorkAssignment.rnd),
      Employee(id: 'emp_003', name: 'J. Chen', type: EmployeeType.driverDev, assignment: WorkAssignment.rnd),
      Employee(id: 'emp_004', name: 'P. Mueller', type: EmployeeType.driverDev, assignment: WorkAssignment.rnd),
      Employee(id: 'emp_005', name: 'A. Kowalski', type: EmployeeType.driverDev, assignment: WorkAssignment.idle),
      Employee(id: 'emp_006', name: 'S. Yamamoto', type: EmployeeType.qa, assignment: WorkAssignment.qaFloor),
      Employee(id: 'emp_007', name: 'R. Petrov', type: EmployeeType.qa, assignment: WorkAssignment.qaFloor),
      Employee(id: 'emp_008', name: 'T. Andersen', type: EmployeeType.assemblyStaff, assignment: WorkAssignment.foundry),
      Employee(id: 'emp_009', name: 'K. Okonkwo', type: EmployeeType.assemblyStaff, assignment: WorkAssignment.foundry),
      Employee(id: 'emp_010', name: 'L. Dubois', type: EmployeeType.assemblyStaff, assignment: WorkAssignment.foundry),
      Employee(id: 'emp_011', name: 'H. Tanaka', type: EmployeeType.assemblyStaff, assignment: WorkAssignment.foundry),
      Employee(id: 'emp_012', name: 'C. Park', type: EmployeeType.assemblyStaff, assignment: WorkAssignment.idle),
    ]);

    // Seed clean rooms
    _cleanRooms.addAll([
      CleanRoom(id: 'cr_01', name: 'CLEAN ROOM A', capacityMax: 100, capacityUsed: 72, status: CleanRoomStatus.operational),
      CleanRoom(id: 'cr_02', name: 'CLEAN ROOM B', capacityMax: 80, capacityUsed: 45, status: CleanRoomStatus.operational),
      CleanRoom(id: 'cr_03', name: 'CLEAN ROOM C', capacityMax: 60, capacityUsed: 0, status: CleanRoomStatus.maintenance),
      CleanRoom(id: 'cr_04', name: 'CLEAN ROOM D', capacityMax: 120, capacityUsed: 98, status: CleanRoomStatus.operational),
    ]);

    // Seed production queue
    _productionQueue.addAll([
      WaferBatch(id: 'wb_01', productName: 'Germanium Transistor Array', progress: 0.78, waferCount: 50),
      WaferBatch(id: 'wb_02', productName: 'Logic Gate IC Prototype', progress: 0.23, waferCount: 25),
      WaferBatch(id: 'wb_03', productName: 'Silicon Diode Batch', progress: 0.91, waferCount: 100),
    ]);

    // Seed yield history (last 30 days)
    for (int i = 0; i < 30; i++) {
      _yieldHistory.add(YieldDataPoint(
        gameDayIndex: i,
        yieldPercent: 0.35 + (i * 0.003) + (i.isEven ? 0.02 : -0.01),
      ));
    }
  }

  // -------------------------------------------------------------------------
  // Simulation Engine
  // -------------------------------------------------------------------------

  /// Start the tick timer.
  void startSimulation() {
    _tickTimer?.cancel();
    if (!isPaused) {
      _tickTimer = Timer.periodic(kTickInterval, (_) => _onTick());
    }
    notifyListeners();
  }

  /// Stop the tick timer entirely.
  void stopSimulation() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Process one engine tick (100ms real-time).
  void _onTick() {
    if (isPaused) return;

    final ticksThisFrame = _simSpeed.multiplier;
    for (int i = 0; i < ticksThisFrame; i++) {
      _tickAccumulator++;

      // Advance game day
      if (_tickAccumulator >= kTicksPerGameDay) {
        _tickAccumulator = 0;
        _advanceOneDay();
      }

      // Sub-tick updates (smooth progress bar movement)
      _updateSubTick();
    }

    notifyListeners();
  }

  void _advanceOneDay() {
    _gameDate = _gameDate.add(const Duration(days: 1));
    _totalGameDays++;

    // Daily financial simulation
    double ipPassiveIncome = 0.0;
    for (final p in _activeProductsRegistry) {
      if (p.paradigm == LicensingModel.ipLicensing) {
        ipPassiveIncome += 250.0;
      }
    }
    final dailyRevenue = 1400.0 + (_totalGameDays * 2.5) + ipPassiveIncome;
    
    final rndStaffCount = _employees.where((e) => e.assignment == WorkAssignment.rnd).length;
    final otherStaffCount = totalStaff - rndStaffCount;
    final rndStaffCost = rndStaffCount * 45.0 * _rndFunding.upkeepMult;
    final otherStaffCost = otherStaffCount * 45.0;
    final rndLabOverhead = 200.0 * (_rndFunding.upkeepMult - 1.0);
    
    final dailyCost = _config.baseOperatingCost + rndStaffCost + otherStaffCost + rndLabOverhead;
    
    _netCashflow = dailyRevenue - dailyCost;
    _liquidity += _netCashflow;

    // Stock price drift
    if (_isPublic) {
      _stockValuation += (_netCashflow > 0 ? 0.03 : -0.05);
      _stockValuation = _stockValuation.clamp(0.01, 999999.0);
    }

    // Yield fluctuation
    _waferYield = (_waferYield + 0.001).clamp(0.0, 0.99);
    if (_totalGameDays % 7 == 0) {
      _waferYield = (_waferYield - 0.005).clamp(0.0, 0.99);
    }

    // Record yield history
    _yieldHistory.add(YieldDataPoint(
      gameDayIndex: _totalGameDays,
      yieldPercent: _waferYield,
    ));
    // Keep last 90 days only
    if (_yieldHistory.length > 90) {
      _yieldHistory.removeAt(0);
    }

    // Mood drift based on average friction
    if (_employees.isNotEmpty) {
      final avgFriction = _employees
              .map((e) => e.effectiveFriction)
              .reduce((a, b) => a + b) /
          _employees.length;
      _corporateMood = (_corporateMood - avgFriction * 0.01 + 0.005)
          .clamp(0.0, 1.0);
    }
  }

  void _updateSubTick() {
    // Smooth research progress advancement
    for (final goal in _activeResearch) {
      if (goal.progress < 1.0) {
        final researchStaff = _employees
            .where((e) =>
                e.assignment == WorkAssignment.rnd &&
                (e.type == EmployeeType.architect ||
                    e.type == EmployeeType.driverDev))
            .length;
        goal.progress = (goal.progress +
                0.00005 * researchStaff)
            .clamp(0.0, 1.0);
      }
    }

    // HistoricalTechTree research tick progress
    final researchStaff = _employees
        .where((e) =>
            e.assignment == WorkAssignment.rnd &&
            (e.type == EmployeeType.architect ||
                e.type == EmployeeType.driverDev))
        .length;

    if (_activeResearchNodeId != null) {
      try {
        final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == _activeResearchNodeId);
        if (node.progress < 1.0) {
          double penaltyFactor = 1.0;
          if (currentGameYear < node.historicalYear) {
            final int yearsAhead = node.historicalYear - currentGameYear;
            penaltyFactor += 0.5 * yearsAhead * (1.0 - _rndFunding.aotMitigation);
          }
          final double effectiveCostTicks = node.researchCostTicks * penaltyFactor;
          
          final speed = (0.5 + 0.5 * researchStaff) / (effectiveCostTicks * 10.0);
          node.progress = (node.progress + speed).clamp(0.0, 1.0);
          if (node.progress >= 1.0) {
            // Node completed! Unlock downstream nodes!
            node.isUnlocked = true;
            for (final other in HistoricalTechTree.nodes) {
              if (!other.isUnlocked && other.prerequisiteIds.isNotEmpty) {
                final allPrereqsDone = other.prerequisiteIds.every((pid) {
                  final p = HistoricalTechTree.nodes.firstWhere((x) => x.id == pid);
                  return p.progress >= 1.0;
                });
                if (allPrereqsDone) {
                  other.isUnlocked = true;
                }
              }
            }
            if (_automationPolicy == AutomationPolicy.fullyAutomated) {
              _autoSelectResearch();
            } else {
              _activeResearchNodeId = null;
            }
          }
        }
      } catch (_) {}
    } else if (_automationPolicy == AutomationPolicy.fullyAutomated) {
      _autoSelectResearch();
    }

    // Smooth production progress
    final List<WaferBatch> completedThisTick = [];
    for (final batch in _productionQueue) {
      if (batch.progress < 1.0) {
        final assemblyStaff = _employees
            .where((e) =>
                e.assignment == WorkAssignment.foundry &&
                e.type == EmployeeType.assemblyStaff)
            .length;
        batch.progress =
            (batch.progress + 0.00008 * assemblyStaff).clamp(0.0, 1.0);
        if (batch.progress >= 1.0) {
          completedThisTick.add(batch);
        }
      }
    }

    if (completedThisTick.isNotEmpty) {
      for (final batch in completedThisTick) {
        _productionQueue.remove(batch);
        _completedProductionQueue.add(WaferBatch(
          id: batch.id,
          productName: batch.productName,
          progress: 1.0,
          waferCount: batch.waferCount,
          yieldPercent: _waferYield,
        ));
        _pendingCompletedAlerts.add(batch.productName);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  void setSpeed(SimSpeed speed) {
    _simSpeed = speed;
    if (speed == SimSpeed.paused) {
      _tickTimer?.cancel();
      _tickTimer = null;
    } else if (_tickTimer == null || !_tickTimer!.isActive) {
      startSimulation();
    }
    notifyListeners();
  }

  void pause() => setSpeed(SimSpeed.paused);

  void play() => setSpeed(SimSpeed.normal);

  void togglePause() {
    if (isPaused) {
      play();
    } else {
      pause();
    }
  }

  void reassignEmployee(String employeeId, WorkAssignment newAssignment) {
    final idx = _employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _employees[idx].assignment = newAssignment;
      notifyListeners();
    }
  }

  void goPublic() {
    _isPublic = true;
    _stockValuation = _config.startingStockValuation;
    notifyListeners();
  }

  /// Formatted date string for display.
  String get formattedDate {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[_gameDate.month - 1]} ${_gameDate.day}, ${_gameDate.year}';
  }

  /// Tick progress within current day (0.0–1.0) for smooth UI interpolation.
  double get dayProgress => _tickAccumulator / kTicksPerGameDay;

  void setAutomationPolicy(AutomationPolicy policy) {
    _automationPolicy = policy;
    if (policy == AutomationPolicy.fullyAutomated) {
      _autoSelectResearch();
    }
    notifyListeners();
  }

  bool isNodeWithinHorizon(ResearchNode node) {
    int maxAllowedYear = currentGameYear + 3;
    return node.historicalYear <= maxAllowedYear;
  }

  bool canSelectResearchNode(String nodeId) {
    final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == nodeId);
    if (node.progress >= 1.0) return false;

    final prereqsMet = node.prerequisiteIds.every((pid) {
      final pre = HistoricalTechTree.nodes.firstWhere((n) => n.id == pid);
      return pre.progress >= 1.0;
    });
    if (!prereqsMet) return false;

    return isNodeWithinHorizon(node);
  }

  bool startResearch(String nodeId) {
    if (!canSelectResearchNode(nodeId)) return false;
    _activeResearchNodeId = nodeId;
    notifyListeners();
    return true;
  }

  void selectResearchNode(String id) {
    if (_automationPolicy == AutomationPolicy.fullyAutomated) return;
    startResearch(id);
  }

  void _autoSelectResearch() {
    try {
      final next = HistoricalTechTree.nodes.firstWhere((n) {
        final isCompleted = n.progress >= 1.0;
        final prereqsMet = n.prerequisiteIds.every((pid) {
          final pNode = HistoricalTechTree.nodes.firstWhere((x) => x.id == pid);
          return pNode.progress >= 1.0;
        });
        return !isCompleted && prereqsMet && isNodeWithinHorizon(n);
      });
      _activeResearchNodeId = next.id;
    } catch (_) {
      _activeResearchNodeId = null;
    }
  }

  @override
  void dispose() {
    stopSimulation();
    super.dispose();
  }
}

class ResearchDepartment {
  final GameStateNotifier _state;
  ResearchDepartment(this._state);

  double get unlockedMaxFrequencyHz => _state.unlockedMaxFrequencyHz;
}
