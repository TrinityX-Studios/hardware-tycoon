import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class Japan extends CountryModel {
  const Japan() : super(
    id: 'jpn',
    name: 'Japan',
    region: 'Asia',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'High Precision', description: 'Base Wafer Yield Bonus', value: 1.15, isPositive: true),
      CountryModifier(label: 'Labor Cost', description: 'Low labor overhead', value: 0.7, isPositive: true),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 450000.0, baseOperatingCost: 1000.0),
  );
}
