/// Hardware Tycoon — UnifiedControlDashboard
///
/// Tabbed panel managing business operations. Uses a vertical icon tab bar
/// on the left edge with content area to the right. Three tabs:
/// R&D Lab, Workforce Router, Foundry Operations.
library;

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'panels/rnd_lab_panel.dart';
import 'panels/workforce_router_panel.dart';
import 'panels/foundry_ops_panel.dart';

class UnifiedControlDashboard extends StatefulWidget {
  const UnifiedControlDashboard({super.key});

  @override
  State<UnifiedControlDashboard> createState() =>
      _UnifiedControlDashboardState();
}

class _UnifiedControlDashboardState extends State<UnifiedControlDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _TabDef(icon: Icons.science, label: 'R&D LAB'),
    _TabDef(icon: Icons.people, label: 'WORKFORCE'),
    _TabDef(icon: Icons.precision_manufacturing, label: 'FOUNDRY'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: HTDecorations.panelBox(),
      child: Row(
        children: [
          // Vertical tab rail
          _VerticalTabRail(
            controller: _tabController,
            tabs: _tabs,
          ),

          // Separator
          Container(width: 1.0, color: HTColors.border),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                RndLabPanel(),
                WorkforceRouterPanel(),
                FoundryOpsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab Definition
// ---------------------------------------------------------------------------

class _TabDef {
  final IconData icon;
  final String label;

  const _TabDef({required this.icon, required this.label});
}

// ---------------------------------------------------------------------------
// Vertical Tab Rail
// ---------------------------------------------------------------------------

class _VerticalTabRail extends StatelessWidget {
  final TabController controller;
  final List<_TabDef> tabs;

  const _VerticalTabRail({
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.0,
      color: HTColors.background,
      child: Column(
        children: [
          const SizedBox(height: 4.0),
          for (int i = 0; i < tabs.length; i++)
            _VerticalTab(
              tab: tabs[i],
              isActive: controller.index == i,
              onTap: () => controller.animateTo(i),
            ),
        ],
      ),
    );
  }
}

class _VerticalTab extends StatefulWidget {
  final _TabDef tab;
  final bool isActive;
  final VoidCallback onTap;

  const _VerticalTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_VerticalTab> createState() => _VerticalTabState();
}

class _VerticalTabState extends State<_VerticalTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56.0,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: widget.isActive
                ? HTColors.primaryGlow
                : _isHovered
                    ? HTColors.surfaceVariant
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isActive ? HTColors.primary : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.tab.icon,
                size: 18.0,
                color: widget.isActive
                    ? HTColors.primary
                    : _isHovered
                        ? HTColors.textSecondary
                        : HTColors.textMuted,
              ),
              const SizedBox(height: 4.0),
              Text(
                widget.tab.label,
                style: widget.isActive
                    ? HTTypography.tabLabelActive.copyWith(fontSize: 8.0)
                    : HTTypography.tabLabel.copyWith(fontSize: 8.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
