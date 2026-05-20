import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/game_state_provider.dart';
import '../../../core/game_state.dart';
import '../../../models/silicon_project.dart';
import '../../../models/research_node.dart';
import '../../../models/company_state.dart';
import '../../../managers/audio_manager.dart';

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
  // Wizard Phase: 0 = Domain/Objective, 1 = Architecture Checklist, 2 = Physical Tuning, 3 = mechanical Assembly
  int _currentStep = 0;

  String _projectName = 'PROJECT_ALPHA';
  ChipTarget _selectedTarget = ChipTarget.cpu;
  LicensingModel _selectedParadigm = LicensingModel.proprietary;
  DesignScope _selectedScope = DesignScope.architecture;
  String? _selectedParentArchitectureName;
  CasingType _selectedCasing = CasingType.bareDie;
  BitWidth _selectedBitWidth = BitWidth.bit4;

  CustomDieLayout? _selectedLayout;
  IhsMaterial _selectedIhs = IhsMaterial.none;

  bool _isRefresh = false;
  SiliconProject? _refreshedFromProject;

  double _lithoOverrideVal = 25.0; // In micrometers (µm)

  // Architectural Checkboxes (Instruction Set Flagging)
  bool _hasMmx = false;
  bool _hasSse = false;
  bool _hasCustomIsa = false;
  bool _hasFpu = false;
  bool _hasDsp = false;

  // Operating Sliders
  double _maxClockMhz = 100.0;
  double _operatingVoltageV = 3.3;

  CacheAllocation _selectedCache = CacheAllocation.none;
  ExtDramCapacity _selectedDram = ExtDramCapacity.none;

  final Map<String, bool> _enabledExtensions = {
    'basic_alu': true,
    'hardware_mul_div': false,
    'bcd_math': false,
    'cisc_layout': true,
    'vliw_layout': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GameStateProvider.of(context);
      final year = state.gameDate.year;
      final floor = _getResearchedLithoFloor(state);
      final double baseLitho = (50.0 - (year - 1960) * 0.7).clamp(floor, 50.0);
      setState(() {
        _lithoOverrideVal = baseLitho;
        // Seed default parameters based on era
        if (year >= 2000) {
          _maxClockMhz = 1200.0;
          _operatingVoltageV = 1.3;
        } else if (year >= 1990) {
          _maxClockMhz = 200.0;
          _operatingVoltageV = 3.3;
        } else if (year >= 1980) {
          _maxClockMhz = 16.0;
          _operatingVoltageV = 5.0;
        } else {
          _maxClockMhz = 2.0;
          _operatingVoltageV = 5.0;
        }
      });
    });
  }

  double _getResearchedLithoFloor(GameStateNotifier state) {
    if (state.isNodeUnlocked('fab_angstrom')) return 0.002;
    if (state.isNodeUnlocked('fab_euv_early')) return 0.010;
    if (state.isNodeUnlocked('fab_cmos')) return 1.2;
    if (state.isNodeUnlocked('fab_mosfet')) return 6.0;
    if (state.isNodeUnlocked('fab_ttl')) return 10.0;
    if (state.isNodeUnlocked('fab_bjt')) return 25.0;
    return 50.0;
  }

  String _getFloorNodeName(GameStateNotifier state) {
    if (state.isNodeUnlocked('fab_angstrom')) return 'ANGSTROM FAB';
    if (state.isNodeUnlocked('fab_euv_early')) return 'EARLY EUV';
    if (state.isNodeUnlocked('fab_cmos')) return 'CMOS SILICON';
    if (state.isNodeUnlocked('fab_mosfet')) return 'MOSFET TRANSISTORS';
    if (state.isNodeUnlocked('fab_ttl')) return 'TTL TRANSISTORS';
    if (state.isNodeUnlocked('fab_bjt')) return 'BIPOLAR JUNCTION';
    return 'BASIC VACUUM';
  }

  String _getCasingDropdownLabel(CasingType casing) {
    switch (casing) {
      case CasingType.bareDie:
        return 'BARE DIE (1960) - baseline wafer die (cost: -10k)';
      case CasingType.ceramicDIP:
        return 'CERAMIC DIP (1965) - gold wire bonded hermetic (cost: baseline)';
      case CasingType.picc:
        return 'PICC (1970) - plastic leaded chip carrier (cost: +5k)';
      case CasingType.seccCartridge:
        return 'SECC CARTRIDGE (1997) - daughtercard slot (+20% FLOPS, cost: +25k)';
      case CasingType.PGA:
        return 'PGA (1980) - advanced pin grid array (cost: +15k)';
      case CasingType.BGA:
        return 'BGA (1995) - high-density ball grid socket (cost: +30k)';
      case CasingType.LGA:
        return 'LGA (2004) - land socket contact layout (cost: +50k)';
    }
  }

  String _getIhsDropdownLabel(IhsMaterial ihs) {
    switch (ihs) {
      case IhsMaterial.none:
        return 'BARE DIE - standard bare thermal junction';
      case IhsMaterial.aluminum:
        return 'ANODIZED ALUMINUM IHS (1970) - (+15% clock, -15% power, cost: +8k)';
      case IhsMaterial.copperLid:
        return 'NICKEL-PLATED COPPER SLUG (2000) - (+35% clock, -30% power, cost: +18k)';
    }
  }

  int get _totalSteps {
    switch (_selectedScope) {
      case DesignScope.architecture:
        return 2;
      case DesignScope.coreUnit:
        return 3;
      case DesignScope.productLiteral:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GameStateProvider.of(context);
    final year = state.gameDate.year;

    // Lithography calculations
    final floor = _getResearchedLithoFloor(state);
    final double baseLitho = (50.0 - (year - 1960) * 0.7).clamp(floor, 50.0);
    if (_lithoOverrideVal < floor) {
      _lithoOverrideVal = floor;
    }
    final double maxLitho = baseLitho * 1.6;

    // Phase 1: Objective & Gating logic
    final isGpuLocked = !state.isNodeUnlocked('arch_pipeline');
    final isFpgaLocked = !state.isNodeUnlocked('arch_fpga');
    final bool isTargetLocked = (_selectedTarget == ChipTarget.gpu && isGpuLocked) ||
        (_selectedTarget == ChipTarget.fpga && isFpgaLocked);

    // Phase 2: Checklist unlocks status
    final isMmxUnlocked = state.isNodeUnlocked('arch_pipeline');
    final isSseUnlocked = state.isNodeUnlocked('arch_32bit');
    final isCustomIsaUnlocked = state.isNodeUnlocked('arch_risc');
    final isFpuUnlocked = state.isNodeUnlocked('math_coprocessor');
    final isDspUnlocked = state.isNodeUnlocked('digital_signal_processing');

    // BitWidth unlocking status
    final isBitWidthLocked = !_selectedBitWidth.isUnlocked;

    // Casing unlocking status
    final isCasingLocked = !_selectedCasing.isUnlocked;

    // IHS unlocking status
    final isIhsLocked = !_selectedIhs.isUnlocked;

    // Layout gating checks
    String? layoutGateWarning;
    bool isLayoutGated = false;
    if (_selectedLayout != null) {
      for (final comp in _selectedLayout!.components) {
        if (comp.type == 'ALU Core' && !state.isNodeUnlocked('arch_alu')) {
          isLayoutGated = true;
          layoutGateWarning = '[!] SCHEMA BLOCKED: Missing ALU Core R&D for selected layout.';
          break;
        }
        if (comp.type == 'Reg File' && !state.isNodeUnlocked('arch_8bit')) {
          isLayoutGated = true;
          layoutGateWarning = '[!] SCHEMA BLOCKED: Missing 8-bit Register File R&D for selected layout.';
          break;
        }
        if (comp.type == 'Interconnect Bus' && !state.isNodeUnlocked('arch_central_bus')) {
          isLayoutGated = true;
          layoutGateWarning = '[!] SCHEMA BLOCKED: Missing Central Interconnect Bus R&D for selected layout.';
          break;
        }
      }
    }

    // Technical Debt logic
    double techDebt = 0.0;
    bool isThirdConsecutive = false;
    if (_isRefresh && _refreshedFromProject != null) {
      techDebt = 0.20;
      int consecutiveCount = 0;
      for (final p in state.activeProductsRegistry.reversed) {
        if (p.isRefresh) {
          consecutiveCount++;
        } else {
          break;
        }
      }
      if (consecutiveCount >= 2) {
        isThirdConsecutive = true;
        techDebt = 0.40;
      }
    }

    // Projections Calculations
    final rndStaffCount = state.employees.where((e) => e.assignment == WorkAssignment.rnd).length;
    final double staffPerfMult = (1.0 + 0.15 * rndStaffCount) * (0.5 + 0.5 * state.corporateMood);

    double bitWidthGenMult = 1.0;
    if (_selectedBitWidth == BitWidth.bit8) bitWidthGenMult = 2.5;
    if (_selectedBitWidth == BitWidth.bit16) bitWidthGenMult = 15.0;
    if (_selectedBitWidth == BitWidth.bit32) bitWidthGenMult = 350.0;
    if (_selectedBitWidth == BitWidth.bit64) bitWidthGenMult = 12000.0;

    double projectedFlops = 0.0;
    if (_selectedLayout != null) {
      projectedFlops = _selectedLayout!.kiloFlops * bitWidthGenMult;
    } else {
      double baseNodeFactor = 120.0;
      projectedFlops = (baseNodeFactor / _lithoOverrideVal) * (1.0 - techDebt) * staffPerfMult * bitWidthGenMult;
    }

    // Apply global tech multipliers
    projectedFlops = projectedFlops * state.globalPerformanceMultiplier;

    // Apply custom checkbox capability factors
    double checkboxPerfMult = 1.0;
    if (_hasMmx && isMmxUnlocked) checkboxPerfMult += 0.20;
    if (_hasSse && isSseUnlocked) checkboxPerfMult += 0.40;
    if (_hasCustomIsa && isCustomIsaUnlocked) checkboxPerfMult += 0.15;
    if (_hasFpu && isFpuUnlocked) checkboxPerfMult += 0.25;
    if (_hasDsp && isDspUnlocked) checkboxPerfMult += 0.30;

    // 1960s dynamic extension multipliers
    if (_enabledExtensions['hardware_mul_div'] == true) checkboxPerfMult += 0.30;
    if (_enabledExtensions['bcd_math'] == true) checkboxPerfMult += 0.15;
    if (_enabledExtensions['cisc_layout'] == true) checkboxPerfMult += 0.25;
    if (_enabledExtensions['vliw_layout'] == true) checkboxPerfMult += 0.20;

    projectedFlops *= checkboxPerfMult;
    
    // Apply Cache allocation multiplier to FLOPS/IPC
    projectedFlops *= _selectedCache.ipcMultiplier;

    if (_selectedCasing == CasingType.seccCartridge) {
      projectedFlops *= 1.20;
    }
    if (_isRefresh) {
      projectedFlops = projectedFlops.clamp(0.01, 85000.0);
    }

    // Dynamic Clock Calculations
    double ihsClockMult = 1.0;
    if (_selectedIhs == IhsMaterial.aluminum) ihsClockMult = 1.15;
    if (_selectedIhs == IhsMaterial.copperLid) ihsClockMult = 1.35;

    double maxPhysicalMhz = (12.0 / _lithoOverrideVal) * (_isRefresh ? 0.85 : 1.15) * (bitWidthGenMult * 0.5);
    maxPhysicalMhz = (maxPhysicalMhz * ihsClockMult).clamp(0.5, 4200.0);

    // Final clock limited by player selection slider and physical constraints
    double finalClockMhz = _maxClockMhz.clamp(0.5, maxPhysicalMhz);

    // Power calculations with IHS thermal efficiency multiplier using CMOS equation
    double thermalDissipationMult = 1.0;
    if (_selectedIhs == IhsMaterial.aluminum) thermalDissipationMult = 0.85;
    if (_selectedIhs == IhsMaterial.copperLid) thermalDissipationMult = 0.70;

    double capFactor = (_selectedScope.index + 1) * 2.0 * (1.0 / _lithoOverrideVal) * (_isRefresh ? 0.8 : 1.25) * (bitWidthGenMult * 0.15);
    double voltageFactorSq = _operatingVoltageV * _operatingVoltageV;
    double frequencyFactor = finalClockMhz / 100.0;
    
    // Add additional capacitance for active features
    double featureCapBonus = 1.0;
    if (_hasMmx && isMmxUnlocked) featureCapBonus += 0.10;
    if (_hasSse && isSseUnlocked) featureCapBonus += 0.15;
    if (_hasCustomIsa && isCustomIsaUnlocked) featureCapBonus -= 0.10; // Architecture optimization
    if (_hasFpu && isFpuUnlocked) featureCapBonus += 0.05;
    if (_hasDsp && isDspUnlocked) featureCapBonus += 0.12;

    // 1960s dynamic extension capacitance
    if (_enabledExtensions['hardware_mul_div'] == true) featureCapBonus += 0.10;
    if (_enabledExtensions['bcd_math'] == true) featureCapBonus += 0.05;
    if (_enabledExtensions['cisc_layout'] == true) featureCapBonus += 0.20;
    // Explicit Parallelism (VLIW) offloads logic to software compilers, keeping physical silicon cold (0W overhead)

    double powerWatts = capFactor * voltageFactorSq * frequencyFactor * featureCapBonus * thermalDissipationMult;
    
    // Apply Cache allocation power penalty
    powerWatts *= _selectedCache.powerMultiplier;
    
    powerWatts = powerWatts.clamp(0.1, 280.0);

    // Yield logic
    double projectedYield = 0.85;
    if (_lithoOverrideVal < baseLitho) {
      projectedYield = 0.85 * pow(_lithoOverrideVal / baseLitho, 1.8);
    } else {
      projectedYield = 0.85 + 0.1 * (_lithoOverrideVal / baseLitho);
    }

    double ihsYieldCushion = 1.0;
    if (_selectedIhs == IhsMaterial.aluminum) ihsYieldCushion = 1.05;
    if (_selectedIhs == IhsMaterial.copperLid) ihsYieldCushion = 1.12;

    // High operating voltage strain penalty
    double voltageStrainMult = 1.0;
    if (_operatingVoltageV > 4.5) {
      voltageStrainMult = 0.90;
    } else if (_operatingVoltageV > 3.6) {
      voltageStrainMult = 0.95;
    }

    projectedYield = (projectedYield * ihsYieldCushion * voltageStrainMult * state.globalYieldMultiplier).clamp(0.05, 0.98);

    // Tapeout cost computations
    double tapeoutCost = 50000.0;
    if (_selectedTarget == ChipTarget.gpu) tapeoutCost = 80000.0;
    if (_selectedTarget == ChipTarget.fpga) tapeoutCost = 100000.0;

    if (_selectedScope == DesignScope.coreUnit) tapeoutCost *= 1.2;
    if (_selectedScope == DesignScope.productLiteral) tapeoutCost *= 1.5;

    // Casing tapeout additions
    if (_selectedCasing == CasingType.bareDie) tapeoutCost -= 10000.0;
    if (_selectedCasing == CasingType.picc) tapeoutCost += 5000.0;
    if (_selectedCasing == CasingType.seccCartridge) tapeoutCost += 25000.0;
    if (_selectedCasing == CasingType.PGA) tapeoutCost += 15000.0;
    if (_selectedCasing == CasingType.BGA) tapeoutCost += 30000.0;
    if (_selectedCasing == CasingType.LGA) tapeoutCost += 50000.0;

    // IHS additions
    if (_selectedIhs == IhsMaterial.aluminum) tapeoutCost += 8000.0;
    if (_selectedIhs == IhsMaterial.copperLid) tapeoutCost += 18000.0;

    // Feature additions
    if (_hasMmx && isMmxUnlocked) tapeoutCost += 12000.0;
    if (_hasSse && isSseUnlocked) tapeoutCost += 25000.0;
    if (_hasCustomIsa && isCustomIsaUnlocked) tapeoutCost += 18000.0;
    if (_hasFpu && isFpuUnlocked) tapeoutCost += 15000.0;
    if (_hasDsp && isDspUnlocked) tapeoutCost += 22000.0;

    // 1960s dynamic extension tapeout cost
    if (_enabledExtensions['hardware_mul_div'] == true) tapeoutCost += 8000.0;
    if (_enabledExtensions['bcd_math'] == true) tapeoutCost += 5000.0;
    if (_enabledExtensions['cisc_layout'] == true) tapeoutCost += 10000.0;
    if (_enabledExtensions['vliw_layout'] == true) tapeoutCost += 12000.0;

    if (_selectedParadigm == LicensingModel.ipLicensing) tapeoutCost *= 1.5;
    if (_isRefresh) tapeoutCost *= 0.40;

    final bool isParentIsaMissing = _selectedScope == DesignScope.coreUnit && _selectedParentArchitectureName == null;

    final bool canInitialize = !isTargetLocked &&
        !isBitWidthLocked &&
        !isParentIsaMissing &&
        (_selectedScope != DesignScope.productLiteral ||
            (!isCasingLocked && !isLayoutGated && !isIhsLocked));

    // Architecture lockout: core unit and product literal require a completed architecture
    final bool isScopeLocked = !state.hasCompletedArchitecture &&
        (_selectedScope == DesignScope.coreUnit || _selectedScope == DesignScope.productLiteral);

    // Dynamic Navigation controls: block next if Phase 1 has locked GPU/FPGA, locked scope, or Phase 2 has locked BitWidth
    final bool nextDisabled = (_currentStep == 0 && (isTargetLocked || isScopeLocked || isParentIsaMissing)) ||
        (_currentStep == 1 && isBitWidthLocked);

    // Dynamic step cap adjustment
    int displayStep = _currentStep;
    if (displayStep >= _totalSteps) {
      displayStep = _totalSteps - 1;
    }

    final bool isMobile = MediaQuery.of(context).size.width <= 600;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => widget.onFocus?.call(),
      child: Container(
        color: HTColors.background,
        padding: EdgeInsets.all(isMobile ? 6.0 : 12.0),
        child: Column(
          children: [
            // Top Section Header with phase tracker
            _buildSectionHeader('SIMULATION TAPEOUT WIZARD - PHASE ${displayStep + 1} OF $_totalSteps'),
            SizedBox(height: isMobile ? 6.0 : 10.0),

            Expanded(
              child: _buildWizardStepContent(state, year, baseLitho, floor, layoutGateWarning, isThirdConsecutive, powerWatts, finalClockMhz, projectedYield, projectedFlops, maxLitho, capFactor),
            ),

            SizedBox(height: isMobile ? 6.0 : 10.0),

            // Bottom Actions Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 6.0 : 10.0, vertical: isMobile ? 6.0 : 8.0),
              color: HTColors.surfaceVariant,
              child: Row(
                children: [
                  Text('EST. TAPEOUT INVESTMENT: ', style: HTTypography.metricLabel),
                  Text(
                    '\$${tapeoutCost.toStringAsFixed(0)}',
                    style: HTTypography.metricValue.copyWith(color: HTColors.primary, fontSize: 12),
                  ),
                  const Spacer(),
                  // Cancel / Abort Button (Resets step to 0)
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _currentStep = 0);
                      widget.onClose();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HTColors.textSecondary,
                      side: const BorderSide(color: HTColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    ),
                    child: const Text('ABORT', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9)),
                  ),
                  const SizedBox(width: 8.0),

                  // PREVIOUS STEP
                  if (_currentStep > 0) ...[
                    ElevatedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HTColors.surface,
                        foregroundColor: HTColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                      child: const Text('PREV PHASE', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9)),
                    ),
                    const SizedBox(width: 8.0),
                  ],

                  // NEXT STEP
                  if (_currentStep < _totalSteps - 1)
                    ElevatedButton(
                      onPressed: nextDisabled ? null : () {
                        AudioManager.instance.playSFX('audio/sounds/click.wav');
                        setState(() => _currentStep++);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HTColors.primary,
                        foregroundColor: HTColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      ),
                      child: const Text('NEXT PHASE', style: TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold, fontSize: 9)),
                    )
                  else
                    // INITIALIZE TAPE OUT / COMPILE ARCHITECTURE SPEC
                    ElevatedButton(
                      onPressed: !canInitialize
                          ? null
                          : () {
                              final project = SiliconProject(
                                projectName: _projectName.trim().isEmpty ? 'UNTITLED_PROJECT' : _projectName.trim().toUpperCase(),
                                type: _selectedTarget,
                                paradigm: _selectedParadigm,
                                scope: _selectedScope,
                                casing: _selectedCasing,
                                ihs: _selectedIhs,
                                customLayoutName: _selectedLayout?.name,
                                bitWidth: _selectedBitWidth,
                                targetLithography: _lithoOverrideVal,
                                isRefresh: _isRefresh,
                                refreshedFromProjectName: _refreshedFromProject?.projectName,
                                technicalDebtFactor: techDebt,
                                projectedFlops: projectedFlops,
                                powerWatts: powerWatts,
                                clockSpeedMhz: finalClockMhz,
                                projectedYieldPct: projectedYield,
                                tapeoutCostTicks: tapeoutCost,
                                parentArchitectureName: _selectedParentArchitectureName,
                                enabledExtensions: {
                                  'fpu': _hasFpu,
                                  'mmx': _hasMmx,
                                  'sse': _hasSse,
                                  'dsp': _hasDsp,
                                  'custom_isa': _hasCustomIsa,
                                  'basic_alu': _enabledExtensions['basic_alu'] ?? true,
                                  'hardware_mul_div': _enabledExtensions['hardware_mul_div'] ?? false,
                                  'bcd_math': _enabledExtensions['bcd_math'] ?? false,
                                  'cisc_layout': _enabledExtensions['cisc_layout'] ?? true,
                                  'vliw_layout': _enabledExtensions['vliw_layout'] ?? false,
                                },
                                cacheAllocation: _selectedCache,
                                maxExtDramCapacity: _selectedDram,
                              );
                              if (project.scope == DesignScope.architecture) {
                                state.tapeoutProject(project);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('SPECIFICATION REGISTERED: ${project.projectName} SYSTEM SPEC COMPLIANT.'),
                                    backgroundColor: HTColors.success,
                                  ),
                                );
                                AudioManager.instance.playSFX('audio/sounds/success.wav');
                              } else {
                                state.startDesigningProject(project);
                              }
                              setState(() => _currentStep = 0); // reset
                              widget.onClose();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HTColors.primary,
                        foregroundColor: HTColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      ),
                      child: Text(
                        _selectedScope == DesignScope.architecture
                            ? 'COMPILE ARCHITECTURE SPEC'
                            : 'INITIALIZE DESIGN',
                        style: const TextStyle(fontFamily: 'IBMPlexMono', fontWeight: FontWeight.bold, fontSize: 9),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStepContent(
    GameStateNotifier state,
    int year,
    double baseLitho,
    double floor,
    String? layoutGateWarning,
    bool isThirdConsecutive,
    double powerWatts,
    double finalClockMhz,
    double projectedYield,
    double projectedFlops,
    double maxLitho,
    double capFactor,
  ) {
    int safeStep = _currentStep;
    if (safeStep >= _totalSteps) {
      safeStep = _totalSteps - 1;
    }
    switch (safeStep) {
      case 0:
        return _buildPhase1Domain(state, year);
      case 1:
        return _buildPhase2Architecture(state, year);
      case 2:
        return _buildPhase3Parameters(state);
      case 3:
        return _buildPhase4Assembly(state, year, baseLitho, floor, layoutGateWarning, isThirdConsecutive, powerWatts, finalClockMhz, projectedYield, projectedFlops, maxLitho, capFactor);
      default:
        return Container();
    }
  }

  // PHASE 1: Project Objective Definition View
  Widget _buildPhase1Domain(GameStateNotifier state, int year) {
    final isGpuLocked = !state.isNodeUnlocked('arch_pipeline');
    final isFpgaLocked = !state.isNodeUnlocked('arch_fpga');
    final bool isTargetLocked = (_selectedTarget == ChipTarget.gpu && isGpuLocked) ||
        (_selectedTarget == ChipTarget.fpga && isFpgaLocked);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubsectionHeader('PHASE 1: PROJECT OBJECTIVE DEFINITION'),
          const SizedBox(height: 10.0),

          // WHAT ARE WE DEVELOPING?
          Text('WHAT ARE WE DEVELOPING?', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Builder(
            builder: (context) {
              final hasArch = state.hasCompletedArchitecture;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: DesignScope.values.map((scope) {
                      final isSelected = _selectedScope == scope;
                      final bool isScopeDisabled = !hasArch &&
                          (scope == DesignScope.coreUnit || scope == DesignScope.productLiteral);
                      String label = '';
                      switch (scope) {
                        case DesignScope.architecture:
                          label = 'DESIGN NEW ARCHITECTURE';
                          break;
                        case DesignScope.coreUnit:
                          label = 'DESIGN CORE UNIT';
                          break;
                        case DesignScope.productLiteral:
                          label = 'DESIGN LITERAL PRODUCT';
                          break;
                      }
                      return Expanded(
                        child: GestureDetector(
                          onTap: isScopeDisabled
                              ? null
                              : () => setState(() {
                                    _selectedScope = scope;
                                    if (scope == DesignScope.coreUnit) {
                                      if (state.savedArchitectures.isNotEmpty) {
                                        final firstArch = state.savedArchitectures.first;
                                        _selectedParentArchitectureName = firstArch.projectName;
                                        _selectedBitWidth = firstArch.bitWidth;
                                        _selectedTarget = firstArch.type;
                                        _hasFpu = firstArch.hasFpu;
                                        _hasMmx = firstArch.hasMmx;
                                        _hasSse = firstArch.hasSse;
                                        _hasDsp = firstArch.hasDsp;
                                        _hasCustomIsa = firstArch.hasCustomIsa;
                                        _enabledExtensions.clear();
                                        _enabledExtensions.addAll(firstArch.enabledExtensions);
                                      }
                                    } else {
                                      _selectedParentArchitectureName = null;
                                      if (scope == DesignScope.architecture) {
                                        _selectedBitWidth = BitWidth.bit8;
                                        _enabledExtensions.clear();
                                        _enabledExtensions.addAll({
                                          'basic_alu': true,
                                          'hardware_mul_div': false,
                                          'bcd_math': false,
                                          'cisc_layout': true,
                                          'vliw_layout': false,
                                        });
                                      }
                                    }
                                  }),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isScopeDisabled ? HTColors.error.withValues(alpha: 0.1) : HTColors.primary.withValues(alpha: 0.15))
                                  : HTColors.surface,
                              border: Border.all(
                                color: isSelected
                                    ? (isScopeDisabled ? HTColors.error : HTColors.primary)
                                    : (isScopeDisabled ? HTColors.border.withValues(alpha: 0.4) : HTColors.border),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: HTTypography.badge.copyWith(
                                  color: isScopeDisabled
                                      ? HTColors.textMuted
                                      : (isSelected ? HTColors.primary : HTColors.textSecondary),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  decoration: isScopeDisabled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (!hasArch) ...[
                    const SizedBox(height: 8.0),
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: HTColors.error.withValues(alpha: 0.08),
                        border: Border.all(color: HTColors.error, width: 0.5),
                      ),
                      child: const Text(
                        '[ CORRECTIONS REQUIRED: DEPLOY AN ISA VIA "DESIGN NEW ARCHITECTURE" TO UNLOCK MANUFACTURING ]',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          color: HTColors.error,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (_selectedScope == DesignScope.coreUnit) ...[
            const SizedBox(height: 12.0),
            Text('SELECT BASE INSTRUCTION SET ARCHITECTURE (ISA)', style: HTTypography.metricLabel),
            const SizedBox(height: 4.0),
            DropdownButtonFormField<String>(
              initialValue: _selectedParentArchitectureName,
              dropdownColor: const Color(0xFF0F172A),
              style: HTTypography.listTitle.copyWith(color: HTColors.textPrimary, fontSize: 11),
              decoration: const InputDecoration(
                filled: true,
                fillColor: HTColors.surface,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: HTColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: HTColors.primary)),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
              hint: const Text(
                'SELECT BASE ISA BASELINE...',
                style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.0, color: HTColors.textMuted),
              ),
              items: state.savedArchitectures.map((arch) {
                return DropdownMenuItem<String>(
                  value: arch.projectName,
                  child: Text(
                    '${arch.projectName} [${arch.bitWidth.label} • ${arch.type.name.toUpperCase()}]',
                    style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.0, color: HTColors.textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedParentArchitectureName = val;
                  if (val != null) {
                    final parentIsa = state.savedArchitectures.firstWhere(
                      (arch) => arch.projectName == val,
                    );
                    _selectedBitWidth = parentIsa.bitWidth;
                    _selectedTarget = parentIsa.type;
                    _hasFpu = parentIsa.hasFpu;
                    _hasMmx = parentIsa.hasMmx;
                    _hasSse = parentIsa.hasSse;
                    _hasDsp = parentIsa.hasDsp;
                    _hasCustomIsa = parentIsa.hasCustomIsa;
                    _enabledExtensions.clear();
                    _enabledExtensions.addAll(parentIsa.enabledExtensions);
                  }
                });
              },
            ),
          ],
          const SizedBox(height: 14.0),

          // PROJECT CODE NAME
          Text('PROJECT CODE NAME', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          TextField(
            style: HTTypography.listTitle.copyWith(color: HTColors.textPrimary, fontSize: 11),
            decoration: const InputDecoration(
              filled: true,
              fillColor: HTColors.surface,
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: HTColors.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: HTColors.primary)),
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            ),
            onChanged: (val) => setState(() => _projectName = val),
            controller: TextEditingController(text: _projectName)..selection = TextSelection.collapsed(offset: _projectName.length),
          ),
          const SizedBox(height: 14.0),

          // CHIP TARGET
          Text('CHIP ARCHITECTURE TARGET', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Row(
            children: ChipTarget.values.map((target) {
              final isSelected = _selectedTarget == target;
              final label = target.name.toUpperCase();
              final isLocked = (target == ChipTarget.gpu && isGpuLocked) ||
                  (target == ChipTarget.fpga && isFpgaLocked);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTarget = target),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isLocked ? HTColors.error.withValues(alpha: 0.15) : HTColors.primary.withValues(alpha: 0.15)) 
                          : HTColors.surface,
                      border: Border.all(
                        color: isSelected 
                            ? (isLocked ? HTColors.error : HTColors.primary) 
                            : HTColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: HTTypography.badge.copyWith(
                          color: isSelected 
                              ? (isLocked ? HTColors.error : HTColors.primary) 
                              : (isLocked ? HTColors.textMuted : HTColors.textSecondary),
                          fontSize: 8.0,
                          decoration: isLocked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (isTargetLocked) ...[
            const SizedBox(height: 6.0),
            _buildWarningMessage(
              _selectedTarget == ChipTarget.gpu
                  ? '[ LOCKED: GPU REQUIRES ACTIVE "INSTRUCTION PIPELINING" R&D ]'
                  : '[ LOCKED: FPGA REQUIRES ACTIVE "FIELD PROGRAMMABLE GATE ARRAY" R&D ]',
              Colors.redAccent,
            ),
          ],
          const SizedBox(height: 14.0),

          // LICENSING STRATEGY
          Text('PATENT & LICENSING STRATEGY', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedParadigm = LicensingModel.proprietary),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: _selectedParadigm == LicensingModel.proprietary ? HTColors.primary.withValues(alpha: 0.15) : HTColors.surface,
                      border: Border.all(
                        color: _selectedParadigm == LicensingModel.proprietary ? HTColors.primary : HTColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'PROPRIETARY IDM',
                        style: HTTypography.badge.copyWith(
                          color: _selectedParadigm == LicensingModel.proprietary ? HTColors.primary : HTColors.textSecondary,
                          fontSize: 8.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedParadigm = LicensingModel.ipLicensing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: _selectedParadigm == LicensingModel.ipLicensing ? HTColors.primary.withValues(alpha: 0.15) : HTColors.surface,
                      border: Border.all(
                        color: _selectedParadigm == LicensingModel.ipLicensing ? HTColors.primary : HTColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'FABLESS IP LICENSOR',
                        style: HTTypography.badge.copyWith(
                          color: _selectedParadigm == LicensingModel.ipLicensing ? HTColors.primary : HTColors.textSecondary,
                          fontSize: 8.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PHASE 2: Architectural Flags & Instruction Checklist View
  Widget _buildPhase2Architecture(GameStateNotifier state, int year) {
    if (_selectedScope == DesignScope.architecture) {
      final is16BitUnlocked = state.isNodeUnlocked('arch_16bit');
      final isBitWidthLocked = _selectedBitWidth == BitWidth.bit16 && !is16BitUnlocked;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubsectionHeader('PHASE 2: 1960s ARCHITECTURAL SPEC SHEET'),
            const SizedBox(height: 12.0),

            // 1. Bit-Width Configuration
            Text('1. BIT-WIDTH CONFIGURATION', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Container(
              decoration: HTDecorations.panelBox(),
              child: RadioGroup<BitWidth>(
                groupValue: _selectedBitWidth,
                onChanged: (val) {
                  if (val != null) {
                    if (val == BitWidth.bit16 && !is16BitUnlocked) return;
                    setState(() => _selectedBitWidth = val);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<BitWidth>(
                      title: const Text('8-Bit Data Word', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                      subtitle: const Text('Historical baseline standard.', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                      value: BitWidth.bit8,
                      activeColor: HTColors.primary,
                      dense: true,
                    ),
                    const Divider(color: HTColors.border, height: 1.0),
                    RadioListTile<BitWidth>(
                      title: const Text('16-Bit Data Word', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                      subtitle: Text(
                        is16BitUnlocked 
                            ? 'Late-60s premium compute throughput; adds transistor density (+150% FLOPS, +200% die area).' 
                            : '[ LOCKED: REQUIRES 16-BIT ARCHITECTURE R&D ]',
                        style: TextStyle(fontFamily: 'IBMPlexMono', color: is16BitUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                      ),
                      value: BitWidth.bit16,
                      activeColor: HTColors.primary,
                      dense: true,
                      enabled: is16BitUnlocked,
                    ),
                  ],
                ),
              ),
            ),
            if (isBitWidthLocked) ...[
              const SizedBox(height: 6.0),
              _buildWarningMessage(
                '[!] SELECTED BIT WIDTH IS LOCKED: REQUIRES 16-BIT ARCHITECTURE R&D.',
                HTColors.error,
              ),
            ],
            const SizedBox(height: 16.0),

            // 2. Execution Logic & ALU Flags
            Text('2. EXECUTION LOGIC & ALU FLAGS', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Container(
              decoration: HTDecorations.panelBox(),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Basic Integer ALU', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                    subtitle: const Text('Baseline execution (Add, Subtract, AND, OR, XOR). Always enabled.', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                    value: true,
                    enabled: false,
                    activeColor: HTColors.primary,
                    dense: true,
                    onChanged: null,
                  ),
                  const Divider(color: HTColors.border, height: 1.0),
                  CheckboxListTile(
                    title: const Text('Hardware Multiply/Divide', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                    subtitle: const Text('Increases performance by avoiding software loops. (+30% FLOPS, +10% capacitance, +\$8k cost)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                    value: _enabledExtensions['hardware_mul_div'] ?? false,
                    activeColor: HTColors.primary,
                    dense: true,
                    onChanged: (val) {
                      setState(() {
                        _enabledExtensions['hardware_mul_div'] = val ?? false;
                      });
                    },
                  ),
                  const Divider(color: HTColors.border, height: 1.0),
                  CheckboxListTile(
                    title: const Text('Binary-Coded Decimal (BCD) Math', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                    subtitle: const Text('Exact decimal module for banking/enterprise. (+15% FLOPS, +5% capacitance, +\$5k cost)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                    value: _enabledExtensions['bcd_math'] ?? false,
                    activeColor: HTColors.primary,
                    dense: true,
                    onChanged: (val) {
                      setState(() {
                        _enabledExtensions['bcd_math'] = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 3. Structural Architectural Philosophy
            Text('3. STRUCTURAL ARCHITECTURAL PHILOSOPHY', style: HTTypography.metricLabel),
            const SizedBox(height: 6.0),
            Container(
              decoration: HTDecorations.panelBox(),
              child: RadioGroup<String>(
                groupValue: _enabledExtensions['cisc_layout'] == true ? 'cisc' : (_enabledExtensions['vliw_layout'] == true ? 'vliw' : null),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (val == 'cisc') {
                        _enabledExtensions['cisc_layout'] = true;
                        _enabledExtensions['vliw_layout'] = false;
                      } else if (val == 'vliw') {
                        _enabledExtensions['cisc_layout'] = false;
                        _enabledExtensions['vliw_layout'] = true;
                      }
                    });
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Microcoded CISC Layout', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                      subtitle: const Text('Native hardware decoder handling multi-cycle instructions. (+25% FLOPS, +20% thermal power, +\$10k cost)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                      value: 'cisc',
                      activeColor: HTColors.primary,
                      dense: true,
                    ),
                    const Divider(color: HTColors.border, height: 1.0),
                    RadioListTile<String>(
                      title: const Text('Explicit Parallelism / Early VLIW Alternative', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                      subtitle: const Text('Complexity is offloaded to software compilers. Keeps physical silicon cold (0W overhead, 0% capacitance), but adds recurring R&D Compiler operating expenses (+\$50/day). (+20% FLOPS)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8)),
                      value: 'vliw',
                      activeColor: HTColors.primary,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isMmxUnlocked = state.isNodeUnlocked('arch_pipeline');
    final isSseUnlocked = state.isNodeUnlocked('arch_32bit');
    final isCustomIsaUnlocked = state.isNodeUnlocked('arch_risc');
    final isFpuUnlocked = state.isNodeUnlocked('math_coprocessor');
    final isDspUnlocked = state.isNodeUnlocked('digital_signal_processing');

    final isBitWidthLocked = !_selectedBitWidth.isUnlocked;
    final bitWidthTechNode = HistoricalTechTree.nodes.firstWhere((n) => n.id == _selectedBitWidth.requiredTechId);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubsectionHeader('PHASE 2: ARCHITECTURAL FLAGS & INSTRUCTION CHECKLIST'),
          const SizedBox(height: 10.0),

          Text('BIT WIDTH SELECTION', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Row(
            children: BitWidth.values.map((width) {
              final isSelected = _selectedBitWidth == width;
              final isUnlocked = width.isUnlocked;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBitWidth = width),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isUnlocked ? HTColors.primary.withValues(alpha: 0.15) : HTColors.error.withValues(alpha: 0.15))
                          : HTColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? (isUnlocked ? HTColors.primary : HTColors.error)
                            : HTColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        width.label,
                        style: HTTypography.badge.copyWith(
                          color: isUnlocked
                              ? (isSelected ? HTColors.primary : HTColors.textSecondary)
                              : HTColors.textMuted,
                          fontSize: 8.0,
                          decoration: isUnlocked ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (isBitWidthLocked) ...[
            const SizedBox(height: 6.0),
            _buildWarningMessage(
              '[!] BIT WIDTH LOCKED: REQUIRES R&D "${bitWidthTechNode.title.toUpperCase()}" NODE.',
              HTColors.error,
            ),
          ],
          const SizedBox(height: 14.0),

          // Checklist of capabilities
          Text('INSTRUCTION SET EXTENSIONS & CAPABILITIES', style: HTTypography.metricLabel),
          const SizedBox(height: 4.0),
          Container(
            decoration: HTDecorations.panelBox(),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width <= 600 ? 4.0 : 8.0),
            child: Column(
              children: [
                // MMX
                CheckboxListTile(
                  title: const Text('MMX Support', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                  subtitle: Text(
                    isMmxUnlocked ? '(+20% FLOPS performance, +10% capacitance)' : '[ LOCKED: REQUIRES INSTRUCTION PIPELINING R&D ]',
                    style: TextStyle(fontFamily: 'IBMPlexMono', color: isMmxUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                  ),
                  value: _hasMmx && isMmxUnlocked,
                  enabled: isMmxUnlocked,
                  activeColor: HTColors.primary,
                  checkColor: HTColors.background,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      _hasMmx = val ?? false;
                    });
                  },
                ),
                const Divider(color: HTColors.border, height: 1.0),
                // SSE
                CheckboxListTile(
                  title: const Text('SSE Vector Blocks', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                  subtitle: Text(
                    isSseUnlocked ? '(+40% FLOPS performance, +15% capacitance)' : '[ LOCKED: REQUIRES 32-BIT ARCHITECTURE R&D ]',
                    style: TextStyle(fontFamily: 'IBMPlexMono', color: isSseUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                  ),
                  value: _hasSse && isSseUnlocked,
                  enabled: isSseUnlocked,
                  activeColor: HTColors.primary,
                  checkColor: HTColors.background,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      _hasSse = val ?? false;
                    });
                  },
                ),
                const Divider(color: HTColors.border, height: 1.0),
                // CUSTOM ISA MATH PROFILES
                CheckboxListTile(
                  title: const Text('Custom ISA Math Profiles (RISC)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                  subtitle: Text(
                    isCustomIsaUnlocked ? '(+15% FLOPS performance, -10% capacitance optimization)' : '[ LOCKED: REQUIRES RISC ARCHITECTURE R&D ]',
                    style: TextStyle(fontFamily: 'IBMPlexMono', color: isCustomIsaUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                  ),
                  value: _hasCustomIsa && isCustomIsaUnlocked,
                  enabled: isCustomIsaUnlocked,
                  activeColor: HTColors.primary,
                  checkColor: HTColors.background,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      _hasCustomIsa = val ?? false;
                    });
                  },
                ),
                const Divider(color: HTColors.border, height: 1.0),
                // BASIC FLOAT COMPUTE POINT (FPU)
                CheckboxListTile(
                  title: const Text('Basic Float Compute Point (FPU)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                  subtitle: Text(
                    isFpuUnlocked ? '(+25% FLOPS performance, +5% capacitance)' : '[ LOCKED: REQUIRES MATH COPROCESSOR R&D ]',
                    style: TextStyle(fontFamily: 'IBMPlexMono', color: isFpuUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                  ),
                  value: _hasFpu && isFpuUnlocked,
                  enabled: isFpuUnlocked,
                  activeColor: HTColors.primary,
                  checkColor: HTColors.background,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      _hasFpu = val ?? false;
                    });
                  },
                ),
                const Divider(color: HTColors.border, height: 1.0),
                // FIXED-POINT VECTOR MATRIX (DSP)
                CheckboxListTile(
                  title: const Text('Fixed-Point Vector Matrix (DSP)', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 10)),
                  subtitle: Text(
                    isDspUnlocked ? '(+30% FLOPS performance, +12% capacitance)' : '[ LOCKED: REQUIRES DIGITAL SIGNAL PROCESSING R&D ]',
                    style: TextStyle(fontFamily: 'IBMPlexMono', color: isDspUnlocked ? HTColors.textSecondary : Colors.redAccent, fontSize: 8),
                  ),
                  value: _hasDsp && isDspUnlocked,
                  enabled: isDspUnlocked,
                  activeColor: HTColors.primary,
                  checkColor: HTColors.background,
                  dense: true,
                  onChanged: (val) {
                    setState(() {
                      _hasDsp = val ?? false;
                    });
                  },
                ),
              ],
            ),
          ),
          
          if (_selectedScope == DesignScope.coreUnit) ...[
            const SizedBox(height: 14.0),
            Text('ON-DIE CACHE ALLOCATION', style: HTTypography.metricLabel),
            const SizedBox(height: 4.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: HTColors.surface,
                border: Border.all(color: HTColors.primary.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<CacheAllocation>(
                  initialValue: _selectedCache,
                  dropdownColor: HTColors.surface,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 9),
                  items: CacheAllocation.values.map((cache) {
                    final isUnlocked = cache.requiredTechId == null || state.isNodeUnlocked(cache.requiredTechId!);
                    return DropdownMenuItem<CacheAllocation>(
                      value: cache,
                      child: Text(
                        isUnlocked ? cache.label : '[LOCKED] ${cache.label.toUpperCase()}',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          color: isUnlocked ? HTColors.textPrimary : HTColors.textMuted,
                          decoration: isUnlocked ? null : TextDecoration.lineThrough,
                          fontSize: 8.0,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (cache) {
                    if (cache != null) {
                      setState(() {
                        _selectedCache = cache;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // PHASE 3: Core Unit Parameters & Physical Tuning View
  Widget _buildPhase3Parameters(GameStateNotifier state) {
    final double maxFreqMhz = state.unlockedMaxFrequencyHz / 1e6;
    final double minFreqMhz = maxFreqMhz >= 1.0 ? 1.0 : (maxFreqMhz / 10).clamp(0.001, maxFreqMhz);

    double currentVal = _maxClockMhz;
    if (currentVal > maxFreqMhz) {
      currentVal = maxFreqMhz;
    }
    if (currentVal < minFreqMhz) {
      currentVal = minFreqMhz;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubsectionHeader('PHASE 3: CORE UNIT PARAMETERS & PHYSICAL TUNING'),
          const SizedBox(height: 10.0),

          // Slider 1: Max Clock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('TARGET MAX CLOCK FREQUENCY CAPACITY', style: HTTypography.metricLabel)),
              const SizedBox(width: 8.0),
              Text('${currentVal.toStringAsFixed(3)} MHz', style: HTTypography.badge.copyWith(color: HTColors.primary)),
            ],
          ),
          Slider(
            value: currentVal,
            min: minFreqMhz,
            max: state.researchDepartment.unlockedMaxFrequencyHz / 1e6,
            divisions: (maxFreqMhz - minFreqMhz) > 0.1 ? 400 : null,
            activeColor: HTColors.primary,
            inactiveColor: HTColors.border,
            onChanged: (val) {
              setState(() {
                _maxClockMhz = val;
              });
            },
          ),
          const SizedBox(height: 10.0),

          // Slider 2: Voltage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('TARGET BASELINE OPERATING VOLTAGE', style: HTTypography.metricLabel)),
              const SizedBox(width: 8.0),
              Text('${_operatingVoltageV.toStringAsFixed(2)} V', style: HTTypography.badge.copyWith(color: _operatingVoltageV > 3.6 ? Colors.orangeAccent : HTColors.success)),
            ],
          ),
          Slider(
            value: _operatingVoltageV,
            min: 0.5,
            max: 5.0,
            divisions: 90,
            activeColor: HTColors.primary,
            inactiveColor: HTColors.border,
            onChanged: (val) => setState(() => _operatingVoltageV = val),
          ),
          const SizedBox(height: 14.0),

          // Real-time CMOS Projections Display Card
          Container(
            decoration: HTDecorations.panelBox(),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width <= 600 ? 4.0 : 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('--- LIVE DYNAMIC CMOS SIMULATOR ---', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4.0),
                _buildDiagnosticLine('Silicon gate capacitance scales with target process node.'),
                _buildDiagnosticLine('Estimated Power dissipation is given by CMOS model: P = C * V^2 * f.'),
                if (_operatingVoltageV > 3.6)
                  _buildDiagnosticLine('WARNING: Over-voltage stress active! Structural silicon fatigue penalizes projected yield.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PHASE 4: Literal Product Carrier Assembly View
  Widget _buildPhase4Assembly(
    GameStateNotifier state,
    int year,
    double baseLitho,
    double floor,
    String? layoutGateWarning,
    bool isThirdConsecutive,
    double powerWatts,
    double finalClockMhz,
    double projectedYield,
    double projectedFlops,
    double maxLitho,
    double capFactor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth <= 600;
        final leftColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubsectionHeader('PHASE 4: LITERAL PRODUCT CARRIER ASSEMBLY'),
            const SizedBox(height: 8.0),

            Text('SELECT CHIP LAYOUT SOURCE >', style: HTTypography.metricLabel),
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: HTColors.surface,
                      border: Border.all(color: HTColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<CustomDieLayout?>(
                        initialValue: _selectedLayout,
                        dropdownColor: HTColors.surface,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 9),
                        items: [
                          const DropdownMenuItem<CustomDieLayout?>(
                            value: null,
                            child: Text('[ BLANK CANVAS ARCHETYPE ]'),
                          ),
                          ...state.playerVerifiedLayouts.map((layout) {
                            return DropdownMenuItem<CustomDieLayout?>(
                              value: layout,
                              child: SizedBox(
                                width: 250,
                                child: Text(
                                  '${layout.name} (FLOPS: ${layout.kiloFlops.toStringAsFixed(1)}k, COMPLEXITY: ${layout.gateComplexity})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 9.0),
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (layout) {
                          setState(() {
                            _selectedLayout = layout;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Casing dropdown
                  Text('PACKAGING CASING PROFILE', style: HTTypography.metricLabel),
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: HTColors.surface,
                      border: Border.all(color: HTColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<CasingType>(
                        initialValue: _selectedCasing,
                        dropdownColor: HTColors.surface,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 9),
                        items: CasingType.values.map((casing) {
                          final isUnlocked = casing.isUnlocked;
                          return DropdownMenuItem<CasingType>(
                            value: casing,
                            child: Text(
                              isUnlocked ? _getCasingDropdownLabel(casing) : '[LOCKED] ${casing.name.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                color: isUnlocked ? HTColors.textPrimary : HTColors.textMuted,
                                decoration: isUnlocked ? null : TextDecoration.lineThrough,
                                fontSize: 8.0,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (casing) {
                          if (casing != null) {
                            setState(() {
                              _selectedCasing = casing;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // IHS Material dropdown (Thermal Layer Selection)
                  Text('PHYSICAL THERMAL LAYER', style: HTTypography.metricLabel),
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: HTColors.surface,
                      border: Border.all(color: HTColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<IhsMaterial>(
                        initialValue: _selectedIhs,
                        dropdownColor: HTColors.surface,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 9),
                        items: IhsMaterial.values.map((ihs) {
                          final isUnlocked = ihs.isUnlocked;
                          return DropdownMenuItem<IhsMaterial>(
                            value: ihs,
                            child: Text(
                              isUnlocked ? _getIhsDropdownLabel(ihs) : '[LOCKED] ${ihs.label.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                color: isUnlocked ? HTColors.textPrimary : HTColors.textMuted,
                                decoration: isUnlocked ? null : TextDecoration.lineThrough,
                                fontSize: 8.0,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (ihs) {
                          if (ihs != null) {
                            setState(() {
                              _selectedIhs = ihs;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Supported Max Ext. DRAM Capacity Dropdown
                  Text('SUPPORTED MAX EXT. DRAM CAPACITY', style: HTTypography.metricLabel),
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: HTColors.surface,
                      border: Border.all(color: HTColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<ExtDramCapacity>(
                        initialValue: _selectedDram,
                        dropdownColor: HTColors.surface,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textPrimary, fontSize: 9),
                        items: ExtDramCapacity.values.map((dram) {
                          final isUnlocked = dram.requiredTechId == null || state.isNodeUnlocked(dram.requiredTechId!);
                          return DropdownMenuItem<ExtDramCapacity>(
                            value: dram,
                            child: Text(
                              isUnlocked ? dram.label : '[LOCKED] ${dram.label.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'IBMPlexMono',
                                color: isUnlocked ? HTColors.textPrimary : HTColors.textMuted,
                                decoration: isUnlocked ? null : TextDecoration.lineThrough,
                                fontSize: 8.0,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (dram) {
                          if (dram != null) {
                            setState(() {
                              _selectedDram = dram;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // Lithography Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('TARGET LITHOGRAPHY DENSITY', style: HTTypography.metricLabel)),
                      const SizedBox(width: 8.0),
                      Text('${_lithoOverrideVal.toStringAsFixed(3)} µm', style: HTTypography.badge.copyWith(color: HTColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _lithoOverrideVal,
                    min: floor,
                    max: maxLitho,
                    activeColor: HTColors.primary,
                    inactiveColor: HTColors.border,
                    onChanged: (val) => setState(() => _lithoOverrideVal = val),
                  ),
                  const SizedBox(height: 10.0),

                  // Derivative Refresh Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('INITIATE AS DERIVATIVE REFRESH', style: TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8.5, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isRefresh,
                        activeThumbColor: HTColors.primary,
                        activeTrackColor: HTColors.primary.withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() {
                            _isRefresh = val;
                            if (val) {
                              final finished = state.activeProductsRegistry.where((p) => p.isTapedOut).toList();
                              if (finished.isNotEmpty) {
                                _refreshedFromProject = finished.last;
                              }
                            } else {
                              _refreshedFromProject = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isRefresh && _refreshedFromProject != null) ...[
                    const SizedBox(height: 4.0),
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: HTColors.surface,
                        border: Border.all(color: HTColors.border),
                      ),
                      child: Text(
                        'REFRESH SOURCE BLUEPRINT: ${_refreshedFromProject!.projectName}',
                        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.primary, fontSize: 8.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
          ],
        );

        final rightColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubsectionHeader('REAL-TIME DIAGNOSTIC TELEMETRY'),
                    const SizedBox(height: 6.0),

                    Container(
                      decoration: HTDecorations.panelBox(),
                      padding: EdgeInsets.all(isMobile ? 3.0 : 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDiagnosticLine('NODE DENSITY LIMIT: ${floor.toStringAsFixed(3)} µm'),
                          _buildDiagnosticLine('FAB HARDWARE TYPE: ${_getFloorNodeName(state)}'),
                          _buildDiagnosticLine('CMOS CAPACITANCE: ${capFactor.toStringAsFixed(3)} fF'),
                          _buildDiagnosticLine('VOLTAGE BIAS: ${_operatingVoltageV.toStringAsFixed(2)} V'),
                          
                          // SCHEMA VALIDATION BLOCKS
                          if (layoutGateWarning != null) ...[
                            const SizedBox(height: 4.0),
                            _buildWarningMessage(layoutGateWarning, Colors.redAccent),
                          ],

                          if (isThirdConsecutive) ...[
                            const SizedBox(height: 4.0),
                            _buildWarningMessage(
                              '[WARN] ISA LEVERAGE CRITICAL: Legacy instruction set duplication detected. Microcode expansion introducing structural silicon waste (+20%).',
                              Colors.orangeAccent,
                            ),
                          ],

                          if (_selectedBitWidth == BitWidth.bit16 && year >= 1977 && year <= 1983) ...[
                            const SizedBox(height: 4.0),
                            _buildWarningMessage(
                              '[CRITICAL] ADDRESS SPACE CEILING REACHED: 16-bit execution models will hard-limit maximum addressable memory arrays within 24 game-months.',
                              Colors.cyanAccent,
                            ),
                          ],

                          if (_lithoOverrideVal < baseLitho) ...[
                            const SizedBox(height: 4.0),
                            _buildWarningMessage(
                              '[WARN] SUB-BASELINE LITHOGRAPHY: Yield degradation active. Pulled target below safe baseline node.',
                              Colors.orangeAccent,
                            ),
                          ],

                          if (_isRefresh) ...[
                            const SizedBox(height: 4.0),
                            _buildWarningMessage(
                              '[INFO] DERIVATIVE REFRESH: Tapeout cost reduced by 60% due to reusable design blueprints.',
                              HTColors.success,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // PERFORMANCE PROJECTIONS & BINNING CARD
                    _buildSubsectionHeader('PERFORMANCE PROJECTIONS & BINNING'),
                    const SizedBox(height: 6.0),

                    Builder(
                      builder: (context) {
                        final yieldAlert = projectedYield < 0.40;
                        final yieldColor = yieldAlert ? Colors.redAccent : HTColors.success;
                        return Container(
                          decoration: HTDecorations.panelBox(),
                          padding: EdgeInsets.all(isMobile ? 4.0 : 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMetricRow('EST. POWER DISSIPATION', '${powerWatts.toStringAsFixed(2)} W'),
                              const SizedBox(height: 4.0),
                              _buildMetricRow('TARGET BUS CLOCK SPEED', '${finalClockMhz.toStringAsFixed(1)} MHz'),
                              const SizedBox(height: 4.0),
                              _buildMetricRow(
                                'PROJECTED CLEAN-ROOM YIELD', 
                                '${(projectedYield * 100.0).toStringAsFixed(1)}%',
                                valueColor: yieldColor,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                                child: Divider(color: HTColors.border, height: 1.0),
                              ),
                              Text('ESTIMATED PERFORMANCE CAPABILITY', style: HTTypography.metricLabel.copyWith(fontSize: 8)),
                              const SizedBox(height: 2.0),
                              Text(
                                _formatFlops(projectedFlops),
                                style: TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  color: yieldAlert ? Colors.redAccent : HTColors.primary,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
        );

        if (isMobile) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftColumn,
                const SizedBox(height: 16.0),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: HTColors.border, width: 1.0)),
                  ),
                  padding: const EdgeInsets.only(top: 16.0),
                  child: rightColumn,
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: leftColumn,
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: HTColors.border, width: 1.0)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: rightColumn,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: HTColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          color: HTColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'IBMPlexMono',
        color: HTColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 8.5,
      ),
    );
  }

  Widget _buildDiagnosticLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '> $text',
        style: const TextStyle(fontFamily: 'IBMPlexMono', color: HTColors.textSecondary, fontSize: 8),
      ),
    );
  }

  Widget _buildWarningMessage(String message, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        message,
        style: TextStyle(fontFamily: 'IBMPlexMono', color: color, fontSize: 8.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: HTTypography.metricLabel.copyWith(fontSize: 8)),
        Text(value, style: HTTypography.badge.copyWith(color: valueColor ?? HTColors.textPrimary, fontSize: 8)),
      ],
    );
  }

  String _formatFlops(double flops) {
    if (flops < 1.0) {
      return '${(flops * 1000).toStringAsFixed(2)} FLOPS';
    } else if (flops < 1000.0) {
      return '${flops.toStringAsFixed(2)} KiloFLOPS';
    } else if (flops < 1000000.0) {
      return '${(flops / 1000.0).toStringAsFixed(2)} MegaFLOPS';
    } else if (flops < 1000000000.0) {
      return '${(flops / 1000000.0).toStringAsFixed(2)} GigaFLOPS';
    } else {
      return '${(flops / 1000000000.0).toStringAsFixed(2)} TeraFLOPS';
    }
  }
}
