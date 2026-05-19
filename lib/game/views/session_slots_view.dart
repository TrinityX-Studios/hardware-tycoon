/// Hardware Tycoon — Session Slots View
///
/// Interface for restoring a previously saved session.
/// Displays 3 distinct core slots with their respective saved states.
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_state.dart';

class SessionSlotsView extends StatelessWidget {
  final AppStateMachine appState;

  const SessionSlotsView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HTColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: HTColors.primary,
                    onPressed: () => appState.goToMainMenu(),
                  ),
                  const SizedBox(width: 16.0),
                  Text('SESSION RESTORATION CORE', style: HTTypography.statMedium),
                ],
              ),
              const SizedBox(height: 12.0),
              const Divider(color: HTColors.border, height: 1.0),
              
              const SizedBox(height: 48.0),
              
              // Slots
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SessionSlot(
                          slotNumber: 1,
                          companyName: 'Acme Silicon',
                          gameDate: 'JUN 1963',
                          timestamp: '2026-05-18 14:32:00',
                          isEmpty: false,
                          onRestore: () {
                            // Stub for loading logic
                          },
                        ),
                        const SizedBox(height: 16.0),
                        const _SessionSlot(
                          slotNumber: 2,
                          isEmpty: true,
                        ),
                        const SizedBox(height: 16.0),
                        const _SessionSlot(
                          slotNumber: 3,
                          isEmpty: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSlot extends StatefulWidget {
  final int slotNumber;
  final bool isEmpty;
  final String? companyName;
  final String? gameDate;
  final String? timestamp;
  final VoidCallback? onRestore;

  const _SessionSlot({
    required this.slotNumber,
    required this.isEmpty,
    this.companyName,
    this.gameDate,
    this.timestamp,
    this.onRestore,
  });

  @override
  State<_SessionSlot> createState() => _SessionSlotState();
}

class _SessionSlotState extends State<_SessionSlot> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: widget.isEmpty
              ? HTColors.surface
              : _isHovered ? HTColors.surfaceVariant : HTColors.surface,
          border: Border.all(
            color: widget.isEmpty
                ? HTColors.border
                : _isHovered ? HTColors.primary : HTColors.border,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Row(
          children: [
            // Slot ID
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: HTColors.background,
                border: Border.all(color: HTColors.border),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '0${widget.slotNumber}',
                style: HTTypography.statMedium.copyWith(color: HTColors.textSecondary),
              ),
            ),
            const SizedBox(width: 24.0),
            
            // Content
            Expanded(
              child: widget.isEmpty
                  ? Text(
                      '[ EMPTY CORE SLOT ]',
                      style: HTTypography.metricLabel.copyWith(
                        color: HTColors.textMuted,
                        letterSpacing: 2.0,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.companyName!, style: HTTypography.statMedium),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            Text('Simulation Date: ${widget.gameDate!}', style: HTTypography.bodySmall),
                            const SizedBox(width: 16.0),
                            Text('Last Written: ${widget.timestamp!}', style: HTTypography.bodySmall.copyWith(color: HTColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
            ),
            
            // Action Button
            if (!widget.isEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('RESTORE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHovered ? HTColors.primary : HTColors.surfaceVariant,
                  foregroundColor: _isHovered ? HTColors.textOnPrimary : HTColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                ),
                onPressed: widget.onRestore,
              ),
          ],
        ),
      ),
    );
  }
}
