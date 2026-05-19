import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class UnitedKingdom extends CountryModel {
  const UnitedKingdom() : super(
    id: 'uk',
    name: 'United Kingdom',
    region: 'Europe',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'Academic Hub', description: 'Talent Bonus', value: 1.4, isPositive: true),
      CountryModifier(label: 'Regulatory Friction', description: 'Complex bureaucracy', value: 1.3, isPositive: false),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 500000.0, baseOperatingCost: 1300.0),
  );
}
