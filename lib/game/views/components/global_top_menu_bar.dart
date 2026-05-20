/// Hardware Tycoon — GlobalTopMenuBar
///
/// A 42px data-dense horizontal bar pinned to the top of the viewport
/// displaying critical world state metrics and simulation speed controls.
///
/// Layout:
/// ┌──────────┬───────────────────────────────────────┬──────────────────┬──────────┐
/// │ JAN 1960 │ $500,000 | CF: +$12,400 | STK: $4.20 │ Staff: 24 | 😊78%│ ▶ 1× 2× │
/// └──────────┴───────────────────────────────────────┴──────────────────┴──────────┘
library;

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/game_state.dart';
import '../../core/game_state_provider.dart';
import '../../models/company_state.dart';
import '../../core/app_state.dart';
import '../../core/save_manager.dart';
import '../../../versioning/versioning.dart';

class GlobalTopMenuBar extends StatelessWidget {
  final AppStateMachine appState;
  final ValueChanged<String>? onToggleWindow;
  final Set<String> closedWindows;

  const GlobalTopMenuBar({
    super.key, 
    required this.appState,
    this.onToggleWindow,
    this.closedWindows = const {},
  });

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);

    return Container(
      height: 42.0,
      decoration: HTDecorations.topBar,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Left: Corporate Branding & Version
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HARDWARE TYCOON', style: HTTypography.panelHeader),
              Text('${AppVersion.displayVersion} • Phase 4', style: HTTypography.bodySmall.copyWith(color: HTColors.textMuted)),
            ],
          ),
          
          _verticalDivider(),

          // Simulation Date Display
          _MetricChip(
            label: 'DATE',
            value: state.formattedDate,
            valueColor: HTColors.primary,
            icon: Icons.calendar_today_outlined,
          ),
          
          _verticalDivider(),
          
          // Window Toggles & Design Mode
          if (onToggleWindow != null) ...[
            _WindowToggle(
              icon: Icons.people_outline,
              label: 'WRK',
              isClosed: closedWindows.contains('workforce'),
              onTap: () => onToggleWindow!('workforce'),
            ),
            const SizedBox(width: 4.0),
            _WindowToggle(
              icon: Icons.science_outlined,
              label: 'RND',
              isClosed: closedWindows.contains('rnd'),
              onTap: () => onToggleWindow!('rnd'),
            ),
            const SizedBox(width: 4.0),
            _WindowToggle(
              icon: Icons.precision_manufacturing_outlined,
              label: 'FND',
              isClosed: closedWindows.contains('foundry'),
              onTap: () => onToggleWindow!('foundry'),
            ),
            const SizedBox(width: 4.0),
            _WindowToggle(
              icon: Icons.music_note,
              label: 'MSC',
              isClosed: closedWindows.contains('music_deck'),
              onTap: () => onToggleWindow!('music_deck'),
            ),
            const SizedBox(width: 8.0),
          ],
          
          OutlinedButton.icon(
            icon: Icon(
              state.isDesigningArchitecture ? Icons.close : Icons.architecture, 
              size: 12,
            ),
            label: Text(state.isDesigningArchitecture ? 'EXIT DESIGN' : 'DESIGN'),
            style: OutlinedButton.styleFrom(
              foregroundColor: state.isDesigningArchitecture ? HTColors.error : HTColors.primary,
              side: BorderSide(color: state.isDesigningArchitecture ? HTColors.error : HTColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
              minimumSize: const Size(0, 24),
              textStyle: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              if (state.isDesigningArchitecture) {
                state.cancelDesigningProject();
              } else {
                onToggleWindow?.call('design_init');
              }
            },
          ),

          _verticalDivider(),

          // Financial Section
          Expanded(
            flex: 4,
            child: _FinancialMetrics(
              liquidity: state.liquidity,
              netCashflow: state.netCashflow,
              stockValuation: state.stockValuation,
              isPublic: state.isPublic,
            ),
          ),

          _verticalDivider(),

          // Workforce Section
          Expanded(
            flex: 2,
            child: _WorkforceMetrics(
              activeStaff: state.activeStaff,
              totalStaff: state.totalStaff,
              mood: state.corporateMood,
            ),
          ),

          _verticalDivider(),

          // Sim Controls
          _SimSpeedControls(
            currentSpeed: state.simSpeed,
            onSpeedChanged: state.setSpeed,
            onTogglePause: state.togglePause,
          ),

          _verticalDivider(),

          // System Menu / Save
          _SystemMenuButton(
            appState: appState,
            gameState: state,
          ),
        ],
      ),
    );
  }



  static Widget _verticalDivider() {
    return Container(
      width: 1.0,
      height: 24.0,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      color: HTColors.divider,
    );
  }
}

class _WindowToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isClosed;
  final VoidCallback onTap;

  const _WindowToggle({
    required this.icon,
    required this.label,
    required this.isClosed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: isClosed ? HTColors.surface : HTColors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: isClosed ? HTColors.border : HTColors.primary,
          ),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12.0, color: isClosed ? HTColors.textMuted : HTColors.primary),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 9.0,
                color: isClosed ? HTColors.textMuted : HTColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ---------------------------------------------------------------------------
// Financial Metrics
// ---------------------------------------------------------------------------

class _FinancialMetrics extends StatelessWidget {
  final double liquidity;
  final double netCashflow;
  final double stockValuation;
  final bool isPublic;

  const _FinancialMetrics({
    required this.liquidity,
    required this.netCashflow,
    required this.stockValuation,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Liquidity
        _MetricChip(
          label: 'LIQUIDITY',
          value: _formatCurrency(liquidity),
          valueColor: HTColors.textPrimary,
          icon: Icons.account_balance_wallet,
        ),

        const SizedBox(width: 12.0),

        // Net Cashflow
        _MetricChip(
          label: 'CASHFLOW',
          value: '${netCashflow >= 0 ? '+' : ''}${_formatCurrency(netCashflow)}',
          valueColor: netCashflow >= 0 ? HTColors.profitGreen : HTColors.lossRed,
          icon: Icons.trending_up,
        ),

        if (isPublic) ...[
          const SizedBox(width: 12.0),
          // Stock Ticker
          _MetricChip(
            label: 'STK',
            value: '\$${stockValuation.toStringAsFixed(2)}',
            valueColor: HTColors.secondary,
            icon: Icons.show_chart,
          ),
        ],
      ],
    );
  }

  static String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    final prefix = amount < 0 ? '-' : '';
    if (absAmount >= 1000000) {
      return '$prefix\$${(absAmount / 1000000).toStringAsFixed(2)}M';
    } else if (absAmount >= 1000) {
      return '$prefix\$${(absAmount / 1000).toStringAsFixed(1)}K';
    }
    return '$prefix\$${absAmount.toStringAsFixed(0)}';
  }
}

// ---------------------------------------------------------------------------
// Workforce Metrics
// ---------------------------------------------------------------------------

class _WorkforceMetrics extends StatelessWidget {
  final int activeStaff;
  final int totalStaff;
  final double mood;

  const _WorkforceMetrics({
    required this.activeStaff,
    required this.totalStaff,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    final moodPercent = (mood * 100).round();
    final moodColor = mood > 0.7
        ? HTColors.success
        : mood > 0.4
            ? HTColors.warning
            : HTColors.error;

    return Row(
      children: [
        // Staff count
        const Icon(Icons.people, size: 13.0, color: HTColors.textMuted),
        const SizedBox(width: 4.0),
        Text(
          '$activeStaff/$totalStaff',
          style: HTTypography.metricValue,
        ),

        const SizedBox(width: 12.0),

        // Mood bar
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MOOD', style: HTTypography.metricLabel),
            const SizedBox(height: 2.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48.0,
                  height: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: LinearProgressIndicator(
                      value: mood,
                      backgroundColor: HTColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  '$moodPercent%',
                  style: HTTypography.metricLabel.copyWith(color: moodColor),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Simulation Speed Controls
// ---------------------------------------------------------------------------

class _SimSpeedControls extends StatelessWidget {
  final SimSpeed currentSpeed;
  final ValueChanged<SimSpeed> onSpeedChanged;
  final VoidCallback onTogglePause;

  const _SimSpeedControls({
    required this.currentSpeed,
    required this.onSpeedChanged,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = currentSpeed == SimSpeed.paused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause toggle
        _ControlButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          isActive: !isPaused,
          onTap: onTogglePause,
          tooltip: isPaused ? 'Resume' : 'Pause',
        ),

        const SizedBox(width: 4.0),

        // Speed buttons
        for (final speed in [SimSpeed.normal, SimSpeed.fast, SimSpeed.ultrafast])
          Padding(
            padding: const EdgeInsets.only(right: 2.0),
            child: _SpeedButton(
              speed: speed,
              isActive: currentSpeed == speed,
              onTap: () => onSpeedChanged(speed),
            ),
          ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: isActive ? HTColors.primaryGlow : Colors.transparent,
              border: Border.all(
                color: isActive ? HTColors.primary : HTColors.border,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Icon(
              icon,
              size: 16.0,
              color: isActive ? HTColors.primary : HTColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final SimSpeed speed;
  final bool isActive;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.speed,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Speed ${speed.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: isActive ? HTColors.primary.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(
                color: isActive ? HTColors.primary : HTColors.border,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(3.0),
            ),
            child: Text(
              speed.label,
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 10.0,
                fontWeight: FontWeight.w700,
                color: isActive ? HTColors.primary : HTColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Metric Chip
// ---------------------------------------------------------------------------

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.0, color: HTColors.textMuted),
        const SizedBox(width: 4.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: HTTypography.metricLabel),
            Text(value, style: HTTypography.metricValue.copyWith(color: valueColor)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// System Menu Button
// ---------------------------------------------------------------------------

class _SystemMenuButton extends StatelessWidget {
  final AppStateMachine appState;
  final GameStateNotifier gameState;

  const _SystemMenuButton({
    required this.appState,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'System Menu / Save',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSystemMenu(context),
          borderRadius: BorderRadius.circular(4.0),
          child: Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: HTColors.surfaceVariant,
              border: Border.all(color: HTColors.border),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Icon(Icons.menu, size: 16.0, color: HTColors.textSecondary),
          ),
        ),
      ),
    );
  }

  void _showSystemMenu(BuildContext context) {
    gameState.pause();
    
    showDialog(
      context: context,
      barrierColor: HTColors.background.withValues(alpha: 0.8),
      builder: (ctx) => Center(
        child: Container(
          width: 320.0,
          padding: const EdgeInsets.all(24.0),
          decoration: HTDecorations.cardBox(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('SYSTEM MENU', style: HTTypography.panelHeader, textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.save, size: 16),
                label: const Text('SAVE SESSION'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HTColors.primary,
                  foregroundColor: HTColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: HTTypography.listTitle,
                ),
                onPressed: () async {
                  await SaveManager.saveSession(gameState);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session Data Committed to Disk'),
                        backgroundColor: HTColors.success,
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 12.0),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('SETTINGS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HTColors.surfaceVariant,
                  foregroundColor: HTColors.textPrimary,
                  side: const BorderSide(color: HTColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: HTTypography.listTitle,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  appState.goToSettings(returnTo: AppScreen.gameplay);
                },
              ),
              
              const SizedBox(height: 12.0),
              
              OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app, size: 16),
                label: const Text('EXIT TO TERMINAL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HTColors.error,
                  side: const BorderSide(color: HTColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: HTTypography.listTitle,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  appState.goToMainMenu();
                },
              ),
              
              const SizedBox(height: 12.0),
              
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: HTColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: HTTypography.body,
                ),
                child: const Text('RESUME OPERATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

