/// Hardware Tycoon — Country Model
///
/// Base class representing a starting country and its regional multipliers.
library;

import 'package:flutter/material.dart';
import '../core/game_state.dart';

class CountryModifier {
  final String label;
  final String description;
  final double value;
  final bool isPositive;

  const CountryModifier({
    required this.label,
    required this.description,
    required this.value,
    required this.isPositive,
  });
}

abstract class CountryModel {
  final String id;
  final String name;
  final String region;
  final IconData icon;
  final List<CountryModifier> modifiers;
  final FinancialConfig baseConfig;

  const CountryModel({
    required this.id,
    required this.name,
    required this.region,
    required this.icon,
    required this.modifiers,
    required this.baseConfig,
  });
}
