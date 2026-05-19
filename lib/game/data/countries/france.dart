import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class France extends CountryModel {
  const France() : super(
    id: 'fra',
    name: 'France',
    region: 'Europe',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'State Subsidized', description: 'Talent Bonus', value: 1.2, isPositive: true),
      CountryModifier(label: 'Labor Rules', description: 'Very high employee friction', value: 1.6, isPositive: false),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 550000.0, baseOperatingCost: 1400.0),
  );
}
