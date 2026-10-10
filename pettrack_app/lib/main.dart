import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:camera/camera.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/language_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/setup_wizard_screen.dart';
import 'screens/monitor_setup_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/server_recovery_screen.dart';
import 'screens/wear/wear_setup_screen.dart';
import 'screens/wear/wear_dashboard_screen.dart';

late List<CameraDescription> _cameras;
List<CameraDescription> get cameras => _cameras;

/// True on WearOS, so the watch gets its own first screen.
Future<bool> _detectWatch() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.systemFeatures.contains('android.hardware.type.watch');
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final coldStart = Stopwatch()..start();
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      20 * 1024 * 1024; // 20 MB

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // The cold-start budget is 2 s to first meaningful frame, so the
  // platform lookups run together instead of one after another, and
  // camera discovery (monitor-only) never holds up the app side.
  final results = await Future.wait<dynamic>([
    availableCameras().catchError((_) => <CameraDescription>[]),
    SharedPreferences.getInstance(),
    AuthService.init(),
    _detectWatch(),
  ]);
  _cameras = results[0] as List<CameraDescription>;
  final prefs = results[1] as SharedPreferences;
  final savedLocale = prefs.getString('language_code') ?? 'hu';
  final themeModeString = prefs.getString('theme_mode') ?? 'system';

  // The access token is short-lived; keep it fresh in the background so
  // screens can read it live at request time (see AuthService).
  unawaited(AuthService.refreshIfNeeded());
  Timer.periodic(
    const Duration(minutes: 5),
    (_) => AuthService.refreshIfNeeded(),
  );

  ThemeMode initialThemeMode;
  switch (themeModeString) {
    case 'light':
      initialThemeMode = ThemeMode.light;
      break;
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    case 'system':
    default:
      initialThemeMode = ThemeMode.system;
  }

  runApp(
    PetTrackApp(
      initialLocale: savedLocale,
      initialThemeMode: initialThemeMode,
      isWatch: results[3] as bool,
    ),
  );

  if (kDebugMode) {
    // The number behind "cold start < 2 s": run in profile on a device and
    // read this line from logcat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'cold start: first frame in ${coldStart.elapsedMilliseconds} ms',
      );
    });
  }
}

class PetTrackApp extends StatefulWidget {
  final String? initialLocale;
  final ThemeMode initialThemeMode;
  final bool isWatch;

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  const PetTrackApp({
    super.key,
    this.initialLocale,
    this.initialThemeMode = ThemeMode.system,
    this.isWatch = false,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _PetTrackAppState? state = context
        .findAncestorStateOfType<_PetTrackAppState>();
    state?.setLocale(newLocale);
  }

  static void setThemeMode(BuildContext context, ThemeMode mode) {
    themeNotifier.value = mode;
    _PetTrackAppState? state = context
        .findAncestorStateOfType<_PetTrackAppState>();
    state?.setThemeMode(mode);
  }

  @override
  State<PetTrackApp> createState() => _PetTrackAppState();
}

class _PetTrackAppState extends State<PetTrackApp> with WidgetsBindingObserver {
  Locale? _locale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeMode = widget.initialThemeMode;
    PetTrackApp.themeNotifier.value = _themeMode;
    if (widget.initialLocale != null) {
      _locale = Locale(widget.initialLocale!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background may mean the short-lived access token
    // expired while we were away — swap it before the next screen fetches.
    if (state == AppLifecycleState.resumed) {
      AuthService.refreshIfNeeded();
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: PetTrackApp.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          // The status bar follows the theme even on screens without an
          // AppBar — white clock and icons on a light page were unreadable.
          // The region is declarative and merges with an AppBar's own; the
          // imperative call under it is the floor, because a frame whose
          // region is not hit leaves the window on the Android theme default
          // (white icons) and nothing corrects it.
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            final style = SystemUiOverlayStyle(
              statusBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: style,
              child: SystemOverlayStyle(
                style: style,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hu'),
            Locale('zh'),
            Locale('it'),
            Locale('de'),
            Locale('ja'),
            Locale('ko'),
          ],
          locale: _locale,
          home: BootScreen(isWatch: widget.isWatch),
        );
      },
    );
  }
}

/// Pushes a [SystemUiOverlayStyle] to the platform after every build.
///
/// [AnnotatedRegion] alone is a hit-test: when the sample point lands on no
/// region, the window keeps whatever the native theme declared. This calls the
/// platform directly so the ink always tracks the app's brightness, and asks
/// the host activity to say it again where Android still listens.
class SystemOverlayStyle extends StatefulWidget {
  final SystemUiOverlayStyle style;
  final Widget child;

  const SystemOverlayStyle({
    super.key,
    required this.style,
    required this.child,
  });

  @override
  State<SystemOverlayStyle> createState() => _SystemOverlayStyleState();
}

class _SystemOverlayStyleState extends State<SystemOverlayStyle>
    with WidgetsBindingObserver {
  static const _systemUi = MethodChannel('pettrack/system_ui');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _push();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the foreground is exactly when Android has been known to
    // hand the window back with the glyphs wiped — say it again.
    if (state == AppLifecycleState.resumed) _push();
  }

  @override
  void didUpdateWidget(SystemOverlayStyle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) _push();
  }

  void _push() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(widget.style);
      _pushToAndroid();
    });
  }

  /// [SystemChrome] only speaks the modern appearance flags, and it drops a
  /// repeat of a style it has already sent. The host activity re-asserts both
  /// that and the legacy light-bar flags, and is happy to hear it again.
  Future<void> _pushToAndroid() async {
    try {
      await _systemUi.invokeMethod<void>('setInk', <String, bool>{
        'status': widget.style.statusBarIconBrightness == Brightness.dark,
        'nav':
            widget.style.systemNavigationBarIconBrightness == Brightness.dark,
      });
    } on MissingPluginException {
      // No Android host listening — SystemChrome already said it.
    } on PlatformException {
      // System chrome must never be able to take the app down with it.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class BootScreen extends StatefulWidget {
  final bool isWatch;
  const BootScreen({super.key, this.isWatch = false});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('app_mode');

    // No artificial splash delay: route the moment prefs say where to go.
    if (!mounted) return;

    if (widget.isWatch) {
      final ip = prefs.getString('server_ip');
      final token = prefs.getString('api_token');
      if (ip != null && ip.isNotEmpty && token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => WearDashboardScreen(serverIp: ip, token: token),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WearSetupScreen()),
        );
      }
      return;
    }

    if (mode == null) {
      // First launch
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LanguageScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }

    if (mode == 'client') {
      final ip = prefs.getString('server_ip') ?? '';
      var token = prefs.getString('jwt_token') ?? '';
      final secret = prefs.getString('secret_token') ?? '';
      final petName = prefs.getString('pet_name') ?? '';
      // Pairing alone is not setup. A phone that got as far as the secret
      // but never named a pet belongs in the wizard — which now resumes
      // where it left off — not in an empty dashboard.
      final setupDone =
          (prefs.getBool('is_setup_completed') ?? false) || petName.isNotEmpty;

      if (!setupDone) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SetupWizardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
        return;
      }

      // A phone that knows its server and secret must never be sent back
      // through the wizard just because the session lapsed — log in again.
      if (token.isEmpty && ip.isNotEmpty && secret.isNotEmpty) {
        final recovered = await AuthService.loginWithSecret(
          serverIp: ip,
          secret: secret,
        );
        if (recovered) token = AuthService.token;
        if (!mounted) return;
      }

      if (ip.isNotEmpty && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MainNavigationScreen(
                  serverIp: ip,
                  token: token,
                  petName: petName,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else if (setupDone && ip.isNotEmpty) {
        // Set up, but no session and the server did not answer. That is a
        // network problem wearing a login problem's clothes — never the
        // wizard, which would look like the setup was lost.
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ServerRecoveryScreen(serverIp: ip),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SetupWizardScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    } else if (mode == 'monitor') {
      final ip = prefs.getString('server_ip');
      final token = prefs.getString('server_token');
      final clientId = prefs.getString('client_id') ?? 'unnamed_monitor';

      if (ip != null && ip.isNotEmpty && token != null && token.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MonitorScreen(serverIp: ip, token: token, clientId: clientId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MonitorSetupScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    } else {
      // An unknown mode (a hand-edited pref, a build that changed its mind)
      // must not strand anyone on the spinner — start over, not hang.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LanguageScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    body: Center(
      child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
