import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pettrack_app/l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';
import '../widgets/highlight_card.dart';
import 'insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String serverIp;
  final String token;
  final String petName;

  const DashboardScreen({
    super.key,
    required this.serverIp,
    required this.token,
    required this.petName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ui.Image? _currentUiImage;
  double _cameraAspectRatio = 16 / 9;
  String? _secretToken;
  WebSocketChannel? _clientChannel;
  Timer? _timer;
  bool _isServerOnline = true;
  int _statusFailures = 0;
  List<dynamic> _activities = [];
  final Map<String, DateTime> _lastZoneAlerts = {};
  final Map<String, int> _zoneAlertIds = {};
  int _nextAlertId = 1000;
  Uint8List? _profilePicBytes;
  List<dynamic> _zonesCache = [];
  String _petType = 'rabbit';
  String _petName = '';
  String? _monitorId;
  int _batteryLevel = 100;
  bool _isCharging = false;
  bool _alertsZoneEnabled = true;
  bool _alertsBatteryEnabled = true;
  bool _alertsSoundEnabled = true;
  double _batteryThreshold = 20.0;
  bool _hasAlertedBattery = false;
  bool _hasCameraError = false;
  // Mirrors the monitor's low-light mode (toggled remotely from here).
  bool _nightMode = false;
  DateTime? _frameTimestamp;
  // Multi-camera: every monitor that has checked in, and the one in focus.
  List<dynamic> _monitors = [];
  String? _selectedMonitorId;
  bool _showCameraGrid = false;
  Timer? _gridTimer;
  int _gridRefresh = 0;
  int _socketGen = 0;
  String? _socketMonitorId;
  final HomeWidgetService _homeWidget = HomeWidgetService();

  String get _displayPetName {
    if (widget.serverIp.contains('demo_ip')) return "Tapsi Hapsi";
    if (_petName.isNotEmpty) return _petName;
    return widget.petName.isEmpty
        ? AppLocalizations.of(context)!.unknown
        : widget.petName;
  }

  /// Icon + copy for one activity event, shared by every feed style.
  (IconData, Color, String, String) _eventDisplay(
    Map<String, dynamic> ev,
    AppLocalizations l10n,
  ) {
    final type = ev['event_type'];
    if (type == 'sound_detected') {
      return (
        Icons.volume_up,
        AppColors.tertiary,
        l10n.soundDetectedTitle,
        l10n.soundDetectedBody,
      );
    }
    if (type == 'camera_offline') {
      return (
        Icons.videocam_off,
        AppColors.warning,
        l10n.cameraOfflineTitle,
        l10n.cameraOfflineBody,
      );
    }
    if (type == 'disk_low') {
      return (
        Icons.sd_storage_outlined,
        AppColors.warning,
        l10n.diskLowTitle,
        l10n.diskLowBody,
      );
    }
    final isEnter = type == 'zone_enter';
    final zone = ev['zone_name'] ?? l10n.unknown;
    return (
      isEnter ? Icons.meeting_room : Icons.directions_walk,
      isEnter ? AppColors.primary : AppColors.secondary,
      isEnter
          ? l10n.zoneEntered(_displayPetName, zone)
          : l10n.zoneLeft(_displayPetName, zone),
      isEnter ? l10n.cameraDetectedMovement : l10n.leftTheZone,
    );
  }

  IconData _getPetIcon(String type) {
    switch (type) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'rabbit':
        return Icons.cruelty_free;
      case 'bird':
        return Icons.flutter_dash;
      case 'guineapig':
        return Icons.pest_control_rodent;
      default:
        return Icons.pets;
    }
  }

  late int _greetingIndex;
  late int _subGreetingIndex;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _greetingIndex = rand.nextInt(10);
    _subGreetingIndex = rand.nextInt(10);
    NotificationService().init();
    NotificationService().requestPermissions();
    _loadAlertSettings();
    _loadProfilePic();
    _fetchPetProfile();
    _loadSecret();

    if (widget.serverIp.contains('demo_ip')) {
      _isServerOnline = true;
      _activities = [
        {
          "event_type": "zone_enter",
          "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "zone_name": "Alomtálca",
        },
        {
          "event_type": "zone_left",
          "timestamp":
              DateTime.now()
                  .subtract(const Duration(minutes: 5))
                  .millisecondsSinceEpoch ~/
              1000,
          "zone_name": "Játszótér",
        },
        {
          "event_type": "zone_enter",
          "timestamp":
              DateTime.now()
                  .subtract(const Duration(minutes: 15))
                  .millisecondsSinceEpoch ~/
              1000,
          "zone_name": "Etető",
        },
      ];
      _zonesCache = [
        {"name": "Alomtálca", "type": "toilet"},
        {"name": "Játszótér", "type": "play"},
        {"name": "Etető", "type": "food"},
      ];
    } else {
      _fetchZones();
      _startPolling();
      _connectClientSocket();
    }
  }

  void _connectClientSocket() async {
    if (widget.serverIp.contains('demo_ip')) {
      debugPrint("Demo mode: skipping WebSocket connection");
      return;
    }

    final gen = ++_socketGen;
    final monitorParam = _selectedMonitorId == null
        ? ''
        : '&monitor=${Uri.encodeComponent(_selectedMonitorId!)}';
    _socketMonitorId = _selectedMonitorId;
    try {
      final wsUrl =
          '${widget.serverIp.replaceAll("http", "ws")}/ws/client?token=${widget.token}$monitorParam';
      _clientChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _clientChannel!.stream.listen(
        (data) {
          if (!mounted || _secretToken == null || gen != _socketGen) return;
          try {
            if (data is String) return;
            final newBytes = data is Uint8List
                ? data
                : Uint8List.fromList(data as List<int>);
            ui.decodeImageFromList(newBytes, (ui.Image img) {
              if (mounted && gen == _socketGen) {
                setState(() {
                  _currentUiImage?.dispose();
                  _currentUiImage = img;
                  if (img.width > 0 && img.height > 0) {
                    _cameraAspectRatio = img.width / img.height;
                  }
                  _frameTimestamp = DateTime.now().toUtc();
                  _hasCameraError = false;
                  _isServerOnline = true;
                });
                _pushHomeWidget();
              } else {
                img.dispose();
              }
            });
          } catch (e) {
            debugPrint("Frame decrypt error: $e");
          }
        },
        onDone: () {
          if (!mounted || gen != _socketGen) return;
          setState(() => _isServerOnline = false);
          Future.delayed(const Duration(seconds: 3), _connectClientSocket);
        },
        onError: (e) {
          if (!mounted || gen != _socketGen) return;
          setState(() => _isServerOnline = false);
          Future.delayed(const Duration(seconds: 3), _connectClientSocket);
        },
      );
    } catch (e) {
      if (!mounted || gen != _socketGen) return;
      setState(() => _isServerOnline = false);
      Future.delayed(const Duration(seconds: 3), _connectClientSocket);
    }
  }

  /// Swap the live stream over to another camera (or back to "all" with null).
  void _selectMonitor(String? monitorId) {
    if (monitorId == _selectedMonitorId) return;
    _socketGen++; // kill the old listener before closing, so it cannot reconnect
    setState(() {
      _selectedMonitorId = monitorId;
      _showCameraGrid = false;
      _currentUiImage?.dispose();
      _currentUiImage = null;
      _frameTimestamp = null;
    });
    _gridTimer?.cancel();
    _clientChannel?.sink.close();
    _clientChannel = null;
    _connectClientSocket();
  }

  /// Hand the current still + status to the Android home-screen widget.
  /// Throttled — the home screen does not need every frame.
  Future<void> _pushHomeWidget() async {
    if (!_homeWidget.isDue()) return;
    final image = _currentUiImage;
    if (image == null) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    Uint8List? png;
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      png = data?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Home widget encode error: $e');
    }
    final battery = _focusedBattery;
    await _homeWidget.push(
      WidgetSnapshot(
        title: _displayPetName,
        status: _getBadgeInfo(l10n).text,
        batteryLabel: '${battery.$1}%',
        emptyHint: l10n.widgetEmptyHint,
        png: png,
      ),
    );
  }

  /// Polls each camera's still so the grid tiles stay fresh without websockets.
  void _startGridRefresh() {
    _gridTimer?.cancel();
    _gridTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _showCameraGrid) setState(() => _gridRefresh++);
    });
  }

  Future<void> _loadAlertSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _alertsZoneEnabled = prefs.getBool('alerts_zone_enabled') ?? true;
        _alertsBatteryEnabled = prefs.getBool('alerts_battery_enabled') ?? true;
        _alertsSoundEnabled = prefs.getBool('alerts_sound_enabled') ?? true;
        _batteryThreshold = prefs.getDouble('alerts_battery_threshold') ?? 20.0;
      });
    }
  }

  Future<void> _loadProfilePic() async {
    final prefs = await SharedPreferences.getInstance();
    final b64 = prefs.getString('profile_pic');
    final pType = prefs.getString('pet_type') ?? 'rabbit';
    final pName = prefs.getString('pet_name') ?? '';
    if (mounted) {
      setState(() {
        _petType = pType;
        _petName = pName;
        if (b64 != null) {
          _profilePicBytes = base64Decode(b64);
        }
      });
    }
  }

  Future<void> _fetchPetProfile() async {
    if (widget.serverIp.contains('demo_ip')) return;
    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/pet'),
            headers: {'x-api-token': widget.token},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        setState(() {
          if (data['name'] != null && data['name'] != "Unknown") {
            _petName = data['name'];
            prefs.setString('pet_name', _petName);
          }
          if (data['type'] != null && data['type'] != "Unknown") {
            _petType = data['type'];
            prefs.setString('pet_type', _petType);
          }
          if (data['profile_pic'] != null) {
            _profilePicBytes = base64Decode(data['profile_pic']);
            prefs.setString('profile_pic', data['profile_pic']);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchZones() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/zones'),
            headers: {'x-api-token': widget.token},
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _zonesCache = data['zones'] as List<dynamic>;
        });
      }
    } catch (_) {}
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      if (mounted) setState(() {});
      _fetchActivity();
      _fetchStatus();
    });
  }

  /// Pull-to-refresh: re-fetch everything at once and confirm with a tick.
  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchPetProfile(),
      _fetchZones(),
      _fetchActivity(),
      _fetchStatus(),
    ]);
    if (mounted) HapticFeedback.lightImpact();
  }

  Future<void> _loadSecret() async {
    final prefs = await SharedPreferences.getInstance();
    _secretToken = prefs.getString('secret_token');
  }

  Future<void> _fetchActivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/activity?limit=50'),
            headers: {'x-api-token': widget.token},
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['events'] == null) return;
        final newEvents = data['events'] as List<dynamic>;

        if (_activities.isEmpty && newEvents.isNotEmpty) {
          setState(() => _activities = newEvents);
        } else if (_activities.length != newEvents.length ||
            (_activities.isNotEmpty &&
                newEvents.isNotEmpty &&
                _activities.first['timestamp'] !=
                    newEvents.first['timestamp'])) {
          if (_activities.isNotEmpty && (_alertsZoneEnabled || _alertsSoundEnabled)) {
            final ev = newEvents.first;
            final l10n = AppLocalizations.of(context)!;
            final eventType = ev['event_type'];
            if (eventType == 'sound_detected' && _alertsSoundEnabled) {
              NotificationService().showNotification(
                id: 3000,
                title: l10n.soundDetectedTitle,
                body: l10n.soundDetectedBody,
              );
            } else if (eventType == 'camera_offline') {
              // Watchdog alarms always notify — "is my pet being watched?"
              // should never be a silent event in the feed.
              NotificationService().showNotification(
                id: 4000,
                title: l10n.cameraOfflineTitle,
                body: l10n.cameraOfflineBody,
              );
            } else if (eventType == 'disk_low') {
              NotificationService().showNotification(
                id: 4001,
                title: l10n.diskLowTitle,
                body: l10n.diskLowBody,
              );
            } else if ((eventType == 'zone_enter' ||
                    eventType == 'zone_exit' ||
                    eventType == 'zone_left') &&
                _alertsZoneEnabled) {
              final isEnter = eventType == 'zone_enter';
              final zoneName = ev['zone_name'] ?? l10n.unknown;
              final now = DateTime.now();
              final lastAlert = _lastZoneAlerts[zoneName];
              if (lastAlert == null ||
                  now.difference(lastAlert).inSeconds >= 60) {
                _lastZoneAlerts[zoneName] = now;
                final alertId = _zoneAlertIds.putIfAbsent(
                  zoneName,
                  () => _nextAlertId++,
                );
                NotificationService().showNotification(
                  id: alertId,
                  title: isEnter
                      ? l10n.zoneEntered(_displayPetName, zoneName)
                      : l10n.zoneLeft(_displayPetName, zoneName),
                  body: '',
                );
              }
            }
          }
          setState(() => _activities = newEvents);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.serverIp}/api/status'),
            headers: {'x-api-token': widget.token},
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        var lowBatteryAlert = false;
        // Decided after setState: switching cameras rebuilds the socket.
        String? selectAfter;
        var reconnectAfter = false;
        setState(() {
          _isServerOnline = true;
          _statusFailures = 0;
          if (data['monitor_id'] != null) {
            _monitorId = data['monitor_id'];
          }
          final monitors = data['monitors'];
          if (monitors is List) {
            _monitors = monitors;
            // Keep the focus on a camera that still exists; when exactly one
            // is left, focus it so the stream is never a mix of two feeds.
            if (_selectedMonitorId != null &&
                !_monitors.any((m) => m['id'] == _selectedMonitorId)) {
              _selectedMonitorId = null;
              reconnectAfter = true;
            } else if (_selectedMonitorId == null &&
                _monitors.length == 1 &&
                _monitors.first['id'] != _socketMonitorId) {
              selectAfter = _monitors.first['id'] as String?;
            }
          }
          if (data['battery_level'] != null) {
            int newBat = data['battery_level'];
            if (_alertsBatteryEnabled &&
                !_isCharging &&
                newBat <= _batteryThreshold &&
                newBat < _batteryLevel &&
                !_hasAlertedBattery) {
              _hasAlertedBattery = true;
              lowBatteryAlert = true;
            }
            if (newBat > _batteryThreshold || _isCharging) {
              _hasAlertedBattery = false;
            }
            _batteryLevel = newBat;
            _isCharging = data['is_charging'] ?? false;
          }
        });
        if (selectAfter != null) _selectMonitor(selectAfter);
        if (reconnectAfter) _connectClientSocket();
        if (lowBatteryAlert && mounted) {
          final l10n = AppLocalizations.of(context)!;
          NotificationService().showNotification(
            id: 2000,
            title: l10n.batteryLowTitle,
            body: l10n.batteryLowBody(data['battery_level'] as int),
          );
        }
      } else if (mounted) {
        _noteStatusFailure();
      }
    } catch (_) {
      if (mounted) _noteStatusFailure();
    }
  }

  /// Battery of the camera in focus (falls back to the active-camera mirror).
  (int, bool) get _focusedBattery {
    if (_selectedMonitorId != null) {
      for (final m in _monitors) {
        if (m['id'] == _selectedMonitorId) {
          return (
            (m['battery_level'] as num?)?.toInt() ?? _batteryLevel,
            m['is_charging'] == true,
          );
        }
      }
    }
    return (_batteryLevel, _isCharging);
  }

  /// Two consecutive failed status polls -> show the unreachable overlay.
  /// One blip should not flash the screen.
  void _noteStatusFailure() {
    _statusFailures++;
    if (_statusFailures >= 2 && _isServerOnline) {
      setState(() => _isServerOnline = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gridTimer?.cancel();
    _clientChannel?.sink.close();
    _currentUiImage?.dispose();
    super.dispose();
  }

  ({String text, Color textColor, Color bgColor}) _getBadgeInfo(
    AppLocalizations l10n,
  ) {
    if (_hasCameraError || _currentUiImage == null) {
      return (
        text: l10n.offlineStatus,
        textColor: Colors.red,
        bgColor: const Color(0xFFFFE5E5),
      );
    }

    if (_frameTimestamp != null) {
      final diff = DateTime.now().toUtc().difference(_frameTimestamp!);
      final sec = diff.inSeconds;
      if (sec <= 10) {
        return (
          text: l10n.liveStatus,
          textColor: Colors.green[800]!,
          bgColor: Colors.green[100]!,
        );
      } else if (sec <= 30) {
        return (
          text: l10n.secondsAgo(sec),
          textColor: Colors.lightGreen[800]!,
          bgColor: Colors.lightGreen[100]!,
        );
      } else {
        return (
          text: l10n.secondsAgo(sec),
          textColor: Colors.orange[800]!,
          bgColor: Colors.orange[100]!,
        );
      }
    }

    return (
      text: l10n.liveStatus,
      textColor: Colors.green[800]!,
      bgColor: Colors.green[100]!,
    );
  }

  /// Camera picker + "all cameras" grid toggle, shown only with 2+ monitors.
  Widget _buildCameraPicker(AppLocalizations l10n) {
    if (_monitors.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in _monitors)
            ChoiceChip(
              label: Text(m['id'] as String),
              selected: !_showCameraGrid && _selectedMonitorId == m['id'],
              onSelected: (_) => _selectMonitor(m['id'] as String),
            ),
          ChoiceChip(
            avatar: const Icon(Icons.grid_view, size: 18),
            label: Text(l10n.cameraGridLabel),
            selected: _showCameraGrid,
            onSelected: (selected) {
              setState(() => _showCameraGrid = selected);
              if (selected) {
                _startGridRefresh();
              } else {
                _gridTimer?.cancel();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Live-ish tiles for every camera; tap one to bring it into focus.
  Widget _buildCameraGrid(AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 16 / 10,
      children: [
        for (final m in _monitors)
          _buildCameraTile(m as Map<String, dynamic>, l10n),
      ],
    );
  }

  Widget _buildCameraTile(Map<String, dynamic> monitor, AppLocalizations l10n) {
    final id = monitor['id'] as String;
    final online = monitor['online'] == true;
    final url =
        '${widget.serverIp}/api/monitors/${Uri.encodeComponent(id)}/frame?v=$_gridRefresh';
    return GestureDetector(
      onTap: online ? () => _selectMonitor(id) : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF15181E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedMonitorId == id
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: online
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    headers: {'x-api-token': widget.token},
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _buildChip(
                      Icons.wifi,
                      "$id · ${monitor['battery_level'] ?? 0}%",
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.redAccent),
                    const SizedBox(height: 4),
                    Text(
                      "$id · ${l10n.offlineStatus}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCameraCard(AppLocalizations l10n, bool isDesktop) {
    final battery = _focusedBattery;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) ...[
          // Mobile header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.serverIp.contains('demo_ip')
                    ? l10n.onlineStatus
                    : l10n.liveVideo,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              _buildBadge(l10n),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _buildCameraPicker(l10n),
        if (_showCameraGrid)
          _buildCameraGrid(l10n)
        else
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: AspectRatio(
            aspectRatio: _cameraAspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(
                  0xFF15181E,
                ), // Dark background matching the image
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.1),
                ),
              ),
              child: widget.serverIp.contains('demo_ip')
                  // Demo mode: a bundled still stands in for the live frame
                  // so the whole dashboard can be explored without a camera.
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/demo_frame.jpg',
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.demoLivePreview,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!_isServerOnline)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_off,
                                    size: 64,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.serverUnreachableTitle,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.serverUnreachableDesc,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else if (_currentUiImage != null)
                            InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: RawImage(
                                image: _currentUiImage!,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),

                          // Overlay Chips
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Row(
                              children: [
                                if (isDesktop) ...[
                                  _buildBadge(l10n),
                                  const SizedBox(width: 8),
                                ],
                                _buildChip(
                                  battery.$2
                                      ? Icons.battery_charging_full
                                      : Icons.battery_full,
                                  "${battery.$1}%",
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  Icons.wifi,
                                  _selectedMonitorId ??
                                      _monitorId ??
                                      l10n.searchingStatus,
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          if (_currentUiImage != null)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  FloatingActionButton.small(
                                    onPressed: _toggleNightMode,
                                    tooltip: l10n.tooltipNightMode,
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    child: Icon(
                                      Icons.nightlight,
                                      color: _nightMode
                                          ? Colors.amber
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FloatingActionButton.small(
                                    onPressed: _sendPlaySound,
                                    tooltip: l10n.tooltipPlaySound,
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    child: const Icon(
                                      Icons.volume_up,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FloatingActionButton.small(
                                    onPressed: _takeSnapshot,
                                    tooltip: l10n.tooltipSnapshot,
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(AppLocalizations l10n) {
    return Builder(
      builder: (context) {
        final badge = _getBadgeInfo(l10n);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isServerOnline ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: badge.textColor,
              ),
              const SizedBox(width: 6),
              Text(
                badge.text,
                style: TextStyle(
                  color: badge.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128), // Dark card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF2C313C),
                    backgroundImage: _profilePicBytes != null
                        ? MemoryImage(_profilePicBytes!)
                        : null,
                    child: _profilePicBytes == null
                        ? Icon(
                            _getPetIcon(_petType),
                            size: 40,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Column(
                    children: [
                      Text(
                        _displayPetName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Entry point to the activity insights screen (the tab bar is full,
  /// so the deep dive lives behind a card).
  Widget _buildInsightsEntry(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InsightsScreen(
                  serverIp: widget.serverIp,
                  token: widget.token,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.insightsTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.insightsEntrySubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityGraph(AppLocalizations l10n) {
    if (_activities.isEmpty) return const SizedBox.shrink();

    // Count zone visits
    final Map<String, int> zoneVisits = {};
    for (var ev in _activities) {
      if (ev['event_type'] == 'zone_enter') {
        final name = ev['zone_name'] ?? l10n.unknown;
        zoneVisits[name] = (zoneVisits[name] ?? 0) + 1;
      }
    }

    Color getZoneColor(String zoneName) {
      String type = 'safe';
      for (var z in _zonesCache) {
        if (z['name'] == zoneName) {
          type = z['type'] ?? 'safe';
          break;
        }
      }
      switch (type) {
        case 'toilet':
          return Colors.blueGrey;
        case 'bed':
          return Colors.indigo;
        case 'water':
          return Colors.blue;
        case 'food':
          return Colors.orange;
        case 'play':
          return Colors.teal;
        case 'safe':
          return AppColors.success;
        case 'danger':
          return AppColors.warning;
        default:
          return AppColors.tertiary;
      }
    }

    final pieSections = zoneVisits.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: getZoneColor(e.key),
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.zoneVisits,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.pie_chart, size: 18, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: zoneVisits.keys.toList().asMap().entries.map((
                      entry,
                    ) {
                      final name = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: getZoneColor(name),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventLog(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2128),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.eventLog,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.access_time, size: 18, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          if (_activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  style: BorderStyle
                      .none, // We don't have dashed border natively easily, using solid
                ),
              ),
              child: Center(
                child: Text(
                  l10n.noRecentEvents,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length > 5 ? 5 : _activities.length,
              separatorBuilder: (context, _) =>
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final ev = _activities[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  (ev['timestamp'] * 1000).toInt(),
                );
                final timeString =
                    "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                final title = _eventDisplay(ev, l10n).$3;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeString,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.navDashboard,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${l10n.lastUpdated}: ${l10n.justNow}",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Asks the monitor phone to chirp, to get the pet's attention.
  void _sendPlaySound() {
    final channel = _clientChannel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'action': 'play_sound'}));
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.playSoundSent),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Asks the monitor to flip night mode (torch + brighter image).
  void _toggleNightMode() {
    final channel = _clientChannel;
    if (channel == null) return;
    final enabled = !_nightMode;
    channel.sink.add(jsonEncode({'action': 'night_mode', 'enabled': enabled}));
    HapticFeedback.lightImpact();
    setState(() => _nightMode = enabled);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled ? l10n.nightModeOn : l10n.nightModeOff),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _takeSnapshot() async {
    if (_currentUiImage == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final byteData = await _currentUiImage!.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;
      final buffer = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/pet_snapshot_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(buffer);

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(file.path),
      ], text: l10n.shareInviteText);
    } catch (e) {
      debugPrint('Snapshot error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          // Desktop Layout
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDesktopHeader(l10n),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Flex 2)
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildCameraCard(l10n, true),
                              const SizedBox(height: 24),
                              HighlightCard(
                                serverIp: widget.serverIp,
                                token: widget.token,
                              ),
                              // Stats removed to unify design
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column (Flex 1)
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildProfileCard(l10n),
                              const SizedBox(height: 24),
                              _buildInsightsEntry(l10n),
                              _buildActivityGraph(l10n),
                              _buildEventLog(l10n),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ),
          );
        } else {
          // Mobile Layout (legacy)
          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.greetingsList.split('|')[_greetingIndex],
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.subGreetingsList.split('|')[_subGreetingIndex],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _profilePicBytes != null
                                ? MemoryImage(_profilePicBytes!)
                                : null,
                            child: _profilePicBytes == null
                                ? Icon(
                                    _getPetIcon(_petType),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayPetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                HighlightCard(
                  serverIp: widget.serverIp,
                  token: widget.token,
                ),
                _buildCameraCard(l10n, false),
                const SizedBox(height: 24),

                _buildInsightsEntry(l10n),
                _buildActivityGraph(l10n),

                // Activities Timeline
                Text(
                  l10n.activities,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                if (_activities.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        l10n.noRecentEvents,
                        style: const TextStyle(color: AppColors.outline),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final ev = _activities[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        (ev['timestamp'] * 1000).toInt(),
                      );
                      final timeString =
                          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                      final (icon, color, title, subtitle) = _eventDisplay(
                        ev,
                        l10n,
                      );

                      return _buildTimelineItem(
                        icon,
                        color,
                        title,
                        subtitle,
                        timeString,
                        isLast: index == _activities.length - 1,
                      );
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
            ),
          );
        }
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String unit,
    String label,
    Color bgColor,
    Color iconColor, {
    bool showToday = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (showToday)
                Text(
                  l10n.today,
                  style: const TextStyle(
                    color: AppColors.outline,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(
                    " $unit",
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.outline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.outline, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    String time, {
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.outline,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _getFavoriteZone() {
    if (_activities.isEmpty) return "--";
    final zoneCounts = <String, int>{};
    for (var act in _activities) {
      if (act['zone_name'] != null) {
        zoneCounts[act['zone_name']] = (zoneCounts[act['zone_name']] ?? 0) + 1;
      }
    }
    if (zoneCounts.isEmpty) return "-";
    final fav = zoneCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return fav.length > 8 ? '${fav.substring(0, 8)}...' : fav;
  }

  // ignore: unused_element
  String _getLastSeen(AppLocalizations l10n) {
    if (_activities.isEmpty) return "-";
    final lastEv = _activities.first;
    if (lastEv['timestamp'] == null) return "-";

    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch((lastEv['timestamp'] * 1000).toInt()),
    );
    if (diff.inMinutes == 0) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minsAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }
}
