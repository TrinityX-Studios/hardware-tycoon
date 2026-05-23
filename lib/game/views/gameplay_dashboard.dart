/// Hardware Tycoon — TUI Desktop Workspace
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/game_state_provider.dart';

import 'components/global_top_menu_bar.dart';
import 'components/draggable_window.dart';
import 'components/silicon_grid_blueprint.dart';
import 'components/die_blueprint_data.dart';
import '../core/app_state.dart';
import '../core/game_state.dart';
import 'components/panels/workforce_router_panel.dart';
import 'components/panels/rnd_lab_panel.dart';
import 'components/panels/foundry_ops_panel.dart';
import 'components/panels/design_init_panel.dart';
import 'components/panels/music_deck_panel.dart';
import '../models/silicon_project.dart';
import '../managers/audio_manager.dart';

class GameplayDashboard extends StatefulWidget {
  final AppStateMachine appState;
  const GameplayDashboard({super.key, required this.appState});

  @override
  State<GameplayDashboard> createState() => _GameplayDashboardState();
}

class _GameplayDashboardState extends State<GameplayDashboard> {
  final List<String> _windowOrder = [
    'design_init',
    'workforce',
    'rnd',
    'foundry',
    'music_deck',
  ];
  final Set<String> _closedWindows = {'design_init', 'music_deck'};
  bool _isAssistedCompliance = false;

  // Silicon Breadboard Layout State
  List<PlacedComponent> _placedComponents = [];
  List<LineTrace> _traces = [];

  void _bringToFront(String id) {
    if (_windowOrder.isNotEmpty && _windowOrder.last != id) {
      setState(() {
        _windowOrder.remove(id);
        _windowOrder.add(id);
      });
    }
  }

  void _closeWindow(String id) {
    setState(() {
      _closedWindows.add(id);
    });
  }

  void _toggleWindow(String id) {
    setState(() {
      if (_closedWindows.contains(id)) {
        _closedWindows.remove(id);
        _bringToFront(id);
      } else {
        _closeWindow(id);
      }
    });
  }

  void _applyAssistedCompliance() {
    final alu = PlacedComponent(
      id: 'alu_assisted',
      type: 'ALU Core',
      gridPosition: const Offset(140.0, 100.0),
      gridSize: const Size(120.0, 80.0),
    );
    final reg = PlacedComponent(
      id: 'reg_assisted',
      type: 'Reg File',
      gridPosition: const Offset(140.0, 20.0),
      gridSize: const Size(120.0, 48.0),
    );
    final ctrl = PlacedComponent(
      id: 'ctrl_assisted',
      type: 'Ctrl Unit',
      gridPosition: const Offset(20.0, 20.0),
      gridSize: const Size(100.0, 60.0),
    );
    final dec = PlacedComponent(
      id: 'dec_assisted',
      type: 'Decoder',
      gridPosition: const Offset(20.0, 170.0),
      gridSize: const Size(80.0, 60.0),
    );
    final mem = PlacedComponent(
      id: 'mem_assisted',
      type: 'Mem Array',
      gridPosition: const Offset(200.0, 200.0),
      gridSize: const Size(180.0, 60.0),
    );

    // Setup traces connecting Reg Bus Pin to ALU Input Pin
    final regPin =
        reg.gridPosition +
        reg.pins.firstWhere((p) => p.name == 'Bus Pin').offset; // (200, 68)
    final aluInput =
        alu.gridPosition +
        alu.pins.firstWhere((p) => p.name == 'Input Pin').offset; // (160, 100)

    // Setup traces connecting Ctrl Out Pin to Decoder In Pin
    final ctrlOut =
        ctrl.gridPosition +
        ctrl.pins.firstWhere((p) => p.name == 'Out Pin').offset; // (40, 80)
    final decIn =
        dec.gridPosition +
        dec.pins.firstWhere((p) => p.name == 'In Pin').offset; // (60, 170)

    setState(() {
      _placedComponents = [alu, reg, ctrl, dec, mem];
      _traces = [
        LineTrace(start: regPin, end: aluInput, color: const Color(0xFFFBBF24)),
        LineTrace(start: ctrlOut, end: decIn, color: const Color(0xFFFBBF24)),
      ];
    });
  }

  int _getBusConnectionsCount(PlacedComponent bus) {
    List<Offset> startPoints = [];
    for (final trace in _traces) {
      final topDistStart = (trace.start.dy - bus.gridPosition.dy).abs();
      final topDistEnd = (trace.end.dy - bus.gridPosition.dy).abs();
      final bottomDistStart =
          (trace.start.dy - (bus.gridPosition.dy + bus.gridSize.height)).abs();
      final bottomDistEnd =
          (trace.end.dy - (bus.gridPosition.dy + bus.gridSize.height)).abs();

      final withinXStart =
          trace.start.dx >= bus.gridPosition.dx - 2.0 &&
          trace.start.dx <= bus.gridPosition.dx + bus.gridSize.width + 2.0;
      final withinXEnd =
          trace.end.dx >= bus.gridPosition.dx - 2.0 &&
          trace.end.dx <= bus.gridPosition.dx + bus.gridSize.width + 2.0;

      if (withinXStart && (topDistStart < 2.0 || bottomDistStart < 2.0)) {
        startPoints.add(trace.start);
      }
      if (withinXEnd && (topDistEnd < 2.0 || bottomDistEnd < 2.0)) {
        startPoints.add(trace.end);
      }
    }

    if (startPoints.isEmpty) return 0;

    List<Offset> visited = List<Offset>.from(startPoints);
    List<Offset> queue = List<Offset>.from(startPoints);

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);

      for (final trace in _traces) {
        if ((trace.start - curr).distance < 2.0) {
          if (!visited.any((v) => (v - trace.end).distance < 2.0)) {
            visited.add(trace.end);
            queue.add(trace.end);
          }
        }
        if ((trace.end - curr).distance < 2.0) {
          if (!visited.any((v) => (v - trace.start).distance < 2.0)) {
            visited.add(trace.start);
            queue.add(trace.start);
          }
        }
      }
    }

    Set<String> connectedComponentIds = {};
    for (final comp in _placedComponents) {
      if (comp.id == bus.id) continue;
      for (final pin in comp.pins) {
        final absPinPos = comp.gridPosition + pin.offset;
        if (visited.any((v) => (v - absPinPos).distance < 2.0)) {
          connectedComponentIds.add(comp.id);
        }
      }
    }

    return connectedComponentIds.length;
  }

  // Flood fill copper path search checking if two nodes connect via traces
  bool _isLayoutValid() {
    final state = GameStateProvider.of(context);
    if (state.currentDesigningProject?.scope == DesignScope.architecture) {
      return true;
    }
    final alu = _placedComponents
        .where((c) => c.type.contains('ALU Core'))
        .firstOrNull;
    final reg = _placedComponents
        .where((c) => c.type.contains('Reg File'))
        .firstOrNull;
    final ctrl = _placedComponents
        .where((c) => c.type == 'Ctrl Unit')
        .firstOrNull;
    final dec = _placedComponents.where((c) => c.type == 'Decoder').firstOrNull;

    if (alu == null || reg == null || ctrl == null || dec == null) return false;

    // Check reg to alu connection
    final regPin =
        reg.gridPosition +
        reg.pins.firstWhere((p) => p.name == 'Bus Pin').offset;
    final aluPins = alu.pins.map((p) => alu.gridPosition + p.offset).toList();
    bool regToAluWired = _areConnected(regPin, aluPins);

    // Check ctrl to decoder connection
    final ctrlPins = ctrl.pins
        .map((p) => ctrl.gridPosition + p.offset)
        .toList();
    final decPins = dec.pins.map((p) => dec.gridPosition + p.offset).toList();
    bool ctrlToDecWired = _areConnectedMultiple(ctrlPins, decPins);

    // Check Interconnect Bus connection limits (max 3 unique endpoints)
    final buses = _placedComponents
        .where((c) => c.type == 'Interconnect Bus')
        .toList();
    bool busLimitOk = true;
    for (final bus in buses) {
      final connectionsCount = _getBusConnectionsCount(bus);
      if (connectionsCount > 3) {
        busLimitOk = false;
        break;
      }
    }

    return regToAluWired && ctrlToDecWired && busLimitOk;
  }

  bool _areConnected(Offset start, List<Offset> targets) {
    List<Offset> visited = [start];
    List<Offset> queue = [start];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      if (targets.any((t) => (curr - t).distance < 2.0)) {
        return true;
      }

      for (final trace in _traces) {
        if ((trace.start - curr).distance < 2.0) {
          if (!visited.any((v) => (v - trace.end).distance < 2.0)) {
            visited.add(trace.end);
            queue.add(trace.end);
          }
        }
        if ((trace.end - curr).distance < 2.0) {
          if (!visited.any((v) => (v - trace.start).distance < 2.0)) {
            visited.add(trace.start);
            queue.add(trace.start);
          }
        }
      }
    }
    return false;
  }

  bool _areConnectedMultiple(List<Offset> starts, List<Offset> targets) {
    for (final start in starts) {
      if (_areConnected(start, targets)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);
    final isValid = _isLayoutValid();

    if (state.pendingCompletedAlerts.isNotEmpty) {
      final alertsCopy = List<String>.from(state.pendingCompletedAlerts);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.clearCompletedAlerts();
        for (final msg in alertsCopy) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF22D3EE), size: 14.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'PRODUCTION COMPLETED: $msg WAFER BATCH READY!',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22D3EE),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF020617),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0),
                side: const BorderSide(color: Color(0xFF22D3EE), width: 1.0),
              ),
            ),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: HTColors.background,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: _TerminalGridPainter()),
            ),
          ),

          // Workspace Windows
          for (final id in _windowOrder)
            if (!_closedWindows.contains(id)) _buildWindow(id),

          // Top Menu Bar (Pinned)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalTopMenuBar(
              appState: widget.appState,
              onToggleWindow: _toggleWindow,
              closedWindows: _closedWindows,
            ),
          ),

          // Pinned Design Mode Overlay (renders when player clicks design architecture)
          if (state.isDesigningArchitecture)
            Positioned.fill(
              top: 42.0,
              child: Container(
                color: HTColors.background.withValues(alpha: 0.96),
                child: Column(
                  children: [
                    Container(
                      color: HTColors.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.architecture,
                            color: HTColors.primary,
                          ),
                          const SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARCHITECTURE DESIGN MODE',
                                style: HTTypography.panelHeader,
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '${state.currentDesigningProject?.type.name.toUpperCase()} | ${state.currentDesigningProject?.paradigm.name.toUpperCase()} : "${state.currentDesigningProject?.projectName ?? "UNKNOWN"}"',
                                style: HTTypography.metricLabel.copyWith(
                                  color: HTColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (state.currentDesigningProject != null) ...[
                            ElevatedButton.icon(
                              icon: const Icon(Icons.flash_on, size: 16.0),
                              label: Text(
                                state.currentDesigningProject?.scope ==
                                        DesignScope.architecture
                                    ? 'REGISTER ARCHITECTURE SPEC'
                                    : 'EXECUTE TAPEOUT',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isValid
                                    ? HTColors.primary
                                    : HTColors.border,
                                foregroundColor: isValid
                                    ? HTColors.textOnPrimary
                                    : HTColors.textMuted,
                                textStyle: const TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: isValid
                                  ? () {
                                      AudioManager.instance.playSFX(
                                        'audio/sounds/success.wav',
                                      );
                                      final proj =
                                          state.currentDesigningProject!;
                                      state.tapeoutProject(proj);
                                      setState(() {
                                        _placedComponents = [];
                                        _traces = [];
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            proj.scope ==
                                                    DesignScope.architecture
                                                ? 'SPECIFICATION REGISTERED: ${proj.projectName} SYSTEM SPEC COMPLIANT.'
                                                : 'TAPEOUT REGISTERED: ${proj.projectName} SYSTEM INITIALIZED.',
                                          ),
                                          backgroundColor: HTColors.success,
                                        ),
                                      );
                                    }
                                  : () {
                                      AudioManager.instance.playSFX(
                                        'audio/sounds/error.wav',
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            '[PANIC] ADVISORY BLOCK: Resolve critical hardware verification failures before tapeout.',
                                          ),
                                          backgroundColor: HTColors.error,
                                        ),
                                      );
                                    },
                            ),
                            const SizedBox(width: 8.0),
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.download,
                                size: 16.0,
                                color: Color(0xFF22D3EE),
                              ),
                              label: const Text('EXPORT BLUEPRINT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF22D3EE),
                                side: const BorderSide(
                                  color: Color(0xFF22D3EE),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: isValid
                                  ? () {
                                      _showExportBlueprintDialog(
                                        context,
                                        state,
                                      );
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 12.0),
                          ],
                          OutlinedButton.icon(
                            icon: const Icon(Icons.close, size: 16.0),
                            label: const Text('ABORT DESIGN'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HTColors.error,
                              side: const BorderSide(color: HTColors.error),
                              textStyle: const TextStyle(
                                fontFamily: 'IBMPlexMono',
                              ),
                            ),
                            onPressed: () {
                              state.cancelDesigningProject();
                              setState(() {
                                _placedComponents = [];
                                _traces = [];
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: SiliconGridBlueprint(
                                components: _placedComponents,
                                traces: _traces,
                                onLayoutChanged: (components, traces) {
                                  setState(() {
                                    _placedComponents = components;
                                    _traces = traces;
                                  });
                                },
                              ),
                            ),
                          ),
                          Container(
                            width: 330.0,
                            decoration: const BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: HTColors.border,
                                  width: 1.0,
                                ),
                              ),
                              color: HTColors.surface,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMetricsCard(state),
                                const SizedBox(height: 12.0),
                                Text(
                                  'PLACEMENT ROUTINES',
                                  style: HTTypography.metricLabel,
                                ),
                                const SizedBox(height: 6.0),
                                _buildPlacementOptionButton(
                                  label: 'MANUAL COMPONENT PLACEMENT',
                                  isActive: !_isAssistedCompliance,
                                  onTap: () {
                                    setState(() {
                                      _isAssistedCompliance = false;
                                      _placedComponents = [];
                                      _traces = [];
                                    });
                                  },
                                  icon: Icons.edit_note,
                                ),
                                const SizedBox(height: 6.0),
                                _buildPlacementOptionButton(
                                  label: 'DESIGN TEAM ASSISTED COMPLIANCE',
                                  isActive: _isAssistedCompliance,
                                  onTap: () {
                                    setState(() {
                                      _isAssistedCompliance = true;
                                    });
                                    _applyAssistedCompliance();
                                  },
                                  icon: Icons.auto_awesome,
                                ),
                                const SizedBox(height: 12.0),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: _buildVerificationConsole(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.pendingBankruptcyWarning)
            _BankruptcyWarningOverlay(state: state),
          if (state.isOutOfBusiness)
            _OutOfBusinessOverlay(state: state, appState: widget.appState),
        ],
      ),
    );
  }

  Widget _buildWindow(String id) {
    final isFocused = _windowOrder.isNotEmpty && _windowOrder.last == id;

    switch (id) {
      case 'design_init':
        return DraggableWindow(
          key: const ValueKey('design_init'),
          title: 'ARCHITECT REGISTRY INITIALIZATION',
          icon: Icons.architecture,
          initialPosition: const Offset(60, 60),
          initialSize: const Size(900, 620),
          isFocused: isFocused,
          onFocus: () => _bringToFront(id),
          onClose: () => _closeWindow(id),
          child: DesignInitPanel(onClose: () => _closeWindow('design_init')),
        );
      case 'workforce':
        return DraggableWindow(
          key: const ValueKey('workforce'),
          title: 'WORKFORCE ROUTER',
          icon: Icons.people_outline,
          initialPosition: const Offset(32, 80),
          initialSize: const Size(450, 500),
          isFocused: isFocused,
          onFocus: () => _bringToFront(id),
          onClose: () => _closeWindow(id),
          child: const WorkforceRouterPanel(),
        );
      case 'rnd':
        return DraggableWindow(
          key: const ValueKey('rnd'),
          title: 'R&D LABORATORY',
          icon: Icons.science_outlined,
          initialPosition: const Offset(500, 80),
          initialSize: const Size(600, 600),
          isFocused: isFocused,
          onFocus: () => _bringToFront(id),
          onClose: () => _closeWindow(id),
          child: const RndLabPanel(),
        );
      case 'foundry':
        return DraggableWindow(
          key: const ValueKey('foundry'),
          title: 'FOUNDRY OPERATIONS',
          icon: Icons.precision_manufacturing_outlined,
          initialPosition: const Offset(32, 600),
          initialSize: const Size(800, 400),
          isFocused: isFocused,
          onFocus: () => _bringToFront(id),
          onClose: () => _closeWindow(id),
          child: const FoundryOpsPanel(),
        );
      case 'music_deck':
        return DraggableWindow(
          key: const ValueKey('music_deck'),
          title: 'CORE MUSIC DECK',
          icon: Icons.music_note,
          initialPosition: const Offset(820, 80),
          initialSize: const Size(320, 390),
          isFocused: isFocused,
          onFocus: () => _bringToFront(id),
          onClose: () => _closeWindow(id),
          child: const MusicDeckPanel(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMetricsCard(GameStateNotifier state) {
    final proj = state.currentDesigningProject;
    if (proj == null) return const SizedBox.shrink();

    double complexity = 100.0;
    if (proj.type == ChipTarget.gpu) complexity = 250.0;
    if (proj.type == ChipTarget.fpga) complexity = 450.0;

    if (proj.scope == DesignScope.coreUnit) complexity *= 2.0;
    if (proj.scope == DesignScope.productLiteral) complexity *= 4.0;

    final moodModifier = 0.5 + 0.5 * state.corporateMood;

    double pinMultiplier = 1.2;
    if (proj.casing == CasingType.PGA) pinMultiplier = 2.5;
    if (proj.casing == CasingType.BGA) pinMultiplier = 6.0;
    if (proj.casing == CasingType.LGA) pinMultiplier = 15.0;

    final targetFlops = (complexity * moodModifier) * pinMultiplier;

    // Total traces length calculation for impedance penalty
    double totalTraceLength = _traces.fold(
      0.0,
      (sum, trace) =>
          sum +
          (trace.end.dx - trace.start.dx).abs() +
          (trace.end.dy - trace.start.dy).abs(),
    );
    double impedanceFactor = 1.0;
    if (totalTraceLength > 600.0) {
      impedanceFactor = (1.0 - (totalTraceLength - 600.0) / 1500.0).clamp(
        0.65,
        1.0,
      );
    }

    final year = state.gameDate.year;
    String unit = 'KiloFLOPS';
    double scaledValue = targetFlops * impedanceFactor;

    if (year < 1980) {
      unit = 'KiloFLOPS';
      scaledValue = targetFlops * 1.5 * impedanceFactor;
    } else if (year >= 1980 && year < 2000) {
      unit = 'MegaFLOPS';
      scaledValue = targetFlops * 12.5 * impedanceFactor;
    } else if (year >= 2000 && year < 2020) {
      unit = 'GigaFLOPS';
      scaledValue = targetFlops * 250.0 * impedanceFactor;
    } else {
      unit = 'TeraFLOPS';
      scaledValue = targetFlops * 5000.0 * impedanceFactor;
    }

    return Container(
      decoration: HTDecorations.panelBox(),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, size: 14.0, color: HTColors.primary),
              const SizedBox(width: 6.0),
              Text(
                'ARCHITECTURE PROJECTION',
                style: HTTypography.panelHeader.copyWith(fontSize: 10.0),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          _buildMetricRow('COMPLEXITY', '${complexity.toStringAsFixed(0)} pts'),
          const SizedBox(height: 6.0),
          _buildMetricRow(
            'MOOD MODIFIER',
            '×${moodModifier.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6.0),
          _buildMetricRow(
            'PIN DENSITY MULT',
            '×${pinMultiplier.toStringAsFixed(1)}',
          ),

          if (impedanceFactor < 1.0) ...[
            const SizedBox(height: 6.0),
            _buildMetricRow(
              'IMPEDANCE MULT',
              '×${impedanceFactor.toStringAsFixed(2)}',
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: HTColors.border, height: 1.0),
          ),

          Text('ESTIMATED PERFORMANCE', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                scaledValue.toStringAsFixed(2),
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  color: HTColors.primary,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4.0),
              Text(
                unit,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  color: HTColors.textSecondary,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: HTTypography.metricLabel.copyWith(fontSize: 8.5)),
        Text(
          value,
          style: HTTypography.badge.copyWith(
            color: HTColors.textPrimary,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementOptionButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive
              ? HTColors.primary.withValues(alpha: 0.15)
              : HTColors.surface,
          border: Border.all(
            color: isActive ? HTColors.primary : HTColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14.0,
              color: isActive ? HTColors.primary : HTColors.textSecondary,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  color: isActive
                      ? HTColors.textPrimary
                      : HTColors.textSecondary,
                  fontSize: 8.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle,
                size: 10.0,
                color: HTColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationConsole() {
    final alu = _placedComponents
        .where((c) => c.type.contains('ALU Core'))
        .firstOrNull;
    final reg = _placedComponents
        .where((c) => c.type.contains('Reg File'))
        .firstOrNull;
    final ctrl = _placedComponents
        .where((c) => c.type == 'Ctrl Unit')
        .firstOrNull;
    final dec = _placedComponents.where((c) => c.type == 'Decoder').firstOrNull;

    bool aluOk = alu != null;
    bool regOk = reg != null;
    bool ctrlOk = ctrl != null;
    bool decOk = dec != null;

    // Check reg to alu connection
    bool regToAluWired = false;
    if (alu != null && reg != null) {
      final regPin =
          reg.gridPosition +
          reg.pins.firstWhere((p) => p.name == 'Bus Pin').offset;
      final aluPins = alu.pins.map((p) => alu.gridPosition + p.offset).toList();
      regToAluWired = _areConnected(regPin, aluPins);
    }

    // Check ctrl to decoder connection
    bool ctrlToDecWired = false;
    if (ctrl != null && dec != null) {
      final ctrlPins = ctrl.pins
          .map((p) => ctrl.gridPosition + p.offset)
          .toList();
      final decPins = dec.pins.map((p) => dec.gridPosition + p.offset).toList();
      ctrlToDecWired = _areConnectedMultiple(ctrlPins, decPins);
    }

    // Total traces length calculation
    double totalTraceLength = _traces.fold(
      0.0,
      (sum, trace) =>
          sum +
          (trace.end.dx - trace.start.dx).abs() +
          (trace.end.dy - trace.start.dy).abs(),
    );
    bool highImpedance = totalTraceLength > 600.0;

    // Check Interconnect Bus connection limits (max 3 unique endpoints)
    final buses = _placedComponents
        .where((c) => c.type == 'Interconnect Bus')
        .toList();
    bool busLimitOk = true;
    String? busStatusMessage;

    for (final bus in buses) {
      final count = _getBusConnectionsCount(bus);
      if (count > 3) {
        busLimitOk = false;
        busStatusMessage =
            '[ERR] BUS CAPACITY CEILING: Current Interconnect Bus multiplexer cannot route more than 3 system endpoints. Advance Bus R&D.';
      } else {
        busStatusMessage =
            '[PASS] BUS CAPACITY: Interconnect Bus multiplexer routing ($count/3 endpoints) is stable.';
      }
    }

    bool isValid =
        aluOk &&
        regOk &&
        ctrlOk &&
        decOk &&
        regToAluWired &&
        ctrlToDecWired &&
        busLimitOk;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        border: Border.all(color: HTColors.border),
        borderRadius: BorderRadius.circular(3.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, size: 12.0, color: HTColors.primary),
              const SizedBox(width: 6.0),
              Text(
                'ENGINEERING ADVISORY CONSOLE',
                style: HTTypography.panelHeader.copyWith(fontSize: 9.0),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          const Text(
            '[?] HARDWARE VERIFICATION PROTOCOL:',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 8.0,
              color: HTColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6.0),

          // 1. Core unit compliance log lines
          _buildConsoleLine(
            isPass: aluOk,
            passText: 'ALU Core detected at G-Grid coordinates.',
            failText: 'ALU Core is missing from grid layout.',
          ),
          _buildConsoleLine(
            isPass: regOk,
            passText: 'Register File detected at G-Grid coordinates.',
            failText: 'Register File is missing from grid layout.',
          ),
          _buildConsoleLine(
            isPass: ctrlOk,
            passText: 'Control Unit detected at G-Grid coordinates.',
            failText: 'Control Unit is missing from grid layout.',
          ),
          _buildConsoleLine(
            isPass: decOk,
            passText: 'Decoder block detected at G-Grid coordinates.',
            failText: 'Decoder block is missing from grid layout.',
          ),

          const SizedBox(height: 4.0),

          // 2. Data bus linkage
          _buildConsoleLine(
            isPass: regToAluWired,
            passText: 'ALU Core successfully bridged to Register File.',
            failText: 'Register File Terminal Pin is currently FLOATING.',
          ),

          // 3. Microcode execution linkage
          _buildConsoleLine(
            isPass: ctrlToDecWired,
            passText: 'Control Unit successfully bridged to Decoder.',
            failText: 'Missing mandatory microcode execution trace.',
          ),

          if (busStatusMessage != null) ...[
            const SizedBox(height: 4.0),
            Text(
              busStatusMessage,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 7.5,
                color: busLimitOk ? HTColors.success : HTColors.error,
              ),
            ),
          ],

          if (highImpedance) ...[
            const SizedBox(height: 4.0),
            Text(
              '[WARN] HIGH IMPEDANCE: Signal propagation path between core blocks is too long (${totalTraceLength.toInt()} units). Reducing base clock target.',
              style: const TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 7.5,
                color: Color(0xFFFBBF24),
              ),
            ),
          ],

          const SizedBox(height: 8.0),
          const Divider(color: HTColors.border, height: 1.0),
          const SizedBox(height: 8.0),

          // 4. Tapeout Blocked/Ready state
          Text(
            isValid
                ? '[READY] VERIFICATION COMPLETED: All silicon paths comply with industrial specification.'
                : '[WAIT] TAPEOUT BLOCKED: Resolve critical hardware connection logs to initialize clean-room fab.',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              color: isValid ? HTColors.success : HTColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportBlueprintDialog(
    BuildContext context,
    GameStateNotifier state,
  ) {
    String bpName = 'LAYOUT_${state.playerVerifiedLayouts.length + 1}';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3.0),
                side: const BorderSide(color: Color(0xFF22D3EE), width: 1.0),
              ),
              title: const Text(
                'EXPORT VERIFIED BLUEPRINT SCHEMA',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22D3EE),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASSIGN SCHEMATIC REGISTERED NAME:',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 8.5,
                      color: HTColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  TextField(
                    autofocus: true,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      color: HTColors.textPrimary,
                      fontSize: 11,
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: HTColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: HTColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF22D3EE)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 8.0,
                      ),
                    ),
                    onChanged: (val) => bpName = val,
                    controller: TextEditingController(text: bpName)
                      ..selection = TextSelection.collapsed(
                        offset: bpName.length,
                      ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HTColors.textSecondary,
                    side: const BorderSide(color: HTColors.border),
                  ),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cleanName = bpName.trim().toUpperCase();
                    if (cleanName.isNotEmpty) {
                      double complexity = 100.0;
                      final proj = state.currentDesigningProject;
                      if (proj != null) {
                        if (proj.type == ChipTarget.gpu) complexity = 250.0;
                        if (proj.type == ChipTarget.fpga) complexity = 450.0;
                        if (proj.scope == DesignScope.coreUnit) {
                          complexity *= 2.0;
                        }
                        if (proj.scope == DesignScope.productLiteral) {
                          complexity *= 4.0;
                        }
                      }

                      final moodModifier = 0.5 + 0.5 * state.corporateMood;
                      double totalTraceLength = _traces.fold(
                        0.0,
                        (sum, trace) =>
                            sum +
                            (trace.end.dx - trace.start.dx).abs() +
                            (trace.end.dy - trace.start.dy).abs(),
                      );
                      double impedanceFactor = totalTraceLength > 600.0
                          ? (1.0 - (totalTraceLength - 600.0) / 1500.0).clamp(
                              0.65,
                              1.0,
                            )
                          : 1.0;
                      double layoutFlops =
                          (complexity * moodModifier * 1.5) * impedanceFactor;

                      final layout = CustomDieLayout(
                        name: cleanName,
                        components: List<PlacedComponent>.from(
                          _placedComponents,
                        ),
                        traces: List<LineTrace>.from(_traces),
                        kiloFlops: layoutFlops,
                        gateComplexity: complexity.toInt(),
                        pathVerified: true,
                      );
                      state.addCustomLayout(layout);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'BLUEPRINT SCHEMA "$cleanName" EXPORTED TO SIMULATION REGISTRY.',
                          ),
                          backgroundColor: HTColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22D3EE),
                    foregroundColor: const Color(0xFF020617),
                  ),
                  child: const Text(
                    'EXPORT',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConsoleLine({
    required bool isPass,
    required String passText,
    required String failText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Text(
        isPass ? '[PASS] $passText' : '[FAIL] $failText',
        style: TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 7.5,
          color: isPass ? HTColors.success : HTColors.error,
        ),
      ),
    );
  }
}

class _TerminalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HTColors.border
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BankruptcyWarningOverlay extends StatefulWidget {
  final GameStateNotifier state;
  const _BankruptcyWarningOverlay({required this.state});

  @override
  State<_BankruptcyWarningOverlay> createState() => _BankruptcyWarningOverlayState();
}

class _BankruptcyWarningOverlayState extends State<_BankruptcyWarningOverlay> {
  bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.state.getDailyCostBreakdown();
    final double totalDailyCost = breakdown.values.fold(0.0, (sum, val) => sum + val);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Container(
            width: 480.0,
            decoration: BoxDecoration(
              color: HTColors.surface,
              border: Border.all(color: HTColors.warning, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: HTColors.warning.withValues(alpha: 0.2),
                  blurRadius: 20.0,
                  spreadRadius: 4.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: HTColors.warning, size: 24.0),
                    const SizedBox(width: 12.0),
                    Text(
                      'BANKRUPTCY WARNING',
                      style: HTTypography.panelHeader.copyWith(color: HTColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(color: HTColors.border, height: 1.0),
                const SizedBox(height: 16.0),
                
                Text(
                  'YOUR LIQUIDITY HAS FALLEN CRITICALLY LOW: ${_formatCurrency(widget.state.liquidity)}',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textPrimary,
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'BANKRUPTCY IS IMMINENT. YOU NEED TO RECONSIDER YOUR BUDGET SPENDING HABITS IMMEDIATELY OR THE ENTERPRISE WILL BE OUT OF BUSINESS.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textSecondary,
                    fontSize: 10.0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16.0),

                InkWell(
                  onTap: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: HTColors.surfaceVariant,
                      border: Border.all(color: HTColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isCollapsed ? Icons.chevron_right : Icons.keyboard_arrow_down,
                              color: HTColors.warning,
                              size: 16.0,
                            ),
                            const SizedBox(width: 8.0),
                            const Text(
                              'FINANCIAL DRAIN BREAKDOWN',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                color: HTColors.textPrimary,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'TOTAL: -${_formatCurrency(totalDailyCost)}/DAY',
                          style: const TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: HTColors.error,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!_isCollapsed) ...[
                  Container(
                    decoration: const BoxDecoration(
                      color: HTColors.background,
                      border: Border(
                        left: BorderSide(color: HTColors.border),
                        right: BorderSide(color: HTColors.border),
                        bottom: BorderSide(color: HTColors.border),
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBreakdownRow('BASE OPERATIONS', breakdown['base_facilities']!),
                        _buildBreakdownRow('R&D STAFF SALARIES', breakdown['rnd_staff']!),
                        _buildBreakdownRow('R&D OVERHEAD', breakdown['rnd_overhead']!),
                        _buildBreakdownRow('WORKFORCE UPKEEP', breakdown['ops_staff']!),
                        _buildBreakdownRow('COMPILER/VLIW LICENSES', breakdown['compiler']!),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24.0),

                ElevatedButton(
                  onPressed: () {
                    widget.state.clearBankruptcyWarning();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF78350F), // Amber 900
                    foregroundColor: HTColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0),
                      side: const BorderSide(color: HTColors.warning, width: 1.0),
                    ),
                  ),
                  child: const Text(
                    'ACKNOWLEDGE & RECONSIDER BUDGET',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              color: HTColors.textSecondary,
              fontSize: 9.0,
            ),
          ),
          Text(
            '-${_formatCurrency(value)}/day',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              color: value > 0.0 ? HTColors.error : HTColors.textMuted,
              fontSize: 9.0,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double val) {
    if (val < 0) {
      return '-\$${val.abs().toStringAsFixed(2)}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }
}

class _OutOfBusinessOverlay extends StatelessWidget {
  final GameStateNotifier state;
  final AppStateMachine appState;
  const _OutOfBusinessOverlay({required this.state, required this.appState});

  @override
  Widget build(BuildContext context) {
    final breakdown = state.getDailyCostBreakdown();
    final double totalDailyCost = breakdown.values.fold(0.0, (sum, val) => sum + val);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: Center(
          child: Container(
            width: 500.0,
            decoration: BoxDecoration(
              color: HTColors.surface,
              border: Border.all(color: HTColors.error, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: HTColors.error.withValues(alpha: 0.25),
                  blurRadius: 30.0,
                  spreadRadius: 6.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dangerous, color: HTColors.error, size: 28.0),
                    const SizedBox(width: 12.0),
                    Text(
                      'SYSTEM PANIC: INSOLVENCY DETECTED',
                      style: HTTypography.panelHeader.copyWith(
                        color: HTColors.error,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                const Divider(color: HTColors.border, height: 1.0),
                const SizedBox(height: 20.0),

                const Text(
                  'GAME OVER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.error,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'THE BOARD OF DIRECTORS HAS DECLARED BANKRUPTCY. YOUR OPERATIONS ARE CEASED, ALL TRADING SUSPENDED, AND THE CORE SILICON COMPLIANCE LABORATORY HAS BEEN SHUT DOWN PERMANENTLY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textSecondary,
                    fontSize: 10.0,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20.0),

                Container(
                  color: HTColors.background,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatRow('FINAL LIQUIDITY', _formatCurrency(state.liquidity), color: HTColors.error),
                      const SizedBox(height: 6.0),
                      _buildStatRow('FINAL VALUATION', _formatCurrency(state.stockValuation)),
                      const SizedBox(height: 6.0),
                      _buildStatRow('DAILY REVENUE RUN RATE', _formatCurrency(1400.0 + (state.totalGameDays * 2.5))),
                      const SizedBox(height: 6.0),
                      _buildStatRow('DAILY EXPENSE DRAIN', _formatCurrency(totalDailyCost), color: HTColors.error),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),

                ElevatedButton(
                  onPressed: () {
                    appState.goToMainMenu();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F1D1D), // Red 900
                    foregroundColor: HTColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2.0),
                      side: const BorderSide(color: HTColors.error, width: 1.0),
                    ),
                  ),
                  child: const Text(
                    'SHUTDOWN SIMULATION & RETURN TO MAIN MENU',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            color: HTColors.textSecondary,
            fontSize: 9.0,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            color: color ?? HTColors.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double val) {
    if (val < 0) {
      return '-\$${val.abs().toStringAsFixed(2)}';
    }
    return '\$${val.toStringAsFixed(2)}';
  }
}
