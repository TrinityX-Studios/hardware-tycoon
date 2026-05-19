/// Hardware Tycoon — Game State Provider
///
/// InheritedNotifier wrapper that provides the [GameStateNotifier]
/// down the widget tree without any third-party DI packages.
library;

import 'package:flutter/widgets.dart';
import 'game_state.dart';

class GameStateProvider extends InheritedNotifier<GameStateNotifier> {
  const GameStateProvider({
    super.key,
    required GameStateNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Retrieve the [GameStateNotifier] from the nearest ancestor.
  /// Automatically rebuilds when [notifyListeners] is called.
  static GameStateNotifier of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<GameStateProvider>();
    assert(provider != null, 'No GameStateProvider found in widget tree');
    return provider!.notifier!;
  }

  /// Retrieve without subscribing to changes (for callbacks, not builds).
  static GameStateNotifier read(BuildContext context) {
    final provider = context
        .getInheritedWidgetOfExactType<GameStateProvider>();
    assert(provider != null, 'No GameStateProvider found in widget tree');
    return provider!.notifier!;
  }
}
