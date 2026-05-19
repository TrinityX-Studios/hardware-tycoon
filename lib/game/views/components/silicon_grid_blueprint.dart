/// Hardware Tycoon — SiliconGridBlueprint
///
/// CustomPainter-based interactive silicon breadboard editor sandbox.
/// Allows placing custom CPU microarchitectural core blocks, routing copper traces,
/// magnetic snapping to specific logical Terminal Pins, and real-time validation feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../core/theme.dart';
import '../../core/game_state_provider.dart';
import '../../models/research_node.dart';
import '../../models/silicon_project.dart';
import 'die_blueprint_data.dart';

class SiliconGridBlueprint extends StatefulWidget {
  final List<PlacedComponent> components;
  final List<LineTrace> traces;
  final Function(List<PlacedComponent>, List<LineTrace>) onLayoutChanged;

  const SiliconGridBlueprint({
    super.key,
    required this.components,
    required this.traces,
    required this.onLayoutChanged,
  });

  @override
  State<SiliconGridBlueprint> createState() => _SiliconGridBlueprintState();
}

class _SiliconGridBlueprintState extends State<SiliconGridBlueprint> {
  String _activeMode = 'move'; // 'move', 'wire', 'erase', 'pan'
  String? _selectedDockType; // e.g. 'ALU Core'
  Offset? _currentMousePosition;

  // Dragging components state
  PlacedComponent? _draggingComponent;
  Offset? _dragOffset;

  // Active wiring state
  Offset? _activeWireStart;
  PlacedComponent? _activeWireSourceComponent;
  TerminalPin? _activeWireSourcePin;

  // Hover states for tooltips/visual highlight
  PlacedComponent? _hoveredComponent;
  TerminalPin? _hoveredPin;
  LineTrace? _hoveredTrace;

  static const double _gridSpacing = 20.0;

  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  double _snap(double value) {
    return (value / _gridSpacing).roundToDouble() * _gridSpacing;
  }

  Offset _snapOffset(Offset offset) {
    return Offset(_snap(offset.dx), _snap(offset.dy));
  }

  bool _isResearchCompleted(BuildContext context, String id) {
    try {
      final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == id);
      return node.progress >= 1.0;
    } catch (_) {
      return false;
    }
  }

  // Snaps pos to nearby component pin if within magnetic radius
  SnapPinResult? _findNearbyPin(Offset logicalPos) {
    for (final comp in widget.components) {
      if (comp.type == 'Interconnect Bus') {
        // Continuous physical bus rail snapping along top and bottom edges!
        final topDist = (logicalPos.dy - comp.gridPosition.dy).abs();
        final bottomDist = (logicalPos.dy - (comp.gridPosition.dy + comp.gridSize.height)).abs();
        final withinX = logicalPos.dx >= comp.gridPosition.dx - 8.0 && logicalPos.dx <= comp.gridPosition.dx + comp.gridSize.width + 8.0;

        if (withinX) {
          if (topDist < 16.0) {
            final clampedX = logicalPos.dx.clamp(comp.gridPosition.dx, comp.gridPosition.dx + comp.gridSize.width);
            final snappedX = _snap(clampedX);
            final absPinPos = Offset(snappedX, comp.gridPosition.dy);
            return SnapPinResult(
              comp,
              TerminalPin('Bus Top Rail', absPinPos - comp.gridPosition),
              absPinPos,
            );
          }
          if (bottomDist < 16.0) {
            final clampedX = logicalPos.dx.clamp(comp.gridPosition.dx, comp.gridPosition.dx + comp.gridSize.width);
            final snappedX = _snap(clampedX);
            final absPinPos = Offset(snappedX, comp.gridPosition.dy + comp.gridSize.height);
            return SnapPinResult(
              comp,
              TerminalPin('Bus Bottom Rail', absPinPos - comp.gridPosition),
              absPinPos,
            );
          }
        }
      } else {
        // Standard discrete pins snapping
        for (final pin in comp.pins) {
          final absPinPos = comp.gridPosition + pin.offset;
          if ((absPinPos - logicalPos).distance < 16.0) {
            return SnapPinResult(comp, pin, absPinPos);
          }
        }
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);
    final currentProj = state.currentDesigningProject;
    final isEditable = currentProj != null &&
        (currentProj.scope == DesignScope.architecture ||
            currentProj.scope == DesignScope.coreUnit ||
            currentProj.scope == DesignScope.productLiteral);

    // Dynamic layout boundary scales procedurally based on tech research parameter
    final hasFineLine = _isResearchCompleted(context, 'lithography_fine_line');
    final double logicalWidth = hasFineLine ? 1000.0 : 400.0;
    final double logicalHeight = hasFineLine ? 800.0 : 300.0;

    final String activeBitLabel = currentProj?.bitWidth.label ?? '8-BIT';

    // List of architectural blocks for the Dock
    final dockItems = [
      _DockItemData(
        type: '$activeBitLabel ALU Core',
        size: const Size(120.0, 80.0),
        color: const Color(0xFF22D3EE),
        prereqId: 'arch_alu',
        prereqName: 'ALU Core',
      ),
      _DockItemData(
        type: 'Ctrl Unit',
        size: const Size(100.0, 60.0),
        color: const Color(0xFF34D399),
      ),
      _DockItemData(
        type: '$activeBitLabel Reg File',
        size: const Size(120.0, 48.0),
        color: const Color(0xFFA78BFA),
        prereqId: 'arch_8bit',
        prereqName: '8-bit Architecture',
      ),
      _DockItemData(
        type: 'Mem Array',
        size: const Size(180.0, 60.0),
        color: const Color(0xFF60A5FA),
      ),
      _DockItemData(
        type: 'Decoder',
        size: const Size(80.0, 60.0),
        color: const Color(0xFFFBBF24),
      ),
      _DockItemData(
        type: 'Interconnect Bus',
        size: const Size(240.0, 20.0),
        color: const Color(0xFFD946EF), // Neon purple
        prereqId: 'arch_central_bus',
        prereqName: 'Central Interconnect Bus',
      ),
      if (_isResearchCompleted(context, 'math_coprocessor') && (currentProj?.hasFpu == true))
        _DockItemData(
          type: 'Basic Float Compute Point (FPU)',
          size: const Size(140.0, 70.0),
          color: const Color(0xFFF472B6),
          prereqId: 'math_coprocessor',
          prereqName: 'Math Coprocessor',
        ),
    ];

    return Container(
      decoration: HTDecorations.panelBox(),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: HTColors.border, width: 1.0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.developer_board, size: 14.0, color: HTColors.primary),
                const SizedBox(width: 8.0),
                Text('INTERACTIVE SILICON BREADBOARD SANDBOX', style: HTTypography.panelHeader),
                const Spacer(),
                Text(
                  !isEditable
                      ? '[ READ-ONLY PREVIEW MODE ]'
                      : (_selectedDockType != null
                          ? 'SELECT: $_selectedDockType • TAP GRID TO PLACE'
                          : 'MODE: ${_activeMode.toUpperCase()}'),
                  style: HTTypography.metricLabel.copyWith(
                    color: !isEditable ? HTColors.error : HTColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Main Editor Space (Dock + Canvas Viewport)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Component Dock + Placement Routines Panel
                Container(
                  width: 170.0,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: HTColors.border, width: 1.0)),
                    color: Color(0xFF0F172A),
                  ),
                  child: !isEditable
                      ? Container(
                          padding: const EdgeInsets.all(12.0),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(Icons.lock, size: 28.0, color: HTColors.error),
                              SizedBox(height: 12.0),
                              Text(
                                'SANDBOX LOCKED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                  color: HTColors.error,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'BREADBOARD INTERACTIVE NODE CONFIGURATION IS ONLY ACCESSIBLE WHEN EXECUTING "DESIGN NEW ARCHITECTURE" OR ASSEMBLING A "PRODUCT LITERAL" FLOOR-PLAN LAYOUT.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 7.5,
                                  color: HTColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Component Dock (scrollable)
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(8.0),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text('COMPONENT DOCK', style: HTTypography.metricLabel),
                                  ),
                                  ...dockItems.map((item) {
                                    final isUnlocked = item.prereqId == null || _isResearchCompleted(context, item.prereqId!);
                                    final isSelected = _selectedDockType == item.type;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        onTap: isUnlocked
                                            ? () {
                                                setState(() {
                                                  if (isSelected) {
                                                    _selectedDockType = null;
                                                  } else {
                                                    _selectedDockType = item.type;
                                                    _activeMode = 'move'; // reset standard wire/erase/pan
                                                  }
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? item.color.withValues(alpha: 0.2)
                                                : isUnlocked
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFF0F172A),
                                            border: Border.all(
                                              color: isSelected
                                                  ? item.color
                                                  : isUnlocked
                                                      ? HTColors.border
                                                      : HTColors.border.withValues(alpha: 0.3),
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                            borderRadius: BorderRadius.circular(3.0),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.type,
                                                      style: TextStyle(
                                                        fontFamily: 'IBMPlexMono',
                                                        fontSize: 10.0,
                                                        fontWeight: FontWeight.bold,
                                                        color: isUnlocked ? HTColors.textPrimary : HTColors.textMuted,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isUnlocked)
                                                    const Icon(Icons.lock, size: 10.0, color: HTColors.error)
                                                  else
                                                    Icon(Icons.add_box, size: 10.0, color: item.color),
                                                ],
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                isUnlocked
                                                    ? '${item.size.width.toInt()}×${item.size.height.toInt()} UNITS'
                                                    : 'REQS: ${item.prereqName}',
                                                style: TextStyle(
                                                  fontFamily: 'IBMPlexMono',
                                                  fontSize: 7.5,
                                                  color: isUnlocked ? HTColors.textSecondary : HTColors.error.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // 2. Viewport wrapping fixed sized layout in an InteractiveViewer
                Expanded(
                  child: Container(
                    color: const Color(0xFF020617),
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(1000.0),
                      minScale: 0.5,
                      maxScale: 2.5,
                      transformationController: _transformationController,
                      panEnabled: true, // Always allow two-finger panning!
                      scaleEnabled: true, // Always allow pinch-zooming!
                      child: Center(
                        child: Container(
                          width: logicalWidth,
                          height: logicalHeight,
                          margin: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: HTColors.border, width: 1.5),
                          ),
                          child: MouseRegion(
                            onHover: !isEditable ? null : (event) => _onHover(event),
                            onExit: !isEditable ? null : (_) => _clearHover(),
                            child: GestureDetector(
                              // Intercept single-pointer events only if NOT in pan mode and board is editable!
                              onTapDown: (!isEditable || _activeMode == 'pan') ? null : (details) => _onTapDown(details, logicalWidth, logicalHeight),
                              onSecondaryTapDown: (!isEditable || _activeMode == 'pan') ? null : (details) => _onRightClick(details),
                              onPanStart: (!isEditable || _activeMode == 'pan') ? null : (details) => _onPanStart(details),
                              onPanUpdate: (!isEditable || _activeMode == 'pan') ? null : (details) => _onPanUpdate(details, logicalWidth, logicalHeight),
                              onPanEnd: (!isEditable || _activeMode == 'pan') ? null : _onPanEnd,
                              child: CustomPaint(
                                size: Size(logicalWidth, logicalHeight),
                                painter: _BreadboardPainter(
                                  components: widget.components,
                                  traces: widget.traces,
                                  activeMode: _activeMode,
                                  selectedDockType: _selectedDockType,
                                  currentMousePos: _currentMousePosition,
                                  activeWireStart: _activeWireStart,
                                  hoveredComponent: _hoveredComponent,
                                  hoveredPin: _hoveredPin,
                                  hoveredTrace: _hoveredTrace,
                                  dockItems: dockItems,
                                  logicalWidth: logicalWidth,
                                  logicalHeight: logicalHeight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: HTColors.border, width: 1.0)),
              color: Color(0xFF0F172A),
            ),
            child: !isEditable
                ? const Center(
                    child: Text(
                      '[ BREADBOARD INTERACTION LOCKED — VIEW-ONLY MODE ]',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        color: HTColors.textMuted,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToolbarButton(
                        label: 'MOVE COMPONENT',
                        icon: Icons.open_with,
                        isActive: _activeMode == 'move' && _selectedDockType == null,
                        onTap: () {
                          setState(() {
                            _activeMode = 'move';
                            _selectedDockType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _buildToolbarButton(
                        label: 'WIRE TERMINALS',
                        icon: Icons.settings_ethernet,
                        isActive: _activeMode == 'wire' && _selectedDockType == null,
                        onTap: () {
                          setState(() {
                            _activeMode = 'wire';
                            _selectedDockType = null;
                            _activeWireStart = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _buildToolbarButton(
                        label: 'ERASER TOOL',
                        icon: Icons.delete_sweep,
                        isActive: _activeMode == 'erase' && _selectedDockType == null,
                        onTap: () {
                          setState(() {
                            _activeMode = 'erase';
                            _selectedDockType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8.0),
                      _buildToolbarButton(
                        label: 'PAN VIEWPORT',
                        icon: Icons.pan_tool,
                        isActive: _activeMode == 'pan' && _selectedDockType == null,
                        onTap: () {
                          setState(() {
                            _activeMode = 'pan';
                            _selectedDockType = null;
                          });
                        },
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 12),
                        label: const Text('CLEAR BOARD'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: HTColors.error,
                          side: const BorderSide(color: HTColors.error),
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                          textStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.0, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          widget.onLayoutChanged([], []);
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isActive ? HTColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isActive ? HTColors.primary : HTColors.border,
            width: isActive ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12.0, color: isActive ? HTColors.primary : HTColors.textSecondary),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 8.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? HTColors.textPrimary : HTColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHover(PointerHoverEvent event) {
    // Local position is already logical coordinates due to fixed-size canvas child!
    final logical = event.localPosition;
    setState(() {
      _currentMousePosition = logical;
    });

    // Check hovered elements
    PlacedComponent? hitComp;
    for (final comp in widget.components) {
      if (comp.bounds.contains(logical)) {
        hitComp = comp;
        break;
      }
    }

    TerminalPin? hitPin;
    if (hitComp != null) {
      if (hitComp.type == 'Interconnect Bus') {
        // Find if hovering top or bottom bus rail snap line
        final topDist = (logical.dy - hitComp.gridPosition.dy).abs();
        final bottomDist = (logical.dy - (hitComp.gridPosition.dy + hitComp.gridSize.height)).abs();
        final withinX = logical.dx >= hitComp.gridPosition.dx - 8.0 && logical.dx <= hitComp.gridPosition.dx + hitComp.gridSize.width + 8.0;

        if (withinX) {
          if (topDist < 10.0) {
            hitPin = TerminalPin('Bus Top Rail', Offset(logical.dx - hitComp.gridPosition.dx, 0.0));
          } else if (bottomDist < 10.0) {
            hitPin = TerminalPin('Bus Bottom Rail', Offset(logical.dx - hitComp.gridPosition.dx, hitComp.gridSize.height));
          }
        }
      } else {
        for (final pin in hitComp.pins) {
          final absPinPos = hitComp.gridPosition + pin.offset;
          if ((absPinPos - logical).distance < 10.0) {
            hitPin = pin;
            break;
          }
        }
      }
    }

    LineTrace? hitTrace;
    if (hitComp == null && hitPin == null) {
      for (final trace in widget.traces) {
        if (_distanceToSegment(logical, trace.start, trace.end) < 8.0) {
          hitTrace = trace;
          break;
        }
      }
    }

    if (hitComp != _hoveredComponent || hitPin != _hoveredPin || hitTrace != _hoveredTrace) {
      setState(() {
        _hoveredComponent = hitComp;
        _hoveredPin = hitPin;
        _hoveredTrace = hitTrace;
      });
    }
  }

  void _clearHover() {
    setState(() {
      _currentMousePosition = null;
      _hoveredComponent = null;
      _hoveredPin = null;
      _hoveredTrace = null;
    });
  }

  void _onTapDown(TapDownDetails details, double logicalWidth, double logicalHeight) {
    final logical = details.localPosition;

    // ERASER MODE CLICK
    if (_activeMode == 'erase') {
      _eraseAt(logical);
      return;
    }

    // COMPONENT PLACEMENT MODE CLICK
    if (_selectedDockType != null) {
      final size = _getSizeForType(_selectedDockType!);
      final snappedOrigin = _snapOffset(logical - Offset(size.width / 2, size.height / 2));

      // Bounds validation
      if (snappedOrigin.dx < 0 ||
          snappedOrigin.dy < 0 ||
          snappedOrigin.dx + size.width > logicalWidth ||
          snappedOrigin.dy + size.height > logicalHeight) {
        return;
      }

      // Check collision with other components
      final rect = Rect.fromLTWH(snappedOrigin.dx, snappedOrigin.dy, size.width, size.height);
      bool overlaps = false;
      for (final comp in widget.components) {
        if (comp.bounds.overlaps(rect)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        final newComp = PlacedComponent(
          id: '${_selectedDockType!.replaceAll(' ', '_').toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
          type: _selectedDockType!,
          gridPosition: snappedOrigin,
          gridSize: size,
        );

        final updated = List<PlacedComponent>.from(widget.components)..add(newComp);
        widget.onLayoutChanged(updated, widget.traces);

        setState(() {
          _selectedDockType = null; // Autoreset selection after placement
        });
      }
    }
  }

  void _onRightClick(TapDownDetails details) {
    final logical = details.localPosition;
    _eraseAt(logical);
  }

  void _eraseAt(Offset logical) {
    PlacedComponent? toRemove;
    for (final comp in widget.components) {
      if (comp.bounds.contains(logical)) {
        toRemove = comp;
        break;
      }
    }

    if (toRemove != null) {
      // Remove component and all wire traces bound to its ID or inside its area
      final compId = toRemove.id;
      final updatedComps = widget.components.where((c) => c.id != compId).toList();
      final updatedTraces = widget.traces.where((trace) {
        // Discard traces whose start or end are on this component's pins
        bool startOnComp = toRemove!.bounds.contains(trace.start);
        bool endOnComp = toRemove.bounds.contains(trace.end);
        return !startOnComp && !endOnComp;
      }).toList();

      widget.onLayoutChanged(updatedComps, updatedTraces);
      return;
    }

    // Try removing traces
    LineTrace? traceToRemove;
    for (final trace in widget.traces) {
      if (_distanceToSegment(logical, trace.start, trace.end) < 8.0) {
        traceToRemove = trace;
        break;
      }
    }

    if (traceToRemove != null) {
      final updatedTraces = widget.traces.where((t) => t != traceToRemove).toList();
      widget.onLayoutChanged(widget.components, updatedTraces);
    }
  }

  // PAN GESTURE - DRAGGING & ROUTING WIRE
  void _onPanStart(DragStartDetails details) {
    final logical = details.localPosition;

    if (_activeMode == 'move') {
      // Find component to drag
      for (final comp in widget.components) {
        if (comp.bounds.contains(logical)) {
          setState(() {
            _draggingComponent = comp;
            _dragOffset = logical - comp.gridPosition;
          });
          break;
        }
      }
    } else if (_activeMode == 'wire') {
      // Try magnetic hook pin start
      final snapped = _findNearbyPin(logical);
      if (snapped != null) {
        setState(() {
          _activeWireStart = snapped.absolutePosition;
          _activeWireSourceComponent = snapped.component;
          _activeWireSourcePin = snapped.pin;
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double logicalWidth, double logicalHeight) {
    final logical = details.localPosition;

    if (_activeMode == 'move' && _draggingComponent != null && _dragOffset != null) {
      final newPos = _snapOffset(logical - _dragOffset!);
      final boundedPos = Offset(
        newPos.dx.clamp(0.0, logicalWidth - _draggingComponent!.gridSize.width),
        newPos.dy.clamp(0.0, logicalHeight - _draggingComponent!.gridSize.height),
      );

      // Check overlaps
      final testRect = Rect.fromLTWH(boundedPos.dx, boundedPos.dy, _draggingComponent!.gridSize.width, _draggingComponent!.gridSize.height);
      bool overlaps = false;
      for (final comp in widget.components) {
        if (comp.id != _draggingComponent!.id && comp.bounds.overlaps(testRect)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        final updated = widget.components.map((comp) {
          if (comp.id == _draggingComponent!.id) {
            return comp.copyWith(gridPosition: boundedPos);
          }
          return comp;
        }).toList();

        // Reposition traces cleanly
        final shiftedTraces = widget.traces.map((trace) {
          Offset newStart = trace.start;
          Offset newEnd = trace.end;

          if (_draggingComponent!.bounds.contains(trace.start)) {
            final pinOffset = trace.start - _draggingComponent!.gridPosition;
            newStart = boundedPos + pinOffset;
          }
          if (_draggingComponent!.bounds.contains(trace.end)) {
            final pinOffset = trace.end - _draggingComponent!.gridPosition;
            newEnd = boundedPos + pinOffset;
          }
          return LineTrace(start: newStart, end: newEnd, color: trace.color);
        }).toList();

        widget.onLayoutChanged(updated, shiftedTraces);
        setState(() {
          _draggingComponent = _draggingComponent!.copyWith(gridPosition: boundedPos);
        });
      }
    } else if (_activeMode == 'wire') {
      setState(() {
        _currentMousePosition = logical;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_activeMode == 'move') {
      setState(() {
        _draggingComponent = null;
        _dragOffset = null;
      });
    } else if (_activeMode == 'wire' && _activeWireStart != null && _currentMousePosition != null) {
      // Finalize copper trace
      final startPin = _activeWireSourcePin;
      final startComp = _activeWireSourceComponent;

      // Locate magnet snap endpoint pin
      final endSnapped = _findNearbyPin(_currentMousePosition!);
      if (endSnapped != null && startPin != null && startComp != null) {
        final endComp = endSnapped.component;

        // Ensure we're not wiring to the same component, or if wiring distinct pins on distinct components!
        if (endComp.id != startComp.id) {
          final newTrace = LineTrace(
            start: _activeWireStart!,
            end: endSnapped.absolutePosition,
            color: const Color(0xFFFBBF24), // Active golden yellow glow color
          );

          final updatedTraces = List<LineTrace>.from(widget.traces)..add(newTrace);
          widget.onLayoutChanged(widget.components, updatedTraces);
        }
      }

      setState(() {
        _activeWireStart = null;
        _activeWireSourceComponent = null;
        _activeWireSourcePin = null;
      });
    }
  }

  Size _getSizeForType(String type) {
    if (type.contains('ALU Core')) return const Size(120.0, 80.0);
    if (type == 'Ctrl Unit') return const Size(100.0, 60.0);
    if (type.contains('Reg File')) return const Size(120.0, 48.0);
    if (type == 'Mem Array') return const Size(180.0, 60.0);
    if (type == 'Decoder') return const Size(80.0, 60.0);
    if (type == 'Interconnect Bus') return const Size(240.0, 20.0);
    if (type == 'Basic Float Compute Point (FPU)') return const Size(140.0, 70.0);
    return const Size(60.0, 60.0);
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final bp = p - b;
    final d1 = ap.dx * ab.dx + ap.dy * ab.dy;
    final d2 = bp.dx * ab.dx + bp.dy * ab.dy;
    if (d1 <= 0) return ap.distance;
    if (d2 >= 0) return bp.distance;
    return (ap.dx * ab.dy - ap.dy * ab.dx).abs() / ab.distance;
  }
}

class SnapPinResult {
  final PlacedComponent component;
  final TerminalPin pin;
  final Offset absolutePosition;

  SnapPinResult(this.component, this.pin, this.absolutePosition);
}

class _DockItemData {
  final String type;
  final Size size;
  final Color color;
  final String? prereqId;
  final String? prereqName;

  _DockItemData({
    required this.type,
    required this.size,
    required this.color,
    this.prereqId,
    this.prereqName,
  });
}

// ---------------------------------------------------------------------------
// Painter for Sandbox Breadboard
// ---------------------------------------------------------------------------

class _BreadboardPainter extends CustomPainter {
  final List<PlacedComponent> components;
  final List<LineTrace> traces;
  final String activeMode;
  final String? selectedDockType;
  final Offset? currentMousePos;
  final Offset? activeWireStart;
  final PlacedComponent? hoveredComponent;
  final TerminalPin? hoveredPin;
  final LineTrace? hoveredTrace;
  final List<_DockItemData> dockItems;
  final double logicalWidth;
  final double logicalHeight;

  _BreadboardPainter({
    required this.components,
    required this.traces,
    required this.activeMode,
    required this.selectedDockType,
    required this.currentMousePos,
    required this.activeWireStart,
    required this.hoveredComponent,
    required this.hoveredPin,
    required this.hoveredTrace,
    required this.dockItems,
    required this.logicalWidth,
    required this.logicalHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background board
    final bgPaint = Paint()
      ..color = const Color(0xFF020617)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, logicalWidth, logicalHeight), bgPaint);

    // Grid nodes (breadboard tie points)
    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (double x = 0; x <= logicalWidth; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, logicalHeight), gridPaint);
    }
    for (double y = 0; y <= logicalHeight; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(logicalWidth, y), gridPaint);
    }

    // Outer board trim
    final trimPaint = Paint()
      ..color = HTColors.border.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, logicalWidth, logicalHeight), trimPaint);

    // 2. Render Placed Wire Traces with distinct glowing for bus connection lines
    for (final trace in traces) {
      bool connectsToBus = false;
      for (final comp in components) {
        if (comp.type == 'Interconnect Bus') {
          // Check if start or end touches the top or bottom continuous horizontal lines of Interconnect Bus
          final topDistStart = (trace.start.dy - comp.gridPosition.dy).abs();
          final topDistEnd = (trace.end.dy - comp.gridPosition.dy).abs();
          final bottomDistStart = (trace.start.dy - (comp.gridPosition.dy + comp.gridSize.height)).abs();
          final bottomDistEnd = (trace.end.dy - (comp.gridPosition.dy + comp.gridSize.height)).abs();

          final withinXStart = trace.start.dx >= comp.gridPosition.dx - 2.0 && trace.start.dx <= comp.gridPosition.dx + comp.gridSize.width + 2.0;
          final withinXEnd = trace.end.dx >= comp.gridPosition.dx - 2.0 && trace.end.dx <= comp.gridPosition.dx + comp.gridSize.width + 2.0;

          if ((withinXStart && (topDistStart < 2.0 || bottomDistStart < 2.0)) ||
              (withinXEnd && (topDistEnd < 2.0 || bottomDistEnd < 2.0))) {
            connectsToBus = true;
            break;
          }
        }
      }

      final isHovered = trace == hoveredTrace;
      final Color baseGlowColor = connectsToBus ? const Color(0xFFD946EF) : const Color(0xFFFBBF24);
      final Color baseCoreColor = connectsToBus ? const Color(0xFFFFFFFF) : const Color(0xFFF59E0B);

      final glowPaint = Paint()
        ..color = baseGlowColor.withValues(alpha: isHovered ? 0.8 : 0.4)
        ..strokeWidth = isHovered ? 3.0 : 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(trace.start, trace.end, glowPaint);

      // Core trace path wire
      final corePaint = Paint()
        ..color = baseCoreColor
        ..strokeWidth = 0.8;
      canvas.drawLine(trace.start, trace.end, corePaint);
    }

    // 3. Render Placed Components Background Fills FIRST (Pass 1)
    for (final comp in components) {
      final fillPaint = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawRect(comp.bounds, fillPaint);
    }

    // 4. Render Placed Components Details, Text & Pins SECOND (Pass 2)
    for (final comp in components) {
      final isHovered = comp == hoveredComponent;
      final color = _getColorForType(comp.type);

      // Tech Grid Texture inside component
      final texturePaint = Paint()
        ..color = color.withValues(alpha: 0.05)
        ..strokeWidth = 0.5;
      for (double tx = comp.bounds.left; tx <= comp.bounds.right; tx += 10) {
        canvas.drawLine(Offset(tx, comp.bounds.top), Offset(tx, comp.bounds.bottom), texturePaint);
      }
      for (double ty = comp.bounds.top; ty <= comp.bounds.bottom; ty += 10) {
        canvas.drawLine(Offset(comp.bounds.left, ty), Offset(comp.bounds.right, ty), texturePaint);
      }

      // Border bounds
      final borderPaint = Paint()
        ..color = isHovered ? color : color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 1.5 : 1.0;
      canvas.drawRect(comp.bounds, borderPaint);

      if (isHovered) {
        // Glowing shadow highlight
        final shadowPaint = Paint()
          ..color = color.withValues(alpha: 0.06)
          ..style = PaintingStyle.fill;
        canvas.drawRect(comp.bounds.inflate(4.0), shadowPaint);
      }

      // Draw Component Label perfectly centered inside its bounds
      final namePainter = TextPainter(
        text: TextSpan(
          text: comp.type.toUpperCase(),
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            color: isHovered ? HTColors.textPrimary : HTColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: comp.bounds.width - 8.0);
      namePainter.paint(
        canvas,
        Offset(
          comp.bounds.left + (comp.bounds.width - namePainter.width) / 2,
          comp.bounds.top + (comp.bounds.height - namePainter.height) / 2,
        ),
      );

      // Render its Terminal Pins
      if (comp.type == 'Interconnect Bus') {
        // Draw continuous top/bottom rail pin visual paths!
        final railPaint = Paint()
          ..color = const Color(0xFFD946EF).withValues(alpha: 0.3)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(comp.gridPosition, Offset(comp.gridPosition.dx + comp.gridSize.width, comp.gridPosition.dy), railPaint);
        canvas.drawLine(Offset(comp.gridPosition.dx, comp.gridPosition.dy + comp.gridSize.height), Offset(comp.gridPosition.dx + comp.gridSize.width, comp.gridPosition.dy + comp.gridSize.height), railPaint);

        // Draw rail visual tie-points dots along the rail
        final dotPaint = Paint()
          ..color = const Color(0xFFD946EF).withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        for (double rx = comp.gridPosition.dx + 20.0; rx < comp.gridPosition.dx + comp.gridSize.width; rx += 20.0) {
          canvas.drawCircle(Offset(rx, comp.gridPosition.dy), 1.5, dotPaint);
          canvas.drawCircle(Offset(rx, comp.gridPosition.dy + comp.gridSize.height), 1.5, dotPaint);
        }
      } else {
        // Standard pin rendering
        for (final pin in comp.pins) {
          final absPinPos = comp.gridPosition + pin.offset;
          final isPinHovered = hoveredPin == pin && isHovered;

          // Check if any trace connects to this pin
          bool isConnected = false;
          for (final trace in traces) {
            if ((trace.start - absPinPos).distance < 2.0 || (trace.end - absPinPos).distance < 2.0) {
              isConnected = true;
              break;
            }
          }

          final pinPaint = Paint()
            ..color = isConnected
                ? const Color(0xFFFBBF24)
                : (isPinHovered ? HTColors.primary : const Color(0xFFEF4444))
            ..style = PaintingStyle.fill;
          canvas.drawCircle(absPinPos, isPinHovered ? 3.5 : 2.5, pinPaint);

          final pinRing = Paint()
            ..color = isConnected ? const Color(0xFFF59E0B) : const Color(0xFF0F172A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawCircle(absPinPos, isPinHovered ? 3.5 : 2.5, pinRing);

          // Micro Pin Label
          final labelPainter = TextPainter(
            text: TextSpan(
              text: pin.name.split(' ')[0].toUpperCase(),
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 5.0,
                color: isConnected ? const Color(0xFFFBBF24) : HTColors.textMuted,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          
          double labelY = absPinPos.dy - 8.0;
          if (pin.offset.dy > comp.gridSize.height / 2) {
            labelY = absPinPos.dy + 3.0;
          }

          labelPainter.paint(
            canvas,
            Offset(absPinPos.dx - labelPainter.width / 2, labelY),
          );
        }
      }
    }

    // 5. Render Placement Preview (if active selected Dock component)
    if (selectedDockType != null && currentMousePos != null) {
      final previewSize = _getSizeForType(selectedDockType!);
      final snappedPreviewOrigin = Offset(
        (currentMousePos!.dx - previewSize.width / 2).clamp(0.0, logicalWidth - previewSize.width),
        (currentMousePos!.dy - previewSize.height / 2).clamp(0.0, logicalHeight - previewSize.height),
      );
      final snappedOrigin = Offset(
        (snappedPreviewOrigin.dx / 20.0).roundToDouble() * 20.0,
        (snappedPreviewOrigin.dy / 20.0).roundToDouble() * 20.0,
      );

      final previewBounds = Rect.fromLTWH(snappedOrigin.dx, snappedOrigin.dy, previewSize.width, previewSize.height);
      final previewColor = _getColorForType(selectedDockType!).withValues(alpha: 0.4);

      final previewPaint = Paint()
        ..color = previewColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(previewBounds, previewPaint);

      final previewBorder = Paint()
        ..color = previewColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(previewBounds, previewBorder);
    }

    // 6. Draw Active Wire Trace currently drawing
    if (activeWireStart != null && currentMousePos != null) {
      Offset targetPos = currentMousePos!;
      SnapPinResult? snapTarget;

      // Scan continuous rails snap for active wire snapping
      for (final comp in components) {
        if (comp.type == 'Interconnect Bus') {
          final topDist = (currentMousePos!.dy - comp.gridPosition.dy).abs();
          final bottomDist = (currentMousePos!.dy - (comp.gridPosition.dy + comp.gridSize.height)).abs();
          final withinX = currentMousePos!.dx >= comp.gridPosition.dx - 8.0 && currentMousePos!.dx <= comp.gridPosition.dx + comp.gridSize.width + 8.0;

          if (withinX) {
            if (topDist < 16.0) {
              final clampedX = currentMousePos!.dx.clamp(comp.gridPosition.dx, comp.gridPosition.dx + comp.gridSize.width);
              final snappedX = (clampedX / 20.0).roundToDouble() * 20.0;
              final absPinPos = Offset(snappedX, comp.gridPosition.dy);
              snapTarget = SnapPinResult(comp, TerminalPin('Bus Top Rail', absPinPos - comp.gridPosition), absPinPos);
              targetPos = absPinPos;
              break;
            }
            if (bottomDist < 16.0) {
              final clampedX = currentMousePos!.dx.clamp(comp.gridPosition.dx, comp.gridPosition.dx + comp.gridSize.width);
              final snappedX = (clampedX / 20.0).roundToDouble() * 20.0;
              final absPinPos = Offset(snappedX, comp.gridPosition.dy + comp.gridSize.height);
              snapTarget = SnapPinResult(comp, TerminalPin('Bus Bottom Rail', absPinPos - comp.gridPosition), absPinPos);
              targetPos = absPinPos;
              break;
            }
          }
        } else {
          for (final pin in comp.pins) {
            final absPinPos = comp.gridPosition + pin.offset;
            if ((absPinPos - currentMousePos!).distance < 16.0) {
              snapTarget = SnapPinResult(comp, pin, absPinPos);
              targetPos = absPinPos;
              break;
            }
          }
        }
      }

      final isSnapValid = snapTarget != null;
      final Color wireColor = isSnapValid ? const Color(0xFFD946EF) : HTColors.primary.withValues(alpha: 0.7);

      final wirePaint = Paint()
        ..color = wireColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      // Draw Manhattan line traces
      final midPoint = Offset(targetPos.dx, activeWireStart!.dy);
      canvas.drawLine(activeWireStart!, midPoint, wirePaint);
      canvas.drawLine(midPoint, targetPos, wirePaint);

      if (isSnapValid) {
        final indicator = Paint()
          ..color = wireColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(targetPos, 8.0, indicator);
      }
    }
  }

  Color _getColorForType(String type) {
    if (type.contains('ALU Core')) return const Color(0xFF22D3EE);
    if (type == 'Ctrl Unit') return const Color(0xFF34D399);
    if (type.contains('Reg File')) return const Color(0xFFA78BFA);
    if (type == 'Mem Array') return const Color(0xFF60A5FA);
    if (type == 'Decoder') return const Color(0xFFFBBF24);
    if (type == 'Interconnect Bus') return const Color(0xFFD946EF);
    if (type == 'Basic Float Compute Point (FPU)') return const Color(0xFFF472B6);
    return HTColors.primary;
  }

  Size _getSizeForType(String type) {
    if (type.contains('ALU Core')) return const Size(120.0, 80.0);
    if (type == 'Ctrl Unit') return const Size(100.0, 60.0);
    if (type.contains('Reg File')) return const Size(120.0, 48.0);
    if (type == 'Mem Array') return const Size(180.0, 60.0);
    if (type == 'Decoder') return const Size(80.0, 60.0);
    if (type == 'Interconnect Bus') return const Size(240.0, 20.0);
    if (type == 'Basic Float Compute Point (FPU)') return const Size(140.0, 70.0);
    return const Size(60.0, 60.0);
  }

  @override
  bool shouldRepaint(covariant _BreadboardPainter oldDelegate) {
    return components != oldDelegate.components ||
        traces != oldDelegate.traces ||
        activeMode != oldDelegate.activeMode ||
        selectedDockType != oldDelegate.selectedDockType ||
        currentMousePos != oldDelegate.currentMousePos ||
        activeWireStart != oldDelegate.activeWireStart ||
        hoveredComponent != oldDelegate.hoveredComponent ||
        hoveredPin != oldDelegate.hoveredPin ||
        hoveredTrace != oldDelegate.hoveredTrace ||
        logicalWidth != oldDelegate.logicalWidth ||
        logicalHeight != oldDelegate.logicalHeight;
  }
}
