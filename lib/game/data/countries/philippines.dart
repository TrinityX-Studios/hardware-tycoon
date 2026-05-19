import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class Philippines extends CountryModel {
  const Philippines() : super(
    id: 'phl',
    name: 'Philippines',
    region: 'Southeast Asia',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'Manual Assembly Base', description: 'Extremely cheap labor cost', value: 0.3, isPositive: true),
      CountryModifier(label: 'Assembly Efficiency', description: 'Fast component packaging', value: 1.6, isPositive: true),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 200000.0, baseOperatingCost: 350.0),
  );
}
