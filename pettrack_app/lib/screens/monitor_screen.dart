import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:pettrack_app/l10n/app_localizations.dart';
import 'package:pettrack_app/theme/colors.dart';
import 'package:pettrack_app/screens/monitor_setup_screen.dart';
import 'package:pettrack_app/utils/night_vision.dart';
import 'package:pettrack_app/utils/sound_detect.dart';
import 'package:pettrack_app/main.dart';
import 'package:pettrack_app/screens/welcome_screen.dart';
import '../services/auth_service.dart';

class MonitorScreen extends StatefulWidget {
  final String serverIp;
  final String token;
  final String clientId;
  const MonitorScreen({
    super.key,
    required this.serverIp,
    required this.token,
    required this.clientId,
  });

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  late CameraController _controller;

  WebSocketChannel? _socket;
  final AudioPlayer _callPlayer = AudioPlayer();
  final AudioRecorder _soundRecorder = AudioRecorder();
  StreamSubscription<Amplitude>? _soundSub;
  StreamSubscription<Uint8List>? _pcmSub;
  DateTime? _lastSoundReport;
  bool _isInitialized = false;
  bool _cameraFailed = false;
  bool _isStreaming = false;
  bool _isSleeping = false;
  Timer? _streamTimer;
  bool _isCapturing = false;
  final GlobalKey _cameraKey = GlobalKey();
  final Battery _battery = Battery();
  Timer? _statusTimer;
  Timer? _reconnectTimer;
  bool _shouldStream = false;
  bool _isReconnecting = false;
  // A viewer can flip this remotely: torch + exposure + gamma lift so the
  // pet is visible in a dark room.
  bool _nightMode = false;

  late String _currentIp;
  late String _currentToken;
  late String _currentClientId;

  @override
  void initState() {
    super.initState();
    _currentIp = widget.serverIp;
    _currentToken = widget.token;
    _currentClientId = widget.clientId;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initCamera();
    _connectWebSocket();
  }

  Future<void> _initCamera() async {
    try {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller.initialize();
      await _controller.setFlashMode(FlashMode.off);
      await _controller.setFocusMode(FocusMode.auto);
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  /// The camera can fail transiently (permission race, another app holding
  /// it) — offer a retry instead of spinning forever.
  Future<void> _retryCamera() async {
    setState(() {
      _cameraFailed = false;
      _isInitialized = false;
    });
    try {
      await _controller.dispose();
    } catch (_) {}
    await _initCamera();
  }

  void _scheduleReconnect() {
    if (!mounted) return;
    setState(() => _isReconnecting = true);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint("Attempting to reconnect...");
      _connectWebSocket();
    });
  }

  Future<void> _connectWebSocket() async {
    if (!mounted) return;

    if (_currentIp.contains('demo_ip')) {
      debugPrint("Demo mode: skipping WebSocket connection");
      return;
    }

    try {
      debugPrint("Connecting to ws://$_currentIp/ws");
      final wsUrl =
          '${_currentIp.replaceAll("http", "ws")}/ws?token=${AuthService.token}&client_id=$_currentClientId';
      _socket = WebSocketChannel.connect(Uri.parse(wsUrl));

      debugPrint("Connected successfully!");
      _reconnectTimer?.cancel();
      if (mounted) setState(() => _isReconnecting = false);

      if (_shouldStream) {
        _startStreaming();
      }

      _socket!.stream.listen(
        (message) {
          if (message == "START") {
            _startStreaming();
          } else if (message == "STOP") {
            _stopStreaming(isManual: true);
          } else {
            try {
              final data = json.decode(message);
              if (data['action'] == 'set_fps' && data['fps'] != null) {
                _updateStreamSpeed((data['fps'] as num).toDouble());
              } else if (data['action'] == 'play_sound') {
                _playCallSound();
              } else if (data['action'] == 'night_mode') {
                _setNightMode(data['enabled'] == true);
              }
            } catch (_) {}
          }
        },
        onDone: () {
          debugPrint("Server disconnected!");
          _stopStreaming(isManual: false);
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _stopStreaming(isManual: false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint("Failed to connect: $e");
      _scheduleReconnect();
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorConnectionFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startStreaming() {
    _shouldStream = true;
    if (_isStreaming || !_isInitialized) return;

    setState(() => _isStreaming = true);
    WakelockPlus.enable();
    debugPrint("Starting Stream");

    _startSoundWatch();
    _sendBatteryStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendBatteryStatus();
    });

    _streamTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      _,
    ) async {
      if (!_isCapturing) {
        await _captureAndSendFrame();
      }
    });
  }

  /// A viewer pressed "play a sound": chirp so the pet looks at the camera.
  Future<void> _playCallSound() async {
    try {
      await _callPlayer.play(AssetSource('sounds/pet_call.wav'));
    } catch (e) {
      debugPrint('Failed to play call sound: $e');
    }
  }

  /// Watch the mic for loud noises (bark / meow) while streaming.
  ///
  /// Only the loudness number leaves the phone — the audio itself is never
  /// recorded or sent anywhere. Requires a mic permission prompt on first use.
  Future<void> _startSoundWatch() async {
    if (_soundSub != null) return;
    try {
      if (!await _soundRecorder.hasPermission()) {
        debugPrint('Mic permission denied — sound events off');
        return;
      }
      // Amplitude needs an active recording session; the stream itself is
      // drained and discarded.
      final pcm = await _soundRecorder.startStream(
        const RecordConfig(numChannels: 1, sampleRate: 16000),
      );
      _pcmSub = pcm.listen((_) {}, onError: (_) {});
      _soundSub = _soundRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 250))
          .listen(
            _onSoundLevel,
            onError: (e) => debugPrint('Sound watch error: $e'),
          );
    } catch (e) {
      debugPrint('Failed to start sound watch: $e');
    }
  }

  void _onSoundLevel(Amplitude amp) {
    if (!isSoundLevelEvent(amp.current)) return;
    final now = DateTime.now();
    if (_lastSoundReport != null &&
        now.difference(_lastSoundReport!) < kSoundReportCooldown) {
      return;
    }
    _lastSoundReport = now;
    _reportSound(amp.current);
  }

  Future<void> _reportSound(double levelDb) async {
    try {
      await http.post(
        Uri.parse('$_currentIp/api/monitor/sound'),
        headers: {
          'x-api-token': AuthService.token,
          'Content-Type': 'application/json',
        },
        body: json.encode({'level': levelDb}),
      );
    } catch (e) {
      debugPrint('Failed to report sound: $e');
    }
  }

  Future<void> _stopSoundWatch() async {
    await _soundSub?.cancel();
    _soundSub = null;
    await _pcmSub?.cancel();
    _pcmSub = null;
    try {
      await _soundRecorder.stop();
    } catch (_) {}
    _lastSoundReport = null;
  }

  /// A viewer toggled night mode: torch + exposure lift on the camera,
  /// gamma lift on the outgoing frames. Each step is best-effort — old
  /// phones may not support torch or exposure control.
  Future<void> _setNightMode(bool enabled) async {
    if (mounted) setState(() => _nightMode = enabled);
    try {
      await _controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
    } catch (e) {
      debugPrint('Torch not available: $e');
    }
    try {
      final max = await _controller.getMaxExposureOffset();
      final target = enabled ? (max > 0 ? (max < 1.5 ? max : 1.5) : 0.0) : 0.0;
      await _controller.setExposureOffset(target);
    } catch (e) {
      debugPrint('Exposure adjust failed: $e');
    }
  }

  void _updateStreamSpeed(double fps) {
    if (!_isStreaming) return;
    _streamTimer?.cancel();
    final interval = (1000 / fps).round();
    _streamTimer = Timer.periodic(Duration(milliseconds: interval), (_) async {
      if (!_isCapturing) {
        await _captureAndSendFrame();
      }
    });
    debugPrint("Stream speed updated to $fps FPS ($interval ms)");
  }

  void _stopStreaming({bool isManual = false}) {
    if (isManual) {
      _shouldStream = false;
    }
    if (!_isStreaming) return;

    _streamTimer?.cancel();
    _streamTimer = null;
    _statusTimer?.cancel();
    _statusTimer = null;
    _stopSoundWatch();

    setState(() {
      _isStreaming = false;
      _isSleeping = false;
    });
    WakelockPlus.disable();
    debugPrint("Stopping Stream");
  }

  Future<void> _sendBatteryStatus() async {
    if (!_isStreaming) return;
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final isCharging =
          state == BatteryState.charging || state == BatteryState.full;

      await http.post(
        Uri.parse('$_currentIp/api/monitor/update'),
        headers: {
          'x-api-token': AuthService.token,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'battery_level': level,
          'is_charging': isCharging,
          // Lets the dashboard keep per-camera battery chips.
          'monitor_id': _currentClientId,
        }),
      );
    } catch (e) {
      debugPrint("Failed to send battery Status: $e");
    }
  }

  Future<void> _captureAndSendFrame() async {
    if (!_controller.value.isInitialized || !_isStreaming || _socket == null) {
      return;
    }

    _isCapturing = true;
    try {
      final boundary =
          _cameraKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 1.0);
      final width = image.width;
      final height = image.height;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      image.dispose(); // Prevent OOM memory leak

      if (byteData == null) return;

      // Encode as JPEG and cap the width: a PNG screenshot of the preview was
      // 1-3 MB per frame and burned CPU on old phones; a ~1280px JPEG at q80
      // is roughly 50-150 KB and keeps the stream light.
      var frame = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: byteData.buffer,
        order: img.ChannelOrder.rgba,
      );
      if (frame.width > 1280) {
        frame = img.copyResize(frame, width: 1280);
      }
      if (_nightMode) {
        frame = applyNightBoost(frame);
      }
      final bytes = img.encodeJpg(frame, quality: 80);

      if (_socket != null) {
        _socket!.sink.add(bytes);
      }
    } catch (e) {
      debugPrint("Capture Failed: $e");
    } finally {
      _isCapturing = false;
    }
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _statusTimer?.cancel();
    _reconnectTimer?.cancel();
    _stopSoundWatch();
    _soundRecorder.dispose();
    _controller.dispose();
    _callPlayer.dispose();
    _socket?.sink.close();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final mainScreen = Scaffold(
      appBar: AppBar(
        title: Text(l10n.monitorTitle),
        actions: [
          if (_isStreaming)
            IconButton(
              icon: const Icon(Icons.bedtime),
              tooltip: l10n.monitorSleepMode,
              onPressed: () => setState(() => _isSleeping = true),
            ),

          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: l10n.exit,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('app_mode');
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
          ),

          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'theme') {
                final isDark =
                    PetTrackApp.themeNotifier.value == ThemeMode.dark;
                PetTrackApp.themeNotifier.value = isDark
                    ? ThemeMode.light
                    : ThemeMode.dark;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('theme_mode', isDark ? 'light' : 'dark');
              } else if (value == 'settings') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MonitorSetupScreen(),
                  ),
                );

                if (result == true && mounted) {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() {
                    _currentIp = prefs.getString('server_ip') ?? _currentIp;
                    _currentToken =
                        prefs.getString('server_token') ?? _currentToken;
                    _currentClientId =
                        prefs.getString('client_id') ?? _currentClientId;
                  });
                  _socket?.sink.close();
                  _connectWebSocket();
                }
              } else if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: l10n.monitorTitle,
                  applicationVersion: l10n.appVersion,
                  applicationIcon: const Icon(
                    Icons.pets,
                    size: 50,
                    color: Colors.orange,
                  ),
                  children: [Text(l10n.aboutDescription)],
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'theme',
                  child: Text(
                    PetTrackApp.themeNotifier.value == ThemeMode.dark
                        ? l10n.lightMode
                        : l10n.darkMode,
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Text(l10n.settingsTitle),
                ),
                PopupMenuItem(value: 'about', child: Text(l10n.aboutTitle)),
              ];
            },
          ),
        ],
      ),
      body: _isInitialized
          ? Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(16.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadiusGeometry.circular(14),
                          child: RepaintBoundary(
                            key: _cameraKey,
                            child: CameraPreview(_controller),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Night mode is toggled remotely by a viewer —
                            // show the person at the monitor that it is on.
                            if (_nightMode) ...[
                              Tooltip(
                                message: l10n.tooltipNightMode,
                                child: const Icon(
                                  Icons.nightlight,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                _isStreaming
                                    ? l10n.monitorStreamingLive
                                    : _isReconnecting
                                    ? l10n.monitorReconnecting
                                    : l10n.monitorWaitingForStart,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ElevatedButton(
                              onPressed: _isStreaming ? null : _startStreaming,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                l10n.start,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isStreaming
                                  ? () => _stopStreaming(isManual: true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              child: Text(
                                l10n.stop,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.monitorServer(widget.serverIp),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _cameraFailed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_photography, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.cameraStartFailed),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _retryCamera,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );

    if (!_isSleeping) {
      return mainScreen;
    }

    return Stack(
      children: [
        mainScreen,
        GestureDetector(
          onDoubleTap: () => setState(() => _isSleeping = false),
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(color: Colors.white24, fontSize: 12),
                child: Text(l10n.monitorSleeping),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
