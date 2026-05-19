import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'game/core/theme.dart';
import 'game/core/app_state.dart';
import 'game/core/game_state_provider.dart';
import 'game/views/gameplay_dashboard.dart';
import 'game/views/main_menu_view.dart';
import 'game/views/setup_view.dart';
import 'game/views/session_slots_view.dart';
import 'game/views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await windowManager.ensureInitialized();
  } catch (_) {}

  // Enforce landscape orientation for all platforms
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Remove system UI overlay on mobile for immersive game experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const HardwareTycoonApp());
}

class HardwareTycoonApp extends StatefulWidget {
  const HardwareTycoonApp({super.key});

  @override
  State<HardwareTycoonApp> createState() => _HardwareTycoonAppState();
}

class _HardwareTycoonAppState extends State<HardwareTycoonApp> {
  late final AppStateMachine _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppStateMachine();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hardware Tycoon',
          debugShowCheckedModeBanner: false,
          theme: hardwareTycoonTheme,
          home: _buildCurrentScreen(),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    switch (_appState.currentScreen) {
      case AppScreen.mainMenu:
        return MainMenuView(appState: _appState);
      case AppScreen.newGameSetup:
        return SetupView(appState: _appState);
      case AppScreen.sessionSlots:
        return SessionSlotsView(appState: _appState);
      case AppScreen.settings:
        return SettingsView(appState: _appState);
      case AppScreen.gameplay:
        // Wrap GameShell in the GameStateProvider for the active game session
        return GameStateProvider(
          notifier: _appState.activeGameState!,
          child: GameplayDashboard(appState: _appState),
        );
    }
  }
}
