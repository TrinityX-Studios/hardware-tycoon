import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/game_state_provider.dart';
import '../../../core/game_state.dart';
import '../../../models/silicon_project.dart';
import '../../../managers/audio_manager.dart';

enum PackageForm {
  bareDie('BARE DIE'),
  ceramicDip('CERAMIC DIP'),
  sealedModule('SEALED MODULE');

  const PackageForm(this.label);
  final String label;
}

class ProcessNodeOption {
  final String id;
  final String label;
  final double lithography;
  final String requiredTechId;

  const ProcessNodeOption({
    required this.id,
    required this.label,
    required this.lithography,
    required this.requiredTechId,
  });
}

const List<ProcessNodeOption> _processNodeOptions = [
  ProcessNodeOption(
    id: 'fab_bjt',
    label: 'BJT (50 µm)',
    lithography: 50.0,
    requiredTechId: 'fab_bjt',
  ),
  ProcessNodeOption(
    id: 'fab_ttl',
    label: 'TTL (25 µm)',
    lithography: 25.0,
    requiredTechId: 'fab_ttl',
  ),
  ProcessNodeOption(
    id: 'fab_cmos',
    label: 'CMOS (3 µm)',
    lithography: 3.0,
    requiredTechId: 'fab_cmos',
  ),
  ProcessNodeOption(
    id: 'fab_euv_early',
    label: 'EUV (0.010 µm)',
    lithography: 0.01,
    requiredTechId: 'fab_euv_early',
  ),
];

class DesignInitPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onFocus;

  const DesignInitPanel({
    super.key,
    required this.onClose,
    this.onFocus,
  });

  @override
  State<DesignInitPanel> createState() => _DesignInitPanelState();
}

class _DesignInitPanelState extends State<DesignInitPanel> {
  String _projectName = 'PROJECT_ALPHA';
  final TextEditingController _projectNameController = TextEditingController(text: 'PROJECT_ALPHA');
  final ChipTarget _selectedTarget = ChipTarget.cpu;
  final LicensingModel _selectedParadigm = LicensingModel.proprietary;
  CasingType _selectedCasing = CasingType.bareDie;
  final BitWidth _selectedBitWidth = BitWidth.bit8;
  PackageForm _selectedPackageForm = PackageForm.bareDie;
  String _selectedProcessNodeId = 'fab_ttl';
  double _targetFrequencyMhz = 20.0;
  double _operatingVoltageV = 3.3;
  double _l1Kb = 8.0;
  double _l2Kb = 32.0;
  double _l3Kb = 128.0;

  @override
  void initState() {
    super.initState();
    _projectNameController.selection = TextSelection.collapsed(offset: _projectName.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GameStateProvider.of(context);
      final maxFreq = state.unlockedMaxFrequencyHz / 1e6;
      setState(() {
        _selectedProcessNodeId = _processNodeOptions
            .firstWhere(
              (node) => state.isNodeUnlocked(node.requiredTechId),
              orElse: () => _processNodeOptions.first,
            )
            .id;
        _targetFrequencyMhz = min(max(20.0, maxFreq / 3.0), maxFreq);
        _operatingVoltageV = state.isNodeUnlocked('fab_cmos') ? 1.3 : 3.3;
      });
    });
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  ProcessNodeOption get _selectedProcessNode {
    return _processNodeOptions.firstWhere(
      (option) => option.id == _selectedProcessNodeId,
      orElse: () => _processNodeOptions.first,
    );
  }

  bool get _isGpuLocked {
    final state = GameStateProvider.of(context);
    return !state.isNodeUnlocked('arch_pipeline');
  }

  bool get _isFpgaLocked {
    final state = GameStateProvider.of(context);
    return !state.isNodeUnlocked('arch_fpga');
  }

  double get _baseUnitCost {
    final casingModifier = {
      CasingType.bareDie: -10000.0,
      CasingType.ceramicDIP: 0.0,
      CasingType.picc: 5000.0,
      CasingType.seccCartridge: 25000.0,
      CasingType.PGA: 15000.0,
      CasingType.BGA: 30000.0,
      CasingType.LGA: 50000.0,
    }[_selectedCasing]!;

    final packageModifier = _selectedPackageForm == PackageForm.ceramicDip
        ? 8000.0
        : _selectedPackageForm == PackageForm.sealedModule
            ? 14000.0
            : 0.0;

    final cacheCost = (_l1Kb + _l2Kb + _l3Kb) * 0.14;
    final targetCost = _targetFrequencyMhz * 9.0;
    final targetPremium = _selectedTarget == ChipTarget.gpu
        ? 12000.0
        : _selectedTarget == ChipTarget.fpga
            ? 14000.0
            : 0.0;

    return (18000.0 + casingModifier + packageModifier + cacheCost + targetCost + targetPremium)
        .clamp(6000.0, 250000.0);
  }

  double get _estimatedDevelopmentMonths {
    final state = GameStateProvider.of(context);
    final base = 4.0 + (_targetFrequencyMhz / 150.0) + (_l1Kb + _l2Kb + _l3Kb) / 256.0;
    final bitWidthPenalty = _selectedBitWidth == BitWidth.bit8
        ? 0.0
        : _selectedBitWidth == BitWidth.bit16
            ? 1.5
            : _selectedBitWidth == BitWidth.bit32
                ? 3.0
                : 5.0;
    final researchMultiplier = state.globalPerformanceMultiplier > 1.0 ? 0.9 : 1.0;
    return (base + bitWidthPenalty) * researchMultiplier;
  }

  double get _projectedYield {
    final state = GameStateProvider.of(context);
    final base = 0.54 + (state.globalYieldMultiplier - 1.0) * 0.06;
    final nodeDiscount = (_selectedProcessNode.lithography <= 3.0 ? 0.08 : 0.0);
    final frequencyPenalty = (_targetFrequencyMhz / max(1.0, state.unlockedMaxFrequencyHz / 1e6)) * 0.14;
    return (base + nodeDiscount - frequencyPenalty).clamp(0.18, 0.95);
  }

  double get _powerWatts {
    final packageFactor = _selectedPackageForm == PackageForm.sealedModule ? 1.18 : 1.0;
    final cacheFactor = 1.0 + (_l1Kb + _l2Kb + _l3Kb) / 1024.0 * 0.08;
    final frequencyFactor = _targetFrequencyMhz / 100.0;
    final voltageFactor = _operatingVoltageV * _operatingVoltageV;
    return (0.08 * voltageFactor * frequencyFactor * cacheFactor * packageFactor).clamp(0.2, 220.0);
  }

  double get _heatLevel {
    return (_powerWatts * 1.4 + (_selectedCasing == CasingType.bareDie ? 6.0 : 0.0)).clamp(30.0, 98.0);
  }

  String get _performanceDisplay {
    final state = GameStateProvider.of(context);
    final base = _targetFrequencyMhz * (1.0 + _selectedBitWidth.index * 0.35);
    final tuned = base * state.globalPerformanceMultiplier * (_selectedTarget == ChipTarget.gpu ? 1.2 : 1.0);
    if (tuned < 1000.0) {
      return '${tuned.toStringAsFixed(1)} MIPS';
    }
    return '${(tuned / 1000.0).toStringAsFixed(2)} KiloFLOPS';
  }

  Map<String, BinningTierSpec>? _buildMarketSegments(int year) {
    if (year < 1989) return null;
    return {
      'High-End': BinningTierSpec(
        clockOverrideMhz: _targetFrequencyMhz * 1.08,
        voltageOverrideV: max(0.95, _operatingVoltageV * 0.98),
        yieldOverridePct: min(0.98, _projectedYield + 0.04),
      ),
      'Mid-Tier': BinningTierSpec(
        clockOverrideMhz: _targetFrequencyMhz,
        voltageOverrideV: _operatingVoltageV,
        yieldOverridePct: _projectedYield,
      ),
      'Budget': BinningTierSpec(
        clockOverrideMhz: _targetFrequencyMhz * 0.84,
        voltageOverrideV: max(0.85, _operatingVoltageV * 0.92),
        yieldOverridePct: max(0.60, _projectedYield - 0.06),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);
    final year = state.gameDate.year;
    final maxFreqMhz = state.unlockedMaxFrequencyHz / 1e6;
    if (_targetFrequencyMhz > maxFreqMhz) {
      _targetFrequencyMhz = maxFreqMhz;
    }

    final bool isMobile = MediaQuery.of(context).size.width <= 700;

    final leftPanel = _buildLeftPanel(state, year);
    final rightPanel = _buildRightPanel(state, maxFreqMhz);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => widget.onFocus?.call(),
      child: Container(
        color: HTColors.background,
        padding: EdgeInsets.all(isMobile ? 8.0 : 14.0),
        child: Column(
          children: [
            _buildSectionHeader('PRODUCT CREATION PANEL'),
            const SizedBox(height: 10.0),
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          leftPanel,
                          const SizedBox(height: 12.0),
                          rightPanel,
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(flex: 3, child: leftPanel),
                        const SizedBox(width: 12.0),
                        Flexible(flex: 7, child: rightPanel),
                      ],
                    ),
            ),
            const SizedBox(height: 10.0),
            _buildActionBar(state, year),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(GameStateNotifier state, int year) {
    return Container(
      decoration: HTDecorations.panelBox(),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('REAL-TIME PROJECTIONS', style: HTTypography.panelHeader),
          const SizedBox(height: 12.0),
          TextField(
            style: HTTypography.listTitle.copyWith(color: HTColors.textPrimary, fontSize: 11),
            decoration: const InputDecoration(
              labelText: 'PRODUCT NAME',
              labelStyle: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 10),
              filled: true,
              fillColor: HTColors.surface,
              border: OutlineInputBorder(borderSide: BorderSide(color: HTColors.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: HTColors.primary)),
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            ),
            controller: _projectNameController,
            onChanged: (value) => setState(() => _projectName = value),
          ),
          const SizedBox(height: 12.0),
          _buildMetricRow('BASE UNIT COST', '\$${_baseUnitCost.toStringAsFixed(0)}'),
          const SizedBox(height: 8.0),
          _buildMetricRow('EST. DEVELOPMENT TIME', '${_estimatedDevelopmentMonths.toStringAsFixed(1)} mo'),
          const Divider(color: HTColors.border, height: 18.0),
          _buildMetricRow('LIVE WAFER YIELD', '${(_projectedYield * 100).toStringAsFixed(1)}%'),
          const SizedBox(height: 6.0),
          _buildMetricRow('HEAT LEVEL', '${_heatLevel.toStringAsFixed(1)} °C'),
          const SizedBox(height: 6.0),
          _buildMetricRow('POWER CONSUMPTION', '${_powerWatts.toStringAsFixed(1)} W'),
          const SizedBox(height: 6.0),
          _buildMetricRow('PERFORMANCE', _performanceDisplay),
          const SizedBox(height: 14.0),
          const Text('MANUFACTURING TELEMETRY', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          _buildTelemetryLine('PROCESS NODE', _selectedProcessNode.label),
          _buildTelemetryLine('PACKAGE FORM', _selectedPackageForm.label),
          _buildTelemetryLine('CASH FLOW PROFILE', _selectedParadigm == LicensingModel.proprietary ? 'PROPRIETARY IDM' : 'IP LICENSOR'),
          const SizedBox(height: 14.0),
          _buildWarnings(state, year),
        ],
      ),
    );
  }

  Widget _buildRightPanel(GameStateNotifier state, double maxFreqMhz) {
    final isMobile = MediaQuery.of(context).size.width <= 700;
    final maxL1 = state.isNodeUnlocked('cache_l1_integrated') ? 64.0 : 16.0;
    final maxL2 = state.isNodeUnlocked('arch_32bit') ? 256.0 : 64.0;
    final maxL3 = state.isNodeUnlocked('fab_cmos') ? 1024.0 : 256.0;

    return Container(
      decoration: HTDecorations.panelBox(),
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PARAMETER CONFIGURATION', style: HTTypography.panelHeader),
            const SizedBox(height: 12.0),
            Text('PACKAGE FORM', style: HTTypography.metricLabel),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: PackageForm.values.map((form) {
                final isSelected = form == _selectedPackageForm;
                return ChoiceChip(
                  label: Text(form.label, style: const TextStyle(fontSize: 10, fontFamily: 'IBMPlexMono')),
                  selected: isSelected,
                  selectedColor: HTColors.primary.withValues(alpha: 0.18),
                  onSelected: (_) => setState(() => _selectedPackageForm = form),
                );
              }).toList(),
            ),
            const SizedBox(height: 14.0),
            Text('PROCESS NODE', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Container(
              decoration: BoxDecoration(
                color: HTColors.surface,
                border: Border.all(color: HTColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProcessNodeId,
                  dropdownColor: HTColors.surface,
                  items: _processNodeOptions.map((node) {
                    final enabled = state.isNodeUnlocked(node.requiredTechId);
                    return DropdownMenuItem<String>(
                      value: node.id,
                      enabled: enabled,
                      child: Text(
                        enabled ? node.label : '${node.label} (LOCKED)',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 10.0,
                          color: enabled ? HTColors.textPrimary : HTColors.textMuted,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProcessNodeId = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            Text('OPERATING FREQUENCY', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Target frequency', style: HTTypography.listTitle.copyWith(fontSize: 10))),
                Text('${_targetFrequencyMhz.toStringAsFixed(1)} MHz', style: HTTypography.badge.copyWith(color: HTColors.primary, fontSize: 10)),
              ],
            ),
            Slider(
              value: _targetFrequencyMhz,
              min: min(1.0, maxFreqMhz),
              max: maxFreqMhz,
              divisions: max(1, maxFreqMhz ~/ 1),
              activeColor: HTColors.primary,
              inactiveColor: HTColors.border,
              onChanged: (value) => setState(() { _targetFrequencyMhz = value; }),
            ),
            const SizedBox(height: 18.0),
            Text('MEMORY & CACHE HIERARCHY', style: HTTypography.metricLabel),
            const SizedBox(height: 8.0),
            _buildSliderControl('L1 CACHE', _l1Kb, 0.0, maxL1, 'KB', (value) => setState(() => _l1Kb = value)),
            const SizedBox(height: 10.0),
            _buildSliderControl('L2 CACHE', _l2Kb, 0.0, maxL2, 'KB', (value) => setState(() => _l2Kb = value)),
            const SizedBox(height: 10.0),
            _buildSliderControl('L3 CACHE', _l3Kb, 0.0, maxL3, 'KB', (value) => setState(() => _l3Kb = value)),
            const SizedBox(height: 18.0),
            Text('PACKAGING CASING PROFILE', style: HTTypography.metricLabel),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: CasingType.values.map((casing) {
                final isUnlocked = casing.isUnlocked;
                final isSelected = casing == _selectedCasing;
                return ChoiceChip(
                  label: Text(casing.label, style: const TextStyle(fontSize: 10, fontFamily: 'IBMPlexMono')),
                  selected: isSelected,
                  selectedColor: HTColors.primary.withValues(alpha: 0.18),
                  onSelected: isUnlocked ? (_) => setState(() => _selectedCasing = casing) : null,
                  backgroundColor: HTColors.surface,
                  disabledColor: HTColors.surfaceVariant,
                );
              }).toList(),
            ),
            const SizedBox(height: 12.0),
            Text('POWER POLICY', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Container(
              decoration: HTDecorations.panelBox(),
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Frequency updates instantly drive power dissipation projections on the left. No external verification gate blocks product commitment.',
                style: HTTypography.bodySmall.copyWith(fontSize: 9.0),
              ),
            ),
            if (isMobile) const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderControl(String label, double value, double minValue, double maxValue, String unit, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: HTTypography.metricLabel.copyWith(fontSize: 10))),
            Text('${value.round()} $unit', style: HTTypography.badge.copyWith(fontSize: 10)),
          ],
        ),
        Slider(
          value: value,
          min: minValue,
          max: maxValue,
          divisions: maxValue > 0 ? (maxValue / max(1.0, minValue)).round() : null,
          activeColor: HTColors.primary,
          inactiveColor: HTColors.border,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionBar(GameStateNotifier state, int year) {
    final developmentReady = !_isGpuLocked || _selectedTarget != ChipTarget.gpu;
    final tapeoutLabel = 'DEVELOP / TAPEOUT';
    final project = SiliconProject(
      projectName: _projectName.trim().isEmpty ? 'UNTITLED_PROJECT' : _projectName.trim().toUpperCase(),
      type: _selectedTarget,
      paradigm: _selectedParadigm,
      scope: DesignScope.productLiteral,
      casing: _selectedCasing,
      bitWidth: _selectedBitWidth,
      targetLithography: _selectedProcessNode.lithography,
      isRefresh: false,
      technicalDebtFactor: 0.0,
      projectedFlops: (_targetFrequencyMhz * (1.0 + _selectedBitWidth.index * 0.35) * (state.globalPerformanceMultiplier))
          .clamp(0.0, 1000000.0),
      powerWatts: _powerWatts,
      clockSpeedMhz: _targetFrequencyMhz,
      projectedYieldPct: _projectedYield,
      tapeoutCostTicks: _baseUnitCost,
      ihs: IhsMaterial.none,
      enabledExtensions: {
        'basic_alu': true,
        'custom_isa': false,
        'hardware_mul_div': false,
        'bcd_math': false,
        'cisc_layout': false,
        'vliw_layout': false,
      },
      cacheAllocation: CacheAllocation.none,
      maxExtDramCapacity: ExtDramCapacity.none,
      marketSegments: _buildMarketSegments(year),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: HTColors.surfaceVariant,
        border: Border.all(color: HTColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PRODUCT DESIGN READY FOR COMPLETE FOUNDARY COMMITMENT',
              style: HTTypography.metricLabel.copyWith(fontSize: 10),
            ),
          ),
          ElevatedButton(
            onPressed: developmentReady
                ? () {
                    AudioManager.instance.playSFX('audio/sounds/click.wav');
                    state.tapeoutProject(project);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('TAPEOUT COMMITTED: ${project.projectName} queued for foundry production.'),
                        backgroundColor: HTColors.success,
                      ),
                    );
                    widget.onClose();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: HTColors.primary,
              foregroundColor: HTColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
            ),
            child: Text(tapeoutLabel, style: const TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(GameStateNotifier state, int year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedTarget == ChipTarget.gpu && _isGpuLocked)
          _buildWarningMessage('[LOCKED] GPU development requires ARCH_PIPELINE research.', Colors.redAccent),
        if (_selectedTarget == ChipTarget.fpga && _isFpgaLocked)
          _buildWarningMessage('[LOCKED] FPGA development requires ARCH_FPGA research.', Colors.redAccent),
        if (year < 1989)
          _buildWarningMessage('[NOTE] 1989 binning support will enable price-tier overrides after the market transitions.', HTColors.primary),
      ],
    );
  }

  Widget _buildTelemetryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: HTTypography.metricLabel.copyWith(fontSize: 9))),
          Text(value, style: HTTypography.badge.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: HTTypography.metricLabel.copyWith(fontSize: 9))),
          Text(value, style: HTTypography.badge.copyWith(color: HTColors.primary, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: HTColors.surface,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          color: HTColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildWarningMessage(String message, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        message,
        style: TextStyle(fontFamily: 'IBMPlexMono', color: color, fontSize: 9.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
