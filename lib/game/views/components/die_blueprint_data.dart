/// Hardware Tycoon — Die Blueprint Data Models
///
/// Immutable data classes defining the silicon die layout for the
/// [SiliconGridBlueprint] CustomPainter canvas.
library;

import 'dart:ui';

// ---------------------------------------------------------------------------
// Placed Component & Electronics Breadboard Pins
// ---------------------------------------------------------------------------

class TerminalPin {
  final String name;
  final Offset offset; // grid-relative offset

  const TerminalPin(this.name, this.offset);
}

class PlacedComponent {
  final String id;
  final String type; // 'ALU Core', 'Ctrl Unit', 'Reg File', 'Mem Array', 'Decoder'
  final Offset gridPosition;
  final Size gridSize;
  final List<String> connectedToIds;

  const PlacedComponent({
    required this.id,
    required this.type,
    required this.gridPosition,
    required this.gridSize,
    this.connectedToIds = const [],
  });

  Rect get bounds => Rect.fromLTWH(gridPosition.dx, gridPosition.dy, gridSize.width, gridSize.height);

  List<TerminalPin> get pins {
    if (type.contains('ALU Core')) {
      return [
        TerminalPin('Input Pin', const Offset(20.0, 0.0)),
        TerminalPin('Output Pin', Offset(gridSize.width - 20.0, gridSize.height)),
      ];
    } else if (type == 'Ctrl Unit') {
      return [
        TerminalPin('Exec Pin', Offset(gridSize.width - 20.0, 0.0)),
        TerminalPin('Out Pin', Offset(20.0, gridSize.height)),
      ];
    } else if (type.contains('Reg File')) {
      return [
        TerminalPin('Bus Pin', Offset(gridSize.width / 2, gridSize.height)),
      ];
    } else if (type == 'Decoder') {
      return [
        TerminalPin('In Pin', Offset(gridSize.width / 2, 0.0)),
        TerminalPin('Out Pin', Offset(gridSize.width - 20.0, gridSize.height)),
      ];
    } else if (type == 'Mem Array') {
      return [
        TerminalPin('Data Pin', Offset(gridSize.width / 2, gridSize.height)),
      ];
    } else if (type == 'Interconnect Bus') {
      return [
        TerminalPin('Bus Top Rail', Offset(gridSize.width / 2, 0.0)),
        TerminalPin('Bus Bottom Rail', Offset(gridSize.width / 2, gridSize.height)),
      ];
    } else if (type == 'Basic Float Compute Point (FPU)') {
      return [
        TerminalPin('Float Input Pin', const Offset(20.0, 0.0)),
        TerminalPin('Float Output Pin', Offset(gridSize.width - 20.0, gridSize.height)),
      ];
    }
    return [
      TerminalPin('Pad A', Offset.zero),
      TerminalPin('Pad B', Offset(gridSize.width, gridSize.height)),
    ];
  }

  PlacedComponent copyWith({
    String? id,
    String? type,
    Offset? gridPosition,
    Size? gridSize,
    List<String>? connectedToIds,
  }) {
    return PlacedComponent(
      id: id ?? this.id,
      type: type ?? this.type,
      gridPosition: gridPosition ?? this.gridPosition,
      gridSize: gridSize ?? this.gridSize,
      connectedToIds: connectedToIds ?? this.connectedToIds,
    );
  }
}

class LineTrace {
  final Offset start;
  final Offset end;
  final Color color;

  const LineTrace({
    required this.start,
    required this.end,
    this.color = const Color(0xFF22D3EE),
  });
}

// ---------------------------------------------------------------------------
// Logic Block Types (Legacy Compatibility)
// ---------------------------------------------------------------------------

enum LogicBlockType {
  alu('ALU', Color(0xFF22D3EE)),
  register('REG', Color(0xFFA78BFA)),
  control('CTRL', Color(0xFF34D399)),
  io('I/O', Color(0xFFFBBF24)),
  memory('MEM', Color(0xFF60A5FA));

  const LogicBlockType(this.label, this.color);
  final String label;
  final Color color;
}

class LogicBlock {
  final String name;
  final Rect bounds;
  final LogicBlockType type;

  const LogicBlock({
    required this.name,
    required this.bounds,
    required this.type,
  });
}

// ---------------------------------------------------------------------------
// Gate Positions (Legacy Compatibility)
// ---------------------------------------------------------------------------

class GatePosition {
  final Offset position;
  final bool isOccupied;
  final String? label;

  const GatePosition({
    required this.position,
    this.isOccupied = false,
    this.label,
  });
}

// ---------------------------------------------------------------------------
// Interconnect Traces (Legacy Compatibility)
// ---------------------------------------------------------------------------

enum TraceType {
  data(Color(0xFF34D399)),
  control(Color(0xFFFBBF24)),
  power(Color(0xFFF87171));

  const TraceType(this.color);
  final Color color;
}

class Trace {
  final Offset start;
  final Offset end;
  final TraceType type;

  const Trace({
    required this.start,
    required this.end,
    required this.type,
  });
}

// ---------------------------------------------------------------------------
// Die Blueprint Data (Legacy Compatibility)
// ---------------------------------------------------------------------------

class DieBlueprintData {
  final List<LogicBlock> blocks;
  final List<GatePosition> gates;
  final List<Trace> traces;

  const DieBlueprintData({
    required this.blocks,
    required this.gates,
    required this.traces,
  });

  /// A representative early-1960s silicon die layout.
  /// Coordinates are normalized to a 400×300 logical canvas.
  factory DieBlueprintData.defaultBlueprint1960() {
    return DieBlueprintData(
      blocks: [
        // Central ALU
        const LogicBlock(
          name: 'ALU CORE',
          bounds: Rect.fromLTWH(140, 80, 120, 80),
          type: LogicBlockType.alu,
        ),
        // Register file
        const LogicBlock(
          name: 'REG FILE',
          bounds: Rect.fromLTWH(140, 20, 120, 48),
          type: LogicBlockType.register,
        ),
        // Control unit
        const LogicBlock(
          name: 'CTRL UNIT',
          bounds: Rect.fromLTWH(20, 20, 100, 60),
          type: LogicBlockType.control,
        ),
        // I/O pads (left)
        const LogicBlock(
          name: 'I/O PAD L',
          bounds: Rect.fromLTWH(20, 100, 100, 40),
          type: LogicBlockType.io,
        ),
        // I/O pads (right)
        const LogicBlock(
          name: 'I/O PAD R',
          bounds: Rect.fromLTWH(280, 100, 100, 40),
          type: LogicBlockType.io,
        ),
        // Memory array
        const LogicBlock(
          name: 'MEM ARRAY',
          bounds: Rect.fromLTWH(20, 170, 180, 60),
          type: LogicBlockType.memory,
        ),
        // Decoder
        const LogicBlock(
          name: 'DECODER',
          bounds: Rect.fromLTWH(220, 170, 80, 60),
          type: LogicBlockType.control,
        ),
        // Output buffer
        const LogicBlock(
          name: 'OUT BUF',
          bounds: Rect.fromLTWH(320, 170, 60, 60),
          type: LogicBlockType.io,
        ),
        // Clock gen
        const LogicBlock(
          name: 'CLK GEN',
          bounds: Rect.fromLTWH(280, 20, 100, 60),
          type: LogicBlockType.control,
        ),
      ],
      gates: [
        // Transistor gate positions scattered across the die
        for (double x = 30; x < 380; x += 20)
          for (double y = 250; y < 290; y += 15)
            GatePosition(
              position: Offset(x, y),
              isOccupied: (x.toInt() + y.toInt()) % 3 == 0,
              label: 'T${x.toInt()}${y.toInt()}',
            ),
        // Additional gates along top edge
        for (double x = 30; x < 380; x += 25)
          GatePosition(
            position: Offset(x, 8),
            isOccupied: x.toInt() % 2 == 0,
            label: 'P${x.toInt()}',
          ),
      ],
      traces: [
        // Data bus from REG to ALU
        const Trace(start: Offset(200, 68), end: Offset(200, 80), type: TraceType.data),
        const Trace(start: Offset(180, 68), end: Offset(180, 80), type: TraceType.data),
        const Trace(start: Offset(220, 68), end: Offset(220, 80), type: TraceType.data),
        const Trace(start: Offset(240, 68), end: Offset(240, 80), type: TraceType.data),
        // Control lines from CTRL to ALU
        const Trace(start: Offset(120, 50), end: Offset(140, 50), type: TraceType.control),
        const Trace(start: Offset(120, 50), end: Offset(120, 120), type: TraceType.control),
        const Trace(start: Offset(120, 120), end: Offset(140, 120), type: TraceType.control),
        // Data bus from ALU to I/O
        const Trace(start: Offset(260, 120), end: Offset(280, 120), type: TraceType.data),
        // Memory bus
        const Trace(start: Offset(200, 160), end: Offset(200, 170), type: TraceType.data),
        const Trace(start: Offset(110, 160), end: Offset(110, 170), type: TraceType.data),
        // Power rails (horizontal)
        const Trace(start: Offset(10, 145), end: Offset(390, 145), type: TraceType.power),
        const Trace(start: Offset(10, 240), end: Offset(390, 240), type: TraceType.power),
        // Clock distribution
        const Trace(start: Offset(330, 80), end: Offset(330, 100), type: TraceType.control),
        const Trace(start: Offset(260, 160), end: Offset(260, 170), type: TraceType.control),
        // Decoder to output
        const Trace(start: Offset(300, 200), end: Offset(320, 200), type: TraceType.data),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DieBlueprintData &&
          blocks.length == other.blocks.length &&
          gates.length == other.gates.length &&
          traces.length == other.traces.length;

  @override
  int get hashCode => Object.hash(blocks.length, gates.length, traces.length);
}
