/// Hardware Tycoon — Foundry Operations Panel
///
/// Three sub-sections: Clean Room status grid, Production queue,
/// and a real-time Wafer Yield Efficiency chart powered by fl_chart.
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/game_state_provider.dart';
import '../../../core/game_state.dart';
import '../../../models/company_state.dart';

class FoundryOpsPanel extends StatefulWidget {
  const FoundryOpsPanel({super.key});

  @override
  State<FoundryOpsPanel> createState() => _FoundryOpsPanelState();
}

class _FoundryOpsPanelState extends State<FoundryOpsPanel> {
  int _activeTabIndex = 0;

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
              const Icon(Icons.precision_manufacturing, size: 14.0, color: HTColors.primary),
              const SizedBox(width: 8.0),
              Text('FOUNDRY OPERATIONS', style: HTTypography.panelHeader),
              const Spacer(),
              _YieldBadge(yield_: state.waferYield),
            ],
          ),
        ),

        // Custom TUI Tab Bar
        Container(
          height: 32.0,
          decoration: const BoxDecoration(
            color: Color(0xFF020617),
            border: Border(
              bottom: BorderSide(color: HTColors.border, width: 1.0),
            ),
          ),
          child: Row(
            children: [
              _buildTab(0, '[ ▓▓ ACTIVE PRODUCTION ▓▓ ]'),
              Container(width: 1.0, color: HTColors.border),
              _buildTab(1, '[ ░░ METRIC ARCHIVE ░░ ]'),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _activeTabIndex == 0
              ? ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    // Clean Room Status Grid
                    _SectionLabel(label: 'CLEAN ROOM STATUS'),
                    const SizedBox(height: 6.0),
                    _CleanRoomGrid(rooms: state.cleanRooms),

                    const SizedBox(height: 12.0),

                    // Production Queue
                    _SectionLabel(label: 'PRODUCTION QUEUE'),
                    const SizedBox(height: 6.0),
                    _ProductionQueue(batches: state.productionQueue),

                    const SizedBox(height: 12.0),

                    // Yield Efficiency Chart
                    _SectionLabel(label: 'WAFER YIELD EFFICIENCY — HISTORICAL'),
                    const SizedBox(height: 6.0),
                    _YieldChart(
                      history: state.yieldHistory,
                      currentYield: state.waferYield,
                    ),
                  ],
                )
              : _buildArchiveTab(state),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTabIndex = index),
        child: Container(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              color: isSelected ? HTColors.primary : HTColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveTab(GameStateNotifier state) {
    final archive = state.completedProductionQueue;
    if (archive.isEmpty) {
      return Center(
        child: Text(
          'NO FINISHED RUNS IN ARCHIVE REGISTER',
          style: HTTypography.bodySmall.copyWith(color: HTColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: archive.length,
      itemBuilder: (context, index) {
        final run = archive[index];
        final yieldPercent = (run.yieldPercent * 100).round();
        return Container(
          margin: const EdgeInsets.only(bottom: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          decoration: HTDecorations.cardBox(),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 12.0, color: HTColors.success),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.productName.toUpperCase(),
                      style: HTTypography.listTitle.copyWith(fontWeight: FontWeight.bold, fontSize: 10.0),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Volume: ${run.waferCount} Wafers | Yield Efficiency: $yieldPercent%',
                      style: HTTypography.bodySmall.copyWith(color: HTColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  border: Border.all(color: HTColors.success, width: 0.5),
                  color: HTColors.success.withValues(alpha: 0.05),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 7.5, color: HTColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Section Label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: HTTypography.badge.copyWith(
        color: HTColors.textMuted,
        fontSize: 10.0,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yield Badge
// ---------------------------------------------------------------------------

class _YieldBadge extends StatelessWidget {
  final double yield_;

  const _YieldBadge({required this.yield_});

  @override
  Widget build(BuildContext context) {
    final percent = (yield_ * 100).round();
    final color = yield_ > 0.7
        ? HTColors.success
        : yield_ > 0.4
            ? HTColors.warning
            : HTColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Text(
        'YIELD $percent%',
        style: HTTypography.badge.copyWith(color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Clean Room Grid (2×2)
// ---------------------------------------------------------------------------

class _CleanRoomGrid extends StatelessWidget {
  final List<CleanRoom> rooms;

  const _CleanRoomGrid({required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: rooms.map((room) => _CleanRoomCard(room: room)).toList(),
    );
  }
}

class _CleanRoomCard extends StatelessWidget {
  final CleanRoom room;

  const _CleanRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160.0,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: HTDecorations.cardBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: room.status.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: room.status.color.withValues(alpha: 0.4),
                        blurRadius: 4.0,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(room.name, style: HTTypography.listTitle),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(room.status.label, style: HTTypography.bodySmall),
            const SizedBox(height: 6.0),
            // Capacity bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: SizedBox(
                      height: 4.0,
                      child: LinearProgressIndicator(
                        value: room.utilizationPercent,
                        backgroundColor: HTColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          room.utilizationPercent > 0.85
                              ? HTColors.warning
                              : HTColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  '${room.capacityUsed}/${room.capacityMax}',
                  style: HTTypography.metricLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Production Queue
// ---------------------------------------------------------------------------

class _ProductionQueue extends StatelessWidget {
  final List<WaferBatch> batches;

  const _ProductionQueue({required this.batches});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: batches.map((batch) => _ProductionRow(batch: batch)).toList(),
    );
  }
}

class _ProductionRow extends StatelessWidget {
  final WaferBatch batch;

  const _ProductionRow({required this.batch});

  @override
  Widget build(BuildContext context) {
    final percent = (batch.progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: HTDecorations.cardBox(),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.productName, style: HTTypography.listTitle),
                const SizedBox(height: 2.0),
                Text('${batch.waferCount} wafers', style: HTTypography.bodySmall),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: SizedBox(
                height: 6.0,
                child: LinearProgressIndicator(
                  value: batch.progress,
                  backgroundColor: HTColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percent >= 90 ? HTColors.success : HTColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            width: 36.0,
            child: Text(
              '$percent%',
              style: HTTypography.metricValue.copyWith(
                color: percent >= 90 ? HTColors.success : HTColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yield Efficiency Chart (fl_chart)
// ---------------------------------------------------------------------------

class _YieldChart extends StatelessWidget {
  final List<YieldDataPoint> history;
  final double currentYield;

  const _YieldChart({
    required this.history,
    required this.currentYield,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        height: 140.0,
        decoration: HTDecorations.cardBox(),
        child: Center(
          child: Text('NO DATA YET', style: HTTypography.bodySmall),
        ),
      );
    }

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value.yieldPercent * 100).clamp(0.0, 100.0),
      );
    }).toList();

    return Container(
      height: 160.0,
      padding: const EdgeInsets.all(12.0),
      decoration: HTDecorations.cardBox(),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: HTColors.border,
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: HTTypography.metricLabel,
                  );
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: HTColors.primary,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: HTColors.primaryGlow,
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => HTColors.surfaceElevated,
              tooltipBorder: const BorderSide(color: HTColors.border),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}%',
                    HTTypography.metricValue.copyWith(color: HTColors.primary),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 150),
      ),
    );
  }
}
