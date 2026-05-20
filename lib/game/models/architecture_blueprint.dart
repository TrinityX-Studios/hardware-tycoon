class IsaExtension {
  final String id;
  final String name;
  final String description;
  final String tradeOffProfile;
  final bool isDefault;
  final bool isInteractive;
  final String? requiredTechId;

  const IsaExtension({
    required this.id,
    required this.name,
    required this.description,
    required this.tradeOffProfile,
    this.isDefault = false,
    this.isInteractive = true,
    this.requiredTechId,
  });
}

class ArchitectureBlueprint {
  final Map<String, bool> enabledExtensions;

  const ArchitectureBlueprint({
    required this.enabledExtensions,
  });

  bool isEnabled(String id) => enabledExtensions[id] ?? false;
}

class HistoricalIsaRegistry {
  static const List<IsaExtension> extensions = [
    IsaExtension(
      id: 'basic_alu',
      name: 'Basic Integer ALU',
      description: 'Add, Subtract, Bitwise AND/OR/XOR operations.',
      tradeOffProfile: 'Baseline execution logic (Always Enabled).',
      isDefault: true,
      isInteractive: false,
    ),
    IsaExtension(
      id: 'hardware_mul_div',
      name: 'Hardware Multiply/Divide',
      description: 'Adds multiplication/division hardware logic in silicon.',
      tradeOffProfile: '+12% Die Area, increases base performance.',
      isDefault: false,
    ),
    IsaExtension(
      id: 'bcd_math',
      name: 'Binary-Coded Decimal (BCD) Math',
      description: 'Module for processing exact decimal math for banking/enterprise.',
      tradeOffProfile: '+8% Die Area, unlocks commercial financial contracts.',
      isDefault: false,
    ),
    IsaExtension(
      id: 'cisc_layout',
      name: 'Microcoded CISC Layout',
      description: 'Multi-cycle complex instruction decoder natively implemented.',
      tradeOffProfile: '+15% Die Area, +20% Thermal power draw, +25% performance edge.',
      isDefault: false,
    ),
    IsaExtension(
      id: 'vliw_layout',
      name: 'Explicit Parallelism / Early VLIW Alternative',
      description: 'Complex instruction scheduling/decoding offloaded entirely to software compilers.',
      tradeOffProfile: 'Physical silicon runs cold/efficient (0W power overhead), but adds a recurring financial R&D Compiler staff upkeep cost (\$50/day).',
      isDefault: false,
    ),
  ];
}
