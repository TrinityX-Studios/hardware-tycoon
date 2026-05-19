// ignore_for_file: constant_identifier_names

import 'research_node.dart';
import '../views/components/die_blueprint_data.dart';

enum ChipTarget {
  cpu,
  gpu,
  fpga,
}

enum LicensingModel {
  proprietary,
  ipLicensing,
}

enum DesignScope {
  architecture('ARCHITECTURE'),
  coreUnit('CORE UNIT'),
  productLiteral('PRODUCT LITERAL');

  const DesignScope(this.label);
  final String label;
}

enum CasingType {
  bareDie('BARE DIE', 'fab_bjt'),
  ceramicDIP('CERAMIC DIP', 'fab_bjt'),
  picc('PICC', 'fab_ttl'),
  seccCartridge('SECC CARTRIDGE', 'pkg_slot_cartridge'),
  PGA('PGA (PIN GRID ARRAY)', 'fab_cmos'),
  BGA('BGA (BALL GRID ARRAY)', 'arch_32bit'),
  LGA('LGA (LAND GRID ARRAY)', 'arch_64bit');

  const CasingType(this.label, this.requiredTechId);
  final String label;
  final String requiredTechId;

  bool get isUnlocked {
    if (requiredTechId == 'fab_bjt') return true;
    try {
      final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == requiredTechId);
      return node.progress >= 1.0;
    } catch (_) {
      return false;
    }
  }
}

enum BitWidth {
  bit4('4-BIT', 'fab_bjt'),
  bit8('8-BIT', 'fab_ttl'),
  bit16('16-BIT', 'arch_16bit'),
  bit32('32-BIT', 'arch_32bit'),
  bit64('64-BIT', 'arch_64bit');

  const BitWidth(this.label, this.requiredTechId);
  final String label;
  final String requiredTechId;

  bool get isUnlocked {
    if (requiredTechId == 'fab_bjt' || requiredTechId == 'fab_ttl') return true;
    try {
      final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == requiredTechId);
      return node.progress >= 1.0;
    } catch (_) {
      return false;
    }
  }
}

enum IhsMaterial {
  none('NONE', 'fab_bjt'),
  aluminum('ALUMINUM', 'pkg_ihs_aluminum'),
  copperLid('COPPER LID', 'pkg_copper_slug');

  const IhsMaterial(this.label, this.requiredTechId);
  final String label;
  final String requiredTechId;

  bool get isUnlocked {
    if (requiredTechId == 'fab_bjt') return true;
    try {
      final node = HistoricalTechTree.nodes.firstWhere((n) => n.id == requiredTechId);
      return node.progress >= 1.0;
    } catch (_) {
      return false;
    }
  }
}

enum CacheAllocation {
  none('NONE', 0.0, 1.0, 1.0, null),
  sram64b('64-BYTE DISCRETE SRAM', 64.0, 1.05, 1.08, 'cache_sram_discrete'),
  sram256b('256-BYTE DISCRETE SRAM', 256.0, 1.10, 1.18, 'cache_sram_discrete'),
  sram1kb('1KB DISCRETE SRAM', 1024.0, 1.18, 1.30, 'cache_sram_discrete'),
  l1_4kb('4KB INTEGRATED L1', 4096.0, 1.35, 1.45, 'cache_l1_integrated'),
  l1_16kb('16KB INTEGRATED L1', 16384.0, 1.50, 1.70, 'cache_l1_integrated'),
  l1_64kb('64KB INTEGRATED L1', 65536.0, 1.75, 2.10, 'cache_l1_integrated');

  const CacheAllocation(this.label, this.bytes, this.ipcMultiplier, this.powerMultiplier, this.requiredTechId);
  final String label;
  final double bytes;
  final double ipcMultiplier;
  final double powerMultiplier;
  final String? requiredTechId;
}

enum ExtDramCapacity {
  none('NONE', 0.0, null),
  dram4kb('4KB EXT DRAM', 4096.0, 'dram_early_cell'),
  dram16kb('16KB EXT DRAM', 16384.0, 'dram_early_cell'),
  dram64kb('64KB EXT DRAM', 65536.0, 'dram_early_cell'),
  dram1mb('1MB SYNC DRAM', 1048576.0, 'dram_synchronous'),
  dram4mb('4MB SYNC DRAM', 4194304.0, 'dram_synchronous'),
  dram16mb('16MB SYNC DRAM', 16777216.0, 'dram_synchronous');

  const ExtDramCapacity(this.label, this.bytes, this.requiredTechId);
  final String label;
  final double bytes;
  final String? requiredTechId;
}

class CustomDieLayout {
  final String name;
  final List<PlacedComponent> components;
  final List<LineTrace> traces;
  final double kiloFlops;
  final int gateComplexity;
  final bool pathVerified;

  const CustomDieLayout({
    required this.name,
    required this.components,
    required this.traces,
    required this.kiloFlops,
    required this.gateComplexity,
    required this.pathVerified,
  });
}

class SiliconProject {
  final String projectName;
  final ChipTarget type;
  final LicensingModel paradigm;
  final DesignScope scope;
  final CasingType casing;
  final BitWidth bitWidth;
  final double targetLithography;
  final bool isRefresh;
  final String? refreshedFromProjectName;
  final double technicalDebtFactor;
  final double projectedFlops;
  final double powerWatts;
  final double clockSpeedMhz;
  final double projectedYieldPct;
  final double tapeoutCostTicks;
  final bool isTapedOut;
  final IhsMaterial ihs;
  final String? customLayoutName;
  final String? parentArchitectureName;
  final bool hasFpu;
  final bool hasMmx;
  final bool hasSse;
  final bool hasDsp;
  final bool hasCustomIsa;
  final CacheAllocation cacheAllocation;
  final ExtDramCapacity maxExtDramCapacity;

  SiliconProject({
    required this.projectName,
    required this.type,
    required this.paradigm,
    required this.scope,
    required this.casing,
    required this.bitWidth,
    required this.targetLithography,
    required this.isRefresh,
    this.refreshedFromProjectName,
    required this.technicalDebtFactor,
    required this.projectedFlops,
    required this.powerWatts,
    required this.clockSpeedMhz,
    required this.projectedYieldPct,
    required this.tapeoutCostTicks,
    this.isTapedOut = false,
    this.ihs = IhsMaterial.none,
    this.customLayoutName,
    this.parentArchitectureName,
    this.hasFpu = false,
    this.hasMmx = false,
    this.hasSse = false,
    this.hasDsp = false,
    this.hasCustomIsa = false,
    this.cacheAllocation = CacheAllocation.none,
    this.maxExtDramCapacity = ExtDramCapacity.none,
  }) {
    if (type == ChipTarget.fpga) {
      final fpgaNode = HistoricalTechTree.nodes.firstWhere(
        (n) => n.id == 'arch_fpga',
        orElse: () => throw StateError('FPGA tech node not found in registry.'),
      );
      if (!fpgaNode.isUnlocked) {
        throw StateError('FPGA architecture research node remains locked in R&D database graph.');
      }
    }
  }
}
