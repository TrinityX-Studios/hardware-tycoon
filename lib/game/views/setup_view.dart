/// Hardware Tycoon — New Game Setup View
///
/// Responsive landscape configuration dashboard for initiating a new corporation.
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import '../models/country_model.dart';
import '../data/countries/united_states.dart';
import '../data/countries/canada.dart';
import '../data/countries/united_kingdom.dart';
import '../data/countries/france.dart';
import '../data/countries/philippines.dart';
import '../data/countries/japan.dart';
import '../data/countries/malaysia.dart';
import '../data/countries/india.dart';

class SetupView extends StatefulWidget {
  final AppStateMachine appState;

  const SetupView({super.key, required this.appState});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final TextEditingController _corpNameController = TextEditingController(text: 'Acme Silicon');
  final TextEditingController _ceoNameController = TextEditingController(text: 'E. Player');
  
  CountryModel? _selectedCountry;
  CountryModel? _hoveredCountry;

  static const List<CountryModel> _availableCountries = [
    UnitedStates(),
    Canada(),
    UnitedKingdom(),
    France(),
    Japan(),
    Philippines(),
    Malaysia(),
    India(),
  ];

  @override
  void initState() {
    super.initState();
    // Default select USA
    _selectedCountry = _availableCountries.firstWhere((c) => c.id == 'usa');
  }

  @override
  void dispose() {
    _corpNameController.dispose();
    _ceoNameController.dispose();
    super.dispose();
  }

  void _onBootSimulation() {
    if (_selectedCountry == null) return;
    
    // In a full implementation, we'd pass the names and chosen country to the config.
    // For now, we just pass the selected country's FinancialConfig.
    widget.appState.startGame(_selectedCountry!.baseConfig);
  }

  @override
  Widget build(BuildContext context) {
    final activeDisplayCountry = _hoveredCountry ?? _selectedCountry;

    return Scaffold(
      backgroundColor: HTColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: Forms
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CORPORATE REGISTRY', style: HTTypography.panelHeader),
                          const SizedBox(height: 24.0),
                          
                          _buildInputField('CORPORATION NAME', _corpNameController),
                          const SizedBox(height: 24.0),
                          _buildInputField('CEO DESIGNATION', _ceoNameController),
                          
                          const Spacer(),
                          
                          // Boot Button
                          SizedBox(
                            width: double.infinity,
                            child: _BootButton(
                              onTap: _onBootSimulation,
                              isEnabled: _selectedCountry != null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(width: 1.0, color: HTColors.border),
                  
                  // Center Column: Country Grid
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GLOBAL HEADQUARTERS SITE', style: HTTypography.panelHeader),
                          const SizedBox(height: 16.0),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 12.0,
                                mainAxisSpacing: 12.0,
                              ),
                              itemCount: _availableCountries.length,
                              itemBuilder: (context, index) {
                                final country = _availableCountries[index];
                                final isSelected = country.id == _selectedCountry?.id;
                                
                                return MouseRegion(
                                  onEnter: (_) => setState(() => _hoveredCountry = country),
                                  onExit: (_) => setState(() => _hoveredCountry = null),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCountry = country),
                                    child: _CountryCard(
                                      country: country,
                                      isSelected: isSelected,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Divider
                  Container(width: 1.0, color: HTColors.border),
                  
                  // Right Column: Active Modifiers
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: HTColors.surface,
                      padding: const EdgeInsets.all(24.0),
                      child: activeDisplayCountry == null 
                        ? const Center(child: Text('SELECT A SITE'))
                        : _buildModifierPanel(activeDisplayCountry),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HTColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: HTColors.primary,
            onPressed: () => widget.appState.goToMainMenu(),
          ),
          const SizedBox(width: 16.0),
          Text('INITIALIZATION SEQUENCE', style: HTTypography.statMedium),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: HTTypography.metricLabel),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          style: HTTypography.body.copyWith(fontSize: 16.0),
          decoration: InputDecoration(
            filled: true,
            fillColor: HTColors.surface,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: HTColors.border),
              borderRadius: BorderRadius.circular(4.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: HTColors.primary),
              borderRadius: BorderRadius.circular(4.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          ),
        ),
      ],
    );
  }
  
  Widget _buildModifierPanel(CountryModel country) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REGIONAL ANALYSIS', style: HTTypography.panelHeader),
        const SizedBox(height: 24.0),
        
        Row(
          children: [
            Icon(country.icon, size: 32.0, color: HTColors.textPrimary),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(country.name.toUpperCase(), style: HTTypography.statMedium),
                  Text(country.region.toUpperCase(), style: HTTypography.metricLabel),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32.0),
        
        Text('STARTING CAPITAL', style: HTTypography.metricLabel),
        const SizedBox(height: 4.0),
        Text('\$${(country.baseConfig.startingLiquidity / 1000).toStringAsFixed(0)}K', style: HTTypography.metricValue.copyWith(color: HTColors.success, fontSize: 20.0)),
        
        const SizedBox(height: 24.0),
        
        Text('ENVIRONMENTAL MODIFIERS', style: HTTypography.metricLabel),
        const SizedBox(height: 12.0),
        
        ...country.modifiers.map((mod) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _ModifierRow(modifier: mod),
        )),
      ],
    );
  }
}

class _CountryCard extends StatelessWidget {
  final CountryModel country;
  final bool isSelected;

  const _CountryCard({required this.country, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isSelected ? HTColors.primary.withValues(alpha: 0.1) : HTColors.surface,
        border: Border.all(
          color: isSelected ? HTColors.primary : HTColors.border,
          width: isSelected ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(country.icon, size: 20.0, color: isSelected ? HTColors.primary : HTColors.textSecondary),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  country.name,
                  style: HTTypography.listTitle.copyWith(
                    color: isSelected ? HTColors.primary : HTColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(country.region, style: HTTypography.bodySmall),
        ],
      ),
    );
  }
}

class _ModifierRow extends StatelessWidget {
  final CountryModifier modifier;

  const _ModifierRow({required this.modifier});

  @override
  Widget build(BuildContext context) {
    final color = modifier.isPositive ? HTColors.success : HTColors.error;
    final valueStr = modifier.value > 1.0 
      ? '+${((modifier.value - 1.0) * 100).round()}%'
      : '-${((1.0 - modifier.value) * 100).round()}%';
      
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          modifier.isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
          size: 14.0,
          color: color,
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(modifier.label, style: HTTypography.listTitle),
                  const Spacer(),
                  Text(valueStr, style: HTTypography.badge.copyWith(color: color)),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(modifier.description, style: HTTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _BootButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isEnabled;

  const _BootButton({required this.onTap, this.isEnabled = true});

  @override
  State<_BootButton> createState() => _BootButtonState();
}

class _BootButtonState extends State<_BootButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          decoration: BoxDecoration(
            color: !widget.isEnabled 
                ? HTColors.surfaceVariant
                : _isHovered ? HTColors.primary : HTColors.primary.withValues(alpha: 0.15),
            border: Border.all(
              color: !widget.isEnabled ? HTColors.border : HTColors.primary,
            ),
            borderRadius: BorderRadius.circular(4.0),
            boxShadow: _isHovered && widget.isEnabled
                ? [const BoxShadow(color: HTColors.primaryGlow, blurRadius: 10.0)]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: !widget.isEnabled 
                      ? HTColors.textMuted
                      : _isHovered ? HTColors.surface : HTColors.primary,
                  size: 20.0,
                ),
                const SizedBox(width: 12.0),
                Text(
                  'BOOT SIMULATION',
                  style: HTTypography.statMedium.copyWith(
                    color: !widget.isEnabled 
                        ? HTColors.textMuted
                        : _isHovered ? HTColors.surface : HTColors.primary,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
