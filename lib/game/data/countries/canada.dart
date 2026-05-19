import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class Canada extends CountryModel {
  const Canada() : super(
    id: 'can',
    name: 'Canada',
    region: 'North America',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'Stable Infrastructure', description: 'Talent Bonus', value: 1.1, isPositive: true),
      CountryModifier(label: 'Labor Cost', description: 'Operational overhead', value: 1.1, isPositive: false),
      CountryModifier(label: 'Reduced Friction', description: 'Smoother operations', value: 0.8, isPositive: true),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 480000.0, baseOperatingCost: 1100.0),
  );
}
