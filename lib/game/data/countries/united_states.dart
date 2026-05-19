import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class UnitedStates extends CountryModel {
  const UnitedStates() : super(
    id: 'usa',
    name: 'United States',
    region: 'North America',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'High Talent', description: 'Silicon Research Bonus', value: 1.5, isPositive: true),
      CountryModifier(label: 'Labor Cost', description: 'Expensive operational overhead', value: 1.4, isPositive: false),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 650000.0, baseOperatingCost: 1800.0),
  );
}
