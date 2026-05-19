/// Hardware Tycoon — Research Node Model
library;



enum ResearchBranch {
  fabrication,
  architecture,
  software,
}

class ResearchNode {
  final String id;
  final String title;
  final String description;
  final ResearchBranch branch;
  final int yearEra;
  final int researchCostTicks;
  final List<String> prerequisiteIds;
  final String trackId;
  
  bool isUnlocked;
  double progress; // 0.0 to 1.0

  int get year => yearEra;
  int get historicalYear => yearEra;

  final String historicalLore;
  final List<String> gameModifiers;

  ResearchNode({
    required this.id,
    required this.title,
    required this.description,
    required this.branch,
    required this.yearEra,
    required this.researchCostTicks,
    this.prerequisiteIds = const [],
    this.isUnlocked = false,
    this.progress = 0.0,
    this.historicalLore = '',
    this.gameModifiers = const [],
    this.trackId = 'FAB',
  });

  /// Row lane index for horizontal epoch grid layout.
  static int trackRow(String track) {
    switch (track) {
      case 'FAB': return 0;
      case 'LOGIC': return 1;
      case 'ARCH': return 2;
      case 'PKG': return 3;
      case 'SOFT': return 4;
      default: return 0;
    }
  }

  /// Decade era labels for background grid markers.
  static const Map<int, String> eraLabels = {
    1960: 'SOLID STATE ERA',
    1970: 'PLANAR PROCESS ERA',
    1980: 'VLSI SCALING ERA',
    1990: 'DEEP SUB-MICRON ERA',
    2000: 'NANOMETER ERA',
    2010: 'FINFET ERA',
    2020: 'CHIPLET ERA',
    2030: 'ANGSTROM ERA',
  };
}

class HistoricalTechTree {
  static final List<ResearchNode> nodes = [
    // 1960s - Discrete & Early ICs
    ResearchNode(
      id: 'pkg_ceramic_dip',
      title: 'Ceramic Dual In-line Package',
      description: 'Gold wire bonded hermetic ceramic casing.',
      branch: ResearchBranch.fabrication,
      yearEra: 1960,
      researchCostTicks: 50,
      isUnlocked: true,
      progress: 1.0,
      trackId: 'PKG',
      historicalLore: 'First patented in 1965 by Fairchild Semiconductor, the Dual In-line Package (DIP) revolutionized electronics by providing standard pin spacing compatible with standard PCB grids, utilizing gold wires bonded to a hermetic ceramic block for superior ruggedness.',
      gameModifiers: const [
        'Unlocks baseline integrated circuit DIP casing choices.',
        'Extends standard electrical terminal layout limits.'
      ],
    ),
    ResearchNode(
      id: 'pkg_ihs_aluminum',
      title: 'Anodized Aluminum IHS',
      description: 'Metal heat spreader capping to improve thermal capabilities.',
      branch: ResearchBranch.fabrication,
      yearEra: 1970,
      researchCostTicks: 200,
      prerequisiteIds: ['pkg_ceramic_dip'],
      trackId: 'PKG',
      historicalLore: 'As transistor density ramped up during the 1970s, thermal concentration threatened system stability. Anodized aluminum lids acted as planar heat pipes, transferring energy away from fragile die junctions.',
      gameModifiers: const [
        '+15% Est. Clock Speed Tolerance (Thermal Protection)',
        '-15% Est. Power Dissipation (Thermal Efficiency)',
        '+5% Yield Cushion (Buffers Aggressive Lithography Override Penalties)'
      ],
    ),
    ResearchNode(
      id: 'pkg_slot_cartridge',
      title: 'Single-Edge Contact Cartridge',
      description: 'Securing off-die processor cards with direct structural slot insertion.',
      branch: ResearchBranch.fabrication,
      yearEra: 1997,
      researchCostTicks: 280,
      prerequisiteIds: ['pkg_ihs_aluminum'],
      trackId: 'PKG',
      historicalLore: 'Employed by Intel in 1997 for the Pentium II processor, Slot 1 cartridges housed the processor core alongside off-die L2 cache SRAM chips directly on a structural daughterboard, bypassing motherboard socket yield limits.',
      gameModifiers: const [
        'Unlocks the Slot-1 SECC Cartridge form factor choice.',
        '+20% Total Silicon Flops Performance Scaling (Off-Die Bus Efficiency)'
      ],
    ),
    ResearchNode(
      id: 'pkg_copper_slug',
      title: 'Nickel-Plated Copper IHS',
      description: 'Ultra-low thermal impedance metal interface lid.',
      branch: ResearchBranch.fabrication,
      yearEra: 2000,
      researchCostTicks: 340,
      prerequisiteIds: ['pkg_ihs_aluminum'],
      trackId: 'PKG',
      historicalLore: 'By the turn of the millennium, processors crossed the 100-watt power ceiling. Pure nickel-plated copper lids provided the ultra-low thermal resistance required to mate high-power dies with aggressive cooling blocks.',
      gameModifiers: const [
        '+35% Est. Clock Speed Tolerance (Thermal Performance)',
        '-30% Est. Power Dissipation (Extreme Cooling Capability)',
        '+12% Yield Cushion (Defends Lithography Aggressive Override Penalties)'
      ],
    ),
    ResearchNode(
      id: 'fab_bjt',
      title: 'Bipolar Junction Transistors',
      description: 'Foundational discrete switching component.',
      branch: ResearchBranch.fabrication,
      yearEra: 1960,
      researchCostTicks: 100,
      isUnlocked: true, // Starting tech
      progress: 1.0,
      historicalLore: 'Invented at Bell Labs in 1947 by Shockley, Bardeen, and Brattain, the BJT ushered in the solid-state electronic era, replacing high-latency, power-hungry vacuum tube systems with discrete active switches.',
      gameModifiers: const [
        'Unlocks baseline Bipolar Junction Transistor lithography floor (25 µm).',
        'Estensively establishes electrical gate current logic switching.'
      ],
    ),
    ResearchNode(
      id: 'fab_crystallization',
      title: 'Silicon Crystallization',
      description: 'Purification of raw silica into crystal ingots.',
      branch: ResearchBranch.fabrication,
      yearEra: 1960,
      researchCostTicks: 50,
      isUnlocked: true,
      progress: 1.0,
    ),
    ResearchNode(
      id: 'fab_doping',
      title: 'Silicon Doping',
      description: 'Introduction of impurities to modulate conductivity.',
      branch: ResearchBranch.fabrication,
      yearEra: 1960,
      researchCostTicks: 50,
      isUnlocked: true,
      progress: 1.0,
    ),
    ResearchNode(
      id: 'fab_photolithography',
      title: 'Silicon Photolithography',
      description: 'Using light mask alignment to transfer geometric patterns.',
      branch: ResearchBranch.fabrication,
      yearEra: 1960,
      researchCostTicks: 50,
      isUnlocked: true,
      progress: 1.0,
    ),
    ResearchNode(
      id: 'fab_float_zone',
      title: 'Float-Zone Refining',
      description: 'Highly pure crystal growth method, unlocking larger wafer surface base sizes.',
      branch: ResearchBranch.fabrication,
      yearEra: 1961,
      researchCostTicks: 180,
      prerequisiteIds: ['fab_crystallization'],
    ),
    ResearchNode(
      id: 'fab_phosphorus',
      title: 'Phosphorus N-Type Infusion',
      description: 'Introduction of Phosphorus, required to advance toward CMOS architecture branches.',
      branch: ResearchBranch.fabrication,
      yearEra: 1961,
      researchCostTicks: 140,
      prerequisiteIds: ['fab_doping'],
    ),
    ResearchNode(
      id: 'opt_proximity',
      title: 'Proximity Mask Printing',
      description: 'Non-contact photolithography, safely dropping lithography boundaries to 10 micrometers.',
      branch: ResearchBranch.fabrication,
      yearEra: 1963,
      researchCostTicks: 220,
      prerequisiteIds: ['fab_photolithography'],
    ),
    ResearchNode(
      id: 'opt_projection',
      title: 'Projection Optics Alignment',
      description: 'Advanced lens alignment systems, dropping lithography boundaries to 3 micrometers.',
      branch: ResearchBranch.fabrication,
      yearEra: 1965,
      researchCostTicks: 350,
      prerequisiteIds: ['opt_proximity'],
    ),
    ResearchNode(
      id: 'arch_alu',
      title: 'Discrete ALU',
      description: 'Arithmetic Logic Unit using basic logic gates.',
      branch: ResearchBranch.architecture,
      yearEra: 1960,
      researchCostTicks: 150,
      prerequisiteIds: ['fab_bjt'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'fab_ttl',
      title: 'Transistor-Transistor Logic (TTL)',
      description: 'Integrated circuits using bipolar transistors.',
      branch: ResearchBranch.fabrication,
      yearEra: 1962,
      researchCostTicks: 250,
      prerequisiteIds: ['fab_bjt'],
    ),
    ResearchNode(
      id: 'cache_sram_discrete',
      title: 'Discrete SRAM Cache',
      description: 'Enables 64-byte to 1KB discrete SRAM caching selection blocks.',
      branch: ResearchBranch.architecture,
      yearEra: 1965,
      researchCostTicks: 250,
      prerequisiteIds: ['arch_alu'],
      trackId: 'LOGIC',
    ),
    
    // 1970s - The Microprocessor & MOS
    ResearchNode(
      id: 'fab_mosfet',
      title: 'MOSFET Fabrication',
      description: 'Metal-Oxide-Semiconductor Field-Effect Transistor.',
      branch: ResearchBranch.fabrication,
      yearEra: 1970,
      researchCostTicks: 400,
      prerequisiteIds: ['fab_ttl'],
    ),
    ResearchNode(
      id: 'dram_early_cell',
      title: 'Dynamic RAM Controllers',
      description: 'Introduces integrated dynamic system memory controllers.',
      branch: ResearchBranch.fabrication,
      yearEra: 1970,
      researchCostTicks: 350,
      prerequisiteIds: ['fab_mosfet'],
      trackId: 'FAB',
    ),
    ResearchNode(
      id: 'logic_rtl',
      title: 'Resistor-Transistor Logic',
      description: 'Low development cost, but introduces thermal/noise sensitivity modifiers.',
      branch: ResearchBranch.fabrication,
      yearEra: 1970,
      researchCostTicks: 100,
      prerequisiteIds: ['fab_mosfet'],
      trackId: 'LOGIC',
    ),
    ResearchNode(
      id: 'logic_dtl',
      title: 'Diode-Transistor Logic',
      description: 'Diode-transistor configurations, improving system gate fan-in counts.',
      branch: ResearchBranch.fabrication,
      yearEra: 1971,
      researchCostTicks: 150,
      prerequisiteIds: ['logic_rtl'],
      trackId: 'LOGIC',
    ),
    ResearchNode(
      id: 'arch_central_bus',
      title: 'Central Interconnect Bus',
      description: 'High-speed shared signal channel architecture.',
      branch: ResearchBranch.architecture,
      yearEra: 1970,
      researchCostTicks: 450,
      prerequisiteIds: ['fab_mosfet'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'lithography_fine_line',
      title: 'Fine-Line Lithography',
      description: 'Advanced projection mask scaling, expanding the layout boundaries.',
      branch: ResearchBranch.fabrication,
      yearEra: 1972,
      researchCostTicks: 500,
      prerequisiteIds: ['fab_mosfet'],
    ),
    ResearchNode(
      id: 'arch_8bit',
      title: '8-bit Microprocessor',
      description: 'Single-chip CPU with 8-bit registers.',
      branch: ResearchBranch.architecture,
      yearEra: 1974,
      researchCostTicks: 600,
      prerequisiteIds: ['fab_mosfet', 'arch_alu'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'soft_asm',
      title: 'Macro Assembler',
      description: 'Low-level programming language support.',
      branch: ResearchBranch.software,
      yearEra: 1974,
      researchCostTicks: 300,
      prerequisiteIds: ['arch_8bit'],
      trackId: 'SOFT',
    ),
    
    // 1980s - 16/32-bit & CISC vs RISC
    ResearchNode(
      id: 'fab_cmos',
      title: 'CMOS Process',
      description: 'Complementary MOS for lower power consumption.',
      branch: ResearchBranch.fabrication,
      yearEra: 1980,
      researchCostTicks: 800,
      prerequisiteIds: ['fab_mosfet'],
    ),
    ResearchNode(
      id: 'arch_16bit',
      title: '16-bit Architecture',
      description: 'Wider registers and larger address space.',
      branch: ResearchBranch.architecture,
      yearEra: 1980,
      researchCostTicks: 900,
      prerequisiteIds: ['arch_8bit', 'fab_cmos'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'math_coprocessor',
      title: 'Math Coprocessor',
      description: 'Dedicated floating point computation unit (FPU).',
      branch: ResearchBranch.architecture,
      yearEra: 1980,
      researchCostTicks: 700,
      prerequisiteIds: ['arch_8bit'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'digital_signal_processing',
      title: 'Digital Signal Processing',
      description: 'Dedicated fixed-point vector matrix calculation unit (DSP).',
      branch: ResearchBranch.architecture,
      yearEra: 1982,
      researchCostTicks: 850,
      prerequisiteIds: ['math_coprocessor'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'arch_cisc',
      title: 'CISC ISA',
      description: 'Complex Instruction Set Computer paradigms.',
      branch: ResearchBranch.architecture,
      yearEra: 1982,
      researchCostTicks: 1000,
      prerequisiteIds: ['arch_16bit'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'arch_risc',
      title: 'RISC ISA',
      description: 'Reduced Instruction Set Computer paradigms.',
      branch: ResearchBranch.architecture,
      yearEra: 1985,
      researchCostTicks: 1000,
      prerequisiteIds: ['arch_16bit'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'arch_fpga',
      title: 'Field Programmable Gate Array (FPGA)',
      description: 'Reconfigurable silicon architecture.',
      branch: ResearchBranch.architecture,
      yearEra: 1985,
      researchCostTicks: 1200,
      prerequisiteIds: ['arch_16bit'],
      trackId: 'ARCH',
    ),
    
    // 1990s - The Pipeline & 32-bit
    ResearchNode(
      id: 'arch_32bit',
      title: '32-bit Architecture',
      description: '4GB addressable memory limit reached.',
      branch: ResearchBranch.architecture,
      yearEra: 1990,
      researchCostTicks: 1500,
      prerequisiteIds: ['arch_cisc'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'arch_pipeline',
      title: 'Instruction Pipelining',
      description: 'Overlap execution of multiple instructions.',
      branch: ResearchBranch.architecture,
      yearEra: 1992,
      researchCostTicks: 1200,
      prerequisiteIds: ['arch_32bit', 'arch_risc'], // Needs RISC or 32-bit concept
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'soft_os',
      title: 'Graphical OS Support',
      description: 'Hardware hooks for multitasking graphical operating systems.',
      branch: ResearchBranch.software,
      yearEra: 1993,
      researchCostTicks: 1000,
      prerequisiteIds: ['arch_32bit'],
      trackId: 'SOFT',
    ),
    ResearchNode(
      id: 'cache_l1_integrated',
      title: 'Integrated L1 Cache',
      description: 'Drastically scales Core Unit base IPC performance calculations.',
      branch: ResearchBranch.architecture,
      yearEra: 1989,
      researchCostTicks: 1400,
      prerequisiteIds: ['arch_cisc', 'cache_sram_discrete'],
      trackId: 'LOGIC',
    ),
    ResearchNode(
      id: 'dram_synchronous',
      title: 'Synchronous DRAM',
      description: 'Removes product tapeout memory bus bottleneck.',
      branch: ResearchBranch.fabrication,
      yearEra: 1993,
      researchCostTicks: 1100,
      prerequisiteIds: ['dram_early_cell'],
      trackId: 'FAB',
    ),
    
    // 2000s - 64-bit & Multi-core
    ResearchNode(
      id: 'arch_64bit',
      title: '64-bit Architecture (amd64)',
      description: 'Breaking the 4GB RAM barrier.',
      branch: ResearchBranch.architecture,
      yearEra: 2003,
      researchCostTicks: 2500,
      prerequisiteIds: ['arch_32bit'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'arch_multicore',
      title: 'Multi-Core Processing',
      description: 'Multiple execution cores on a single die.',
      branch: ResearchBranch.architecture,
      yearEra: 2005,
      researchCostTicks: 3000,
      prerequisiteIds: ['arch_64bit', 'arch_pipeline'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'fab_euv_early',
      title: 'Early EUV Lithography',
      description: 'Extreme ultraviolet lithography prototypes.',
      branch: ResearchBranch.fabrication,
      yearEra: 2008,
      researchCostTicks: 4000,
      prerequisiteIds: ['fab_cmos'],
    ),
    
    // 2020s-2038 - The Epoch Crisis
    ResearchNode(
      id: 'arch_chiplet',
      title: 'Chiplet Interconnects',
      description: 'Advanced packaging of modular dies.',
      branch: ResearchBranch.architecture,
      yearEra: 2022,
      researchCostTicks: 5000,
      prerequisiteIds: ['arch_multicore'],
      trackId: 'ARCH',
    ),
    ResearchNode(
      id: 'soft_y2038',
      title: 'Y2038 Compliance',
      description: '64-bit time_t hardware acceleration to prevent epoch overflow.',
      branch: ResearchBranch.software,
      yearEra: 2030,
      researchCostTicks: 8000,
      prerequisiteIds: ['arch_64bit', 'soft_os'],
      trackId: 'SOFT',
    ),
    ResearchNode(
      id: 'fab_angstrom',
      title: 'Angstrom-Era Fabrication',
      description: 'Sub-nanometer gate-all-around transistors.',
      branch: ResearchBranch.fabrication,
      yearEra: 2035,
      researchCostTicks: 10000,
      prerequisiteIds: ['fab_euv_early', 'arch_chiplet'],
    ),
  ];
}
