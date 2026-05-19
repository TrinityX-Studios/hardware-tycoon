import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class India extends CountryModel {
  const India() : super(
    id: 'ind',
    name: 'India',
    region: 'South Asia',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'Mathematical Frontier', description: 'Moderate talent reduction', value: 0.9, isPositive: false),
      CountryModifier(label: 'Labor Cost', description: 'Very cheap labor cost', value: 0.3, isPositive: true),
      CountryModifier(label: 'Bureaucracy', description: 'High regulatory friction', value: 1.4, isPositive: false),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 220000.0, baseOperatingCost: 380.0),
  );
}
