import 'package:flutter/material.dart';
import '../../../core/theme.dart';

import '../../../models/research_node.dart';
import '../../../core/game_state_provider.dart';
import '../../../core/game_state.dart';
import '../../../models/company_state.dart';

class RndLabPanel extends StatefulWidget {
  const RndLabPanel({super.key});

  @override
  State<RndLabPanel> createState() => _RndLabPanelState();
}

class _RndLabPanelState extends State<RndLabPanel> {
  final TransformationController _transformController =
      TransformationController();

  static const double _cardWidth = 220.0;
  static const double _cardHeight = 100.0;
  static const double _hGap = 30.0; // horizontal gap between cards
  static const double _vGap = 12.0; // vertical gap between sub-rows
  static const double _leftPad = 60.0; // left canvas padding

  bool _isShowingDialog = false;
  String _searchQuery = '';

  /// Assigns each track to a distinct sub-row Y offset so cards in the
  /// same visual band don't overlap vertically.
  static double _getSubRowY(String trackId) {
    final t = trackId.toUpperCase();
    switch (t) {
      // --- Lane 0: Fabrication & Materials (y base = 50) ---
      case 'FAB':
      case 'MATERIALS':
        return 50.0;
      // --- Lane 1: Logic family (y base = 50 + 120 = 170) ---
      case 'LOGIC':
        return 50.0 + (_cardHeight + _vGap) * 1;
      // --- Lane 2: Architecture (y base = 50 + 240 = 290) ---
      case 'ARCH':
        return 50.0 + (_cardHeight + _vGap) * 2;
      // --- Lane 3: Software (y base = 50 + 360 = 410) ---
      case 'SOFT':
        return 50.0 + (_cardHeight + _vGap) * 3;
      // --- Lane 4: Packaging / Thermal (y base = 50 + 480 = 530) ---
      case 'PKG':
        return 50.0 + (_cardHeight + _vGap) * 4;
      default:
        return 50.0 + (_cardHeight + _vGap) * 5;
    }
  }

  /// Builds the position map fresh every frame. Uses a greedy placement
  /// algorithm: nodes are sorted by year, then for each node the algorithm
  /// calculates a minimum X based on year and finds the first X slot at its
  /// row that doesn't collide with any previously-placed card.
  Map<String, Offset> _buildPositions() {
    final Map<String, Offset> positions = {};

    // Sort nodes by year for deterministic left-to-right placement
    final sorted = List<ResearchNode>.from(HistoricalTechTree.nodes)
      ..sort((a, b) => a.yearEra.compareTo(b.yearEra));

    // Track the rightmost occupied X edge for each sub-row
    final Map<double, double> rowRightEdge = {};

    for (final node in sorted) {
      final double y = _getSubRowY(node.trackId);

      // Minimum X determined by calendar year
      double minX = _leftPad + (node.yearEra - 1960) * 200.0;

      // Ensure we don't collide with any card already on this row
      final double currentEdge = rowRightEdge[y] ?? 0.0;
      if (minX < currentEdge) {
        minX = currentEdge;
      }

      positions[node.id] = Offset(minX, y);

      // Update the right edge for this row
      rowRightEdge[y] = minX + _cardWidth + _hGap;
    }

    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);

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
              const Icon(Icons.science, size: 14.0, color: HTColors.primary),
              const SizedBox(width: 8.0),
              Text('R&D TIMELINE (1960-2038)', style: HTTypography.panelHeader),
              const Spacer(),
              Text(
                'PAN TO NAVIGATE',
                style: HTTypography.bodySmall.copyWith(
                  color: HTColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // R&D Funding selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: const BoxDecoration(
            color: Color(0xFF0B1329),
            border: Border(
              bottom: BorderSide(color: HTColors.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'R&D FUNDING MULTIPLIER > ',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(width: 8.0),
              ...RndFundingTier.values.map((tier) {
                final isSelected = state.rndFunding == tier;
                String upkeepLabel = '';
                switch (tier) {
                  case RndFundingTier.normal:
                    upkeepLabel = 'NORMAL (1x)';
                    break;
                  case RndFundingTier.accelerated:
                    upkeepLabel = 'ACCELERATED (3x UPKEEP)';
                    break;
                  case RndFundingTier.crash:
                    upkeepLabel = 'CRASH PROGRAM (8x UPKEEP)';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    onPressed: () => state.setRndFunding(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? HTColors.primary : const Color(0xFF1E293B),
                      foregroundColor: isSelected ? HTColors.background : HTColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      textStyle: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 8.0,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.0),
                        side: BorderSide(
                          color: isSelected ? HTColors.primary : HTColors.border,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Text(upkeepLabel),
                  ),
                );
              }),
            ],
          ),
        ),

        // Search Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: const BoxDecoration(
            color: Color(0xFF020617),
            border: Border(
              bottom: BorderSide(color: HTColors.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'QUERY_NODE_ID > ',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22D3EE),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 24.0,
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10.0,
                      color: HTColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                      border: InputBorder.none,
                      hintText: 'ENTER TECH NAME OR BRANCH TO SEARCH...',
                      hintStyle: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        fontSize: 9.0,
                        color: HTColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Policy & Active Focus Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: const BoxDecoration(
            color: HTColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: HTColors.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              Text('R&D MODE:', style: HTTypography.metricLabel),
              const SizedBox(width: 8.0),
              Row(
                children: AutomationPolicy.values.map((policy) {
                  final isSelected = state.automationPolicy == policy;
                  return GestureDetector(
                    onTap: () => state.setAutomationPolicy(policy),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? HTColors.primary.withValues(alpha: 0.15)
                            : HTColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? HTColors.primary
                              : HTColors.border,
                        ),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: Text(
                        policy.label,
                        style: HTTypography.badge.copyWith(
                          color: isSelected
                              ? HTColors.primary
                              : HTColors.textSecondary,
                          fontSize: 9.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              if (state.activeResearchNodeId != null) ...[
                Builder(
                  builder: (context) {
                    final node = HistoricalTechTree.nodes.firstWhere(
                      (n) => n.id == state.activeResearchNodeId,
                    );
                    final researchStaff = state.employees
                        .where(
                          (e) =>
                              e.assignment == WorkAssignment.rnd &&
                              (e.type == EmployeeType.architect ||
                                  e.type == EmployeeType.driverDev),
                        )
                        .length;
                    final int currentYear = state.gameDate.year;
                    double costMultiplier = 1.0;
                    if (currentYear < node.historicalYear) {
                      final int yearsAhead = node.historicalYear - currentYear;
                      costMultiplier += 0.5 * yearsAhead * (1.0 - state.rndFunding.aotMitigation);
                    }
                    final double effectiveCostTicks = node.researchCostTicks * costMultiplier;
                    final speed =
                        (0.5 + 0.5 * researchStaff) /
                        (effectiveCostTicks * 10.0);
                    final ticksRemaining = speed > 0
                        ? ((1.0 - node.progress) / speed).round()
                        : 9999;
                    return Text(
                      'ACTIVE FOCUS: "${node.title.toUpperCase()}" [$ticksRemaining TICKS EST]',
                      style: const TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: HTColors.primary,
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ] else ...[
                const Text(
                  'ACTIVE FOCUS: NONE [IDLE]',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textMuted,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Interactive Graph
        Expanded(
          child: Builder(
            builder: (context) {
              // Recalculate positions every build (reactive to hot-reload & state changes)
              final nodePositions = _buildPositions();

              double maxX = 1200.0;
              double maxY = 600.0;
              for (final pos in nodePositions.values) {
                if (pos.dx > maxX) maxX = pos.dx;
                if (pos.dy > maxY) maxY = pos.dy;
              }
              final canvasWidth = maxX + _cardWidth + 200.0;
              final canvasHeight = maxY + _cardHeight + 100.0;

              return InteractiveViewer(
                transformationController: _transformController,
                constrained: false,
                minScale: 0.15,
                maxScale: 2.0,
                boundaryMargin: const EdgeInsets.all(400.0),
                panEnabled: !_isShowingDialog,
                scaleEnabled: !_isShowingDialog,
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Background Era Grid Lines
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _EraBackgroundPainter(
                            horizontalStep: 200.0,
                            offset: _leftPad,
                            laneYPositions: const [50.0],
                            canvasHeight: canvasHeight,
                          ),
                        ),
                      ),

                      // Connections
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ManhattanLinePainter(
                            nodes: HistoricalTechTree.nodes,
                            positions: nodePositions,
                            cardWidth: _cardWidth,
                            cardHeight: _cardHeight,
                            searchQuery: _searchQuery,
                          ),
                        ),
                      ),

                      // Nodes
                      for (final node in HistoricalTechTree.nodes)
                        if (nodePositions.containsKey(node.id))
                          Builder(
                            builder: (context) {
                              final pos = nodePositions[node.id]!;
                              final isMatch =
                                  _searchQuery.isEmpty ||
                                  node.title.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ) ||
                                  node.branch.name.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  );

                              return Positioned(
                                left: pos.dx,
                                top: pos.dy,
                                width: _cardWidth,
                                height: _cardHeight,
                                child: Opacity(
                                  opacity: isMatch ? 1.0 : 0.20,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showResearchDetailModal(
                                        context,
                                        node,
                                        state,
                                      );
                                    },
                                    child: _ResearchNodeCard(
                                      node: node,
                                      isActiveFocus:
                                          state.activeResearchNodeId == node.id,
                                      isSearchMatch:
                                          _searchQuery.isNotEmpty && isMatch,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showResearchDetailModal(
    BuildContext context,
    ResearchNode node,
    GameStateNotifier state,
  ) {
    setState(() {
      _isShowingDialog = true;
    });
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isCompleted = node.progress >= 1.0;
        final isActive = state.activeResearchNodeId == node.id;
        final prereqsMet = node.prerequisiteIds.every((pid) {
          final pre = HistoricalTechTree.nodes.firstWhere((n) => n.id == pid);
          return pre.progress >= 1.0;
        });

        Color branchColor;
        switch (node.branch) {
          case ResearchBranch.fabrication:
            branchColor = Colors.orange;
            break;
          case ResearchBranch.architecture:
            branchColor = HTColors.primary;
            break;
          case ResearchBranch.software:
            branchColor = Colors.purpleAccent;
            break;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40.0,
            vertical: 24.0,
          ),
          child: Container(
            width: 480.0,
            decoration: BoxDecoration(
              color: HTColors.surface,
              border: Border.all(color: branchColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: branchColor.withValues(alpha: 0.15),
                  blurRadius: 16.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.science, color: branchColor, size: 16.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        node.title.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          color: HTColors.textPrimary,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: branchColor.withValues(alpha: 0.1),
                        border: Border.all(color: branchColor),
                      ),
                      child: Text(
                        node.branch.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          color: branchColor,
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Specs
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: HTColors.surfaceVariant,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          final currentYear = state.gameDate.year;
                          double costMultiplier = 1.0;
                          if (currentYear < node.historicalYear) {
                            final int yearsAhead = node.historicalYear - currentYear;
                            costMultiplier += 0.5 * yearsAhead * (1.0 - state.rndFunding.aotMitigation);
                          }
                          final int displayCost = (node.researchCostTicks * costMultiplier).round();
                          final isPenalty = costMultiplier > 1.0;
                          return Text(
                            isPenalty ? 'RESEARCH COST: $displayCost TICKS (+${((costMultiplier - 1.0)*100).round()}% AOT)' : 'RESEARCH COST: ${node.researchCostTicks} TICKS',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              color: isPenalty ? const Color(0xFFFBBF24) : HTColors.textSecondary,
                              fontSize: 9.0,
                            ),
                          );
                        }
                      ),
                      Text(
                        'ERA: ${node.yearEra}s',
                        style: const TextStyle(
                          fontFamily: 'IBMPlexMono',
                          color: HTColors.textSecondary,
                          fontSize: 9.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Description
                Text(
                  node.description,
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textPrimary,
                    fontSize: 10.0,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Historical Lore Section
                const Text(
                  '--- HISTORICAL CONTEXT ---',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textMuted,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  node.historicalLore.isNotEmpty
                      ? node.historicalLore
                      : 'An essential stepping stone in semiconductor fabrication history, advancing the structural complexity and throughput limits of silicon processing technology.',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textSecondary,
                    fontSize: 9.0,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Game Modifiers Section
                const Text(
                  '--- SIMULATION INFLUENCE ---',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textMuted,
                    fontSize: 8.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                if (node.gameModifiers.isNotEmpty) ...[
                  ...node.gameModifiers.map(
                    (mod) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              color: HTColors.primary,
                              fontSize: 9.0,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              mod,
                              style: const TextStyle(
                                fontFamily: 'IBMPlexMono',
                                color: HTColors.success,
                                fontSize: 9.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: HTColors.primary,
                            fontSize: 9.0,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Enables future ${node.branch.name} development pathways and locks down prerequisite branches.',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexMono',
                              color: HTColors.textSecondary,
                              fontSize: 9.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),

                // Footer Buttons Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: HTColors.border),
                        foregroundColor: HTColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                      child: const Text(
                        'DISMISS',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    if (isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: HTColors.surfaceVariant,
                          border: Border.all(color: HTColors.border),
                        ),
                        child: const Text(
                          '[ RESEARCH DEPLOYED ]',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: HTColors.textMuted,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (!prereqsMet) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          '[ PREREQUISITES LOCKED ]',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: Colors.red,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: HTColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: HTColors.primary),
                        ),
                        child: const Text(
                          '[ ACTIVE R&D TARGET ]',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            color: HTColors.primary,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed:
                            state.automationPolicy ==
                                AutomationPolicy.fullyAutomated
                            ? null
                            : () {
                                state.selectResearchNode(node.id);
                                Navigator.of(context).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: branchColor,
                          foregroundColor: HTColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 10.0,
                          ),
                        ),
                        child: const Text(
                          'INITIALIZE RESEARCH',
                          style: TextStyle(
                            fontFamily: 'IBMPlexMono',
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isShowingDialog = false;
      });
    });
  }
}

class _ResearchNodeCard extends StatefulWidget {
  final ResearchNode node;
  final bool isActiveFocus;
  final bool isSearchMatch;

  const _ResearchNodeCard({
    required this.node,
    this.isActiveFocus = false,
    this.isSearchMatch = false,
  });

  @override
  State<_ResearchNodeCard> createState() => _ResearchNodeCardState();
}

class _ResearchNodeCardState extends State<_ResearchNodeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isActiveFocus = widget.isActiveFocus;
    final bool isCompleted = node.progress >= 1.0;

    Color branchColor;
    switch (node.branch) {
      case ResearchBranch.fabrication:
        branchColor = Colors.orange;
        break;
      case ResearchBranch.architecture:
        branchColor = HTColors.primary;
        break;
      case ResearchBranch.software:
        branchColor = Colors.purpleAccent;
        break;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Color borderColor = isCompleted
            ? branchColor
            : (isActiveFocus ? HTColors.primary : HTColors.border);
        double borderWidth = (isCompleted || isActiveFocus) ? 2.0 : 1.0;
        List<BoxShadow> shadows = (isCompleted || isActiveFocus)
            ? [
                BoxShadow(
                  color: (isCompleted ? branchColor : HTColors.primary)
                      .withValues(alpha: 0.2),
                  blurRadius: 8.0,
                ),
              ]
            : [];

        if (widget.isSearchMatch) {
          final pulseVal = _controller.value;
          borderColor = Color.lerp(
            const Color(0xFF22D3EE),
            const Color(0xFFD946EF),
            pulseVal,
          )!;
          borderWidth = 2.0 + pulseVal * 1.5;
          shadows = [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.6),
              blurRadius: 6.0 + pulseVal * 8.0,
              spreadRadius: pulseVal * 1.0,
            ),
          ];
        }

        return Container(
          decoration: BoxDecoration(
            color: isCompleted ? HTColors.surfaceVariant : HTColors.surface,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(4.0),
            boxShadow: shadows,
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${node.yearEra}',
                    style: HTTypography.metricValue.copyWith(
                      color: isCompleted ? branchColor : HTColors.textMuted,
                      fontSize: 10.0,
                    ),
                  ),
                  if (isActiveFocus) ...[
                    const SizedBox(width: 6.0),
                    const Text(
                      '[FOCUS]',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: HTColors.primary,
                        fontSize: 8.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (node.isUnlocked && !isCompleted)
                    const Icon(
                      Icons.lock_open,
                      size: 10,
                      color: HTColors.textSecondary,
                    )
                  else if (!isCompleted)
                    const Icon(Icons.lock, size: 10, color: HTColors.textMuted),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                node.title,
                style: HTTypography.listTitle.copyWith(
                  color: (isCompleted || isActiveFocus)
                      ? HTColors.textPrimary
                      : HTColors.textSecondary,
                  fontSize: 11.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2.0),
              Expanded(
                child: Text(
                  node.description,
                  style: HTTypography.listSubtitle.copyWith(fontSize: 9.0),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4.0),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2.0),
                child: LinearProgressIndicator(
                  value: node.progress,
                  minHeight: 4.0,
                  backgroundColor: HTColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? branchColor : HTColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ManhattanLinePainter extends CustomPainter {
  final List<ResearchNode> nodes;
  final Map<String, Offset> positions;
  final double cardWidth;
  final double cardHeight;
  final String searchQuery;

  _ManhattanLinePainter({
    required this.nodes,
    required this.positions,
    required this.cardWidth,
    required this.cardHeight,
    required this.searchQuery,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final node in nodes) {
      if (!positions.containsKey(node.id)) continue;

      final currentPos = positions[node.id]!;
      final currentLeftCenter = Offset(
        currentPos.dx,
        currentPos.dy + (cardHeight / 2),
      );

      for (final prereqId in node.prerequisiteIds) {
        if (!positions.containsKey(prereqId)) continue;

        final prePos = positions[prereqId]!;
        final preRightCenter = Offset(
          prePos.dx + cardWidth,
          prePos.dy + (cardHeight / 2),
        );

        final path = Path();
        path.moveTo(preRightCenter.dx, preRightCenter.dy);

        // Orthogonal horizontal flow routing
        final midX =
            preRightCenter.dx + (currentLeftCenter.dx - preRightCenter.dx) / 2;
        path.lineTo(midX, preRightCenter.dy);
        path.lineTo(midX, currentLeftCenter.dy);
        path.lineTo(currentLeftCenter.dx, currentLeftCenter.dy);

        final prereqNode = nodes.firstWhere((n) => n.id == prereqId);

        final currentMatch =
            searchQuery.isEmpty ||
            node.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
            node.branch.name.toLowerCase().contains(searchQuery.toLowerCase());

        final prereqMatch =
            searchQuery.isEmpty ||
            prereqNode.title.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            prereqNode.branch.name.toLowerCase().contains(
              searchQuery.toLowerCase(),
            );

        double opacity = 1.0;
        if (searchQuery.isNotEmpty) {
          opacity = (currentMatch && prereqMatch) ? 0.9 : 0.08;
        } else {
          opacity = node.isUnlocked ? 0.5 : 0.3;
        }

        paint.color = HTColors.primary.withValues(alpha: opacity);
        canvas.drawPath(path, paint);

        // Draw arrow head pointing to the right
        final arrowPaint = Paint()
          ..color = HTColors.primary.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        final arrowPath = Path();
        arrowPath.moveTo(currentLeftCenter.dx, currentLeftCenter.dy);
        arrowPath.lineTo(
          currentLeftCenter.dx - 6.0,
          currentLeftCenter.dy - 4.0,
        );
        arrowPath.lineTo(
          currentLeftCenter.dx - 6.0,
          currentLeftCenter.dy + 4.0,
        );
        arrowPath.close();
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ManhattanLinePainter oldDelegate) => true;
}

class _EraBackgroundPainter extends CustomPainter {
  final double horizontalStep;
  final double offset;
  final List<double> laneYPositions;
  final double canvasHeight;

  _EraBackgroundPainter({
    required this.horizontalStep,
    required this.offset,
    required this.laneYPositions,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw horizontal background lane stripes for each track row
    final stripePaint = Paint()
      ..color = HTColors.surfaceVariant.withValues(alpha: 0.06);
    // 6 sub-rows: FAB, LOGIC, ARCH, SOFT, PKG, fallback
    for (int i = 0; i < 6; i++) {
      double y = 50.0 + i * 112.0;
      canvas.drawRect(
        Rect.fromLTWH(0, y - 6, size.width, 112.0),
        stripePaint,
      );
    }

    // 2. Draw vertical decade divider lines & Era header labels
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Decades from 1960 to 2040
    for (int year = 1960; year <= 2040; year += 10) {
      double x = (year - 1960) * horizontalStep + offset;

      // Draw thin vertical line down the entire height
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);

      // Draw decade header text at the top
      final label = ResearchNode.eraLabels[year];
      if (label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: '|--- $year $label ---|',
            style: const TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              color: HTColors.textMuted,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x + 10.0, 10.0));
      }
    }

    // 3. Draw track lane labels on far left
    const laneLabels = ['FAB', 'LOGIC', 'ARCH', 'SOFT', 'PKG'];
    for (int i = 0; i < laneLabels.length; i++) {
      final y = 50.0 + i * 112.0 + 40.0;
      final tp = TextPainter(
        text: TextSpan(
          text: laneLabels[i],
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 8.0,
            fontWeight: FontWeight.bold,
            color: HTColors.textMuted.withValues(alpha: 0.4),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(8.0, y));
    }
  }

  @override
  bool shouldRepaint(covariant _EraBackgroundPainter oldDelegate) => false;
}
