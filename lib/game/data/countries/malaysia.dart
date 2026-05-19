import 'package:flutter/material.dart';
import '../../models/country_model.dart';
import '../../core/game_state.dart';

class Malaysia extends CountryModel {
  const Malaysia() : super(
    id: 'mys',
    name: 'Malaysia',
    region: 'Southeast Asia',
    icon: Icons.flag,
    modifiers: const [
      CountryModifier(label: 'Free-Trade Corridor', description: 'Very low regulatory friction', value: 0.3, isPositive: true),
      CountryModifier(label: 'Labor Cost', description: 'Cheap labor overhead', value: 0.4, isPositive: true),
    ],
    baseConfig: const FinancialConfig(startingLiquidity: 250000.0, baseOperatingCost: 400.0),
  );
}
