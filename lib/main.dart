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
import 'game/views/about_and_credits.dart';
import 'game/managers/audio_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
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

class _HardwareTycoonAppState extends State<HardwareTycoonApp> with WindowListener {
  late final AppStateMachine _appState;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _appState = AppStateMachine();
    windowManager.addListener(this);
    // Start background music
    AudioManager.instance.playBGM('audio/music/Laser_Groove.mp3');
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _appState.dispose();
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null) {
      // Fallback close if context is not ready yet
      await AudioManager.instance.stopBGM();
      await windowManager.destroy();
      return;
    }
    final bool? shouldClose = await _showExitConfirmationDialog(navigatorContext);
    if (shouldClose == true) {
      // Graceful shutdown of audio layers to avoid Linux segmentation faults
      await AudioManager.instance.stopBGM();
      await windowManager.destroy();
    }
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 380.0,
            decoration: BoxDecoration(
              color: HTColors.surface,
              border: Border.all(color: HTColors.secondary, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: HTColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 16.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: HTColors.secondary, size: 16.0),
                    SizedBox(width: 8.0),
                    Text(
                      'SYSTEM SHUTDOWN ADVISED',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        color: HTColors.textPrimary,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                const Divider(color: HTColors.border, height: 1.0),
                const SizedBox(height: 12.0),
                const Text(
                  'ARE YOU SURE YOU WANT TO TERMINATE THE CORE SIMULATION ENVIRONMENT? UNSAVED PROGRESS WILL BE LOST.',
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    color: HTColors.textSecondary,
                    fontSize: 9.0,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: HTColors.border),
                        foregroundColor: HTColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                      child: const Text(
                        'REVERT (NO)',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HTColors.secondaryDim,
                        foregroundColor: HTColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.0),
                          side: const BorderSide(color: HTColors.secondary, width: 1.0),
                        ),
                      ),
                      child: const Text(
                        'SHUTDOWN (YES)',
                        style: TextStyle(
                          fontFamily: 'IBMPlexMono',
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
      case AppScreen.about:
        return AboutAndCreditsView(appState: _appState);
      case AppScreen.gameplay:
        // Wrap GameShell in the GameStateProvider for the active game session
        return GameStateProvider(
          notifier: _appState.activeGameState!,
          child: GameplayDashboard(appState: _appState),
        );
    }
  }
}
