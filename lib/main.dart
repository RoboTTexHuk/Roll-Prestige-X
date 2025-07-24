import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart' show AppTrackingTransparency, TrackingStatus;
import 'package:appsflyer_sdk/appsflyer_sdk.dart' show AppsFlyerOptions, AppsflyerSdk;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:rollprestigex/pupuWEB.dart' show GalaxyStreamPortal;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:widget_loading/widget_loading.dart' show CircularWidgetLoading;

// Регистрация зависимостей через GetIt
final sl = GetIt.instance;

void setupDependencies() {
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingleton<Logger>(Logger());
  sl.registerSingleton<Connectivity>(Connectivity());
}

// Перечисление для событий трекинга
enum NebulaTrackEvent { initiate }
enum NebulaTrackState { initial, approved, rejected, processing }

// Класс для управления состоянием трекинга
class CosmicAuthBloc extends Bloc<NebulaTrackEvent, NebulaTrackState> {
  CosmicAuthBloc() : super(NebulaTrackState.initial) {
    on<NebulaTrackEvent>((event, emit) async {
      if (event == NebulaTrackEvent.initiate) {
        emit(NebulaTrackState.processing);
        try {
          await AppTrackingTransparency.requestTrackingAuthorization();
          final result = await AppTrackingTransparency.trackingAuthorizationStatus;
          emit(result == TrackingStatus.authorized ? NebulaTrackState.approved : NebulaTrackState.rejected);
        } catch (e) {
          emit(NebulaTrackState.rejected);
        }
      }
    });
  }
}

// Класс для управления сетевыми запросами
class VortexNetworkManager {
  Future<bool> checkConnectivity() async {
    var connectivityResult = await sl<Connectivity>().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> sendData(String url, Map<String, dynamic> data) async {
    try {
      await http.post(Uri.parse(url), body: jsonEncode(data));
    } catch (e) {
      sl<Logger>().e("Network error: $e");
    }
  }
}

// Точка входа приложения
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_shadowMessageProcessor);

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  tzData.initializeTimeZones();

  final storage = await SharedPreferences.getInstance();
  final bool hasSeenAuth = storage.getBool('auth_viewed') ?? false;

  runApp(
    MaterialApp(
      home: BlocProvider(
        create: (_) => CosmicAuthBloc(),
        child: hasSeenAuth ? const HorizonSetupView() : const StarlightAuthView(),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

// Экран для авторизации трекинга
class StarlightAuthView extends StatefulWidget {
  const StarlightAuthView({super.key});

  @override
  State<StarlightAuthView> createState() => _StarlightAuthViewState();
}

class _StarlightAuthViewState extends State<StarlightAuthView> {
  Future<void> _markAuthViewed() async {
    final storage = await SharedPreferences.getInstance();
    await storage.setBool('auth_viewed', true);
  }
@override
  void initState() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black, // Черный фон статус-бара
    statusBarIconBrightness: Brightness.light, // Белые иконки в статус-баре (для Android)
    statusBarBrightness: Brightness.dark, // Для iOS: темный фон, белые иконки
  ));
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CosmicAuthBloc, NebulaTrackState>(
      listener: (context, state) async {
        if (state == NebulaTrackState.approved || state == NebulaTrackState.rejected) {
          await _markAuthViewed();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HorizonSetupView()),
          );
        }
      },
      builder: (context, state) {
        if (state == NebulaTrackState.processing) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Container(
              width: 350,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info, size: 56, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Why do we need tracking access?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Your data helps us tailor ads, offers, and bonuses to your interests. We might show relevant discounts or game reminders. Your information is never sold or shared for unrelated purposes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.amber, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<CosmicAuthBloc>().add(NebulaTrackEvent.initiate);
                      },
                      child: const Text('Proceed'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can update this choice in your device settings anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Экран инициализации уведомлений
class HorizonSetupView extends StatefulWidget {
  const HorizonSetupView({Key? key}) : super(key: key);
  @override
  State<HorizonSetupView> createState() => _HorizonSetupViewState();
}

class _HorizonSetupViewState extends State<HorizonSetupView> {
  final AuroraSignalManager _signalManager = AuroraSignalManager();
  bool _hasNavigated = false;
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Черный фон статус-бара
      statusBarIconBrightness: Brightness.light, // Белые иконки в статус-баре (для Android)
      statusBarBrightness: Brightness.dark, // Для iOS: темный фон, белые иконки
    ));
    _signalManager.listenForSignal((signal) {
      _transition(signal);
    });
    _expiryTimer = Timer(const Duration(seconds: 8), () {
      _transition('');
    });
  }

  void _transition(String signal) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _expiryTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GalaxyPortalView(signalKey: signal),
      ),
    );
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: SizedBox(

          child: Center(child: _AnimatedDotsText()),
        ),
      ),
    );
  }
}

// Класс для управления сигналами уведомлений
class AuroraSignalManager extends ChangeNotifier {
  String? _signalValue;

  void listenForSignal(Function(String signal) onSignal) {
    const MethodChannel('com.example.fcm/token')
        .setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String signal = call.arguments as String;
        onSignal(signal);
      }
    });
  }
}

// Класс для управления данными устройства
class QuantumDeviceHub {
  String? gadgetIdentifier;
  String? sessionMarker = "unique-session-mark";
  String? systemType;
  String? systemBuild;
  String? appBuild;
  String? userLocale;
  String? regionZone;
  bool alertsActive = true;

  Future<void> configureDevice() async {
    final gadgetInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final data = await gadgetInfo.androidInfo;
      gadgetIdentifier = data.id;
      systemType = "android";
      systemBuild = data.version.release;
    } else if (Platform.isIOS) {
      final data = await gadgetInfo.iosInfo;
      gadgetIdentifier = data.identifierForVendor;
      systemType = "ios";
      systemBuild = data.systemVersion;
    }
    final appInfo = await PackageInfo.fromPlatform();
    appBuild = appInfo.version;
    userLocale = Platform.localeName.split('_')[0];
    regionZone = tz.local.name;

    // Генерация уникального instance_id (sessionMarker) на основе временной метки
    sessionMarker = "session-${DateTime.now().millisecondsSinceEpoch}";
  }

  Map<String, dynamic> toDataPacket({String? alertToken}) {
    return {
      "fcm_token": alertToken ?? 'missing_token',
      "device_id": gadgetIdentifier ?? 'missing_id',
      "app_name": "rollprestigex",
      "instance_id": sessionMarker ?? 'missing_session',
      "platform": systemType ?? 'missing_system',
      "os_version": systemBuild ?? 'missing_build',
      "app_version": appBuild ?? 'missing_app',
      "language": userLocale ?? 'en',
      "timezone": regionZone ?? 'UTC',
      "push_enabled": alertsActive,
    };
  }
}
// Класс для управления аналитикой
class StellarTrackHub extends ChangeNotifier {
  AppsflyerSdk? _trackEngine;
  String trackIdentity = "";
  String trackMetrics = "";

  void activateTracking(VoidCallback onRefresh) {
    final config = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6748404377",
      showDebug: true,
    );
    _trackEngine = AppsflyerSdk(config);
    _trackEngine?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _trackEngine?.startSDK(
      onSuccess: () => sl<Logger>().i("Tracking initialized"),
      onError: (int code, String msg) => sl<Logger>().e("Tracking error $code: $msg"),
    );
    _trackEngine?.onInstallConversionData((result) {
      trackMetrics = result.toString();
      onRefresh();
    });
    _trackEngine?.getAppsFlyerUID().then((val) {
      trackIdentity = val.toString();
      onRefresh();
    });
  }
}

// Главный экран с веб-виджетом
class GalaxyPortalView extends StatefulWidget {
  final String? signalKey;
  const GalaxyPortalView({super.key, required this.signalKey});

  @override
  State<GalaxyPortalView> createState() => _GalaxyPortalViewState();
}

class _GalaxyPortalViewState extends State<GalaxyPortalView> with WidgetsBindingObserver {
  late InAppWebViewController _portalEngine;
  bool _isFetching = false;
  final String _coreEndpoint = "https://rollprestigex.cfd/";
  final QuantumDeviceHub _gadgetHub = QuantumDeviceHub();
  final StellarTrackHub _analyticsHub = StellarTrackHub();
  int _portalInstanceId = 0;
  DateTime? _suspendedAt;
  bool _displayPortal = false;
  double _progressValue = 0.0;
  late Timer _progressTimer;
  final int _waitDuration = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Черный фон статус-бара
      statusBarIconBrightness: Brightness.light, // Белые иконки в статус-баре (для Android)
      statusBarBrightness: Brightness.dark, // Для iOS: темный фон, белые иконки
    ));
    Future.delayed(const Duration(seconds: 9), () {
      setState(() {
        _displayPortal = true;
      });
    });

    _beginSetup();
  }

  void _beginSetup() {
    _initiateProgress();
    _configureAlertSystem();
    _setupPrivacyAuth();
    _analyticsHub.activateTracking(() => setState(() {}));
    _configureAlertChannel();
    _initializeGadget();
    Future.delayed(const Duration(seconds: 2), _setupPrivacyAuth);
    Future.delayed(const Duration(seconds: 6), () {
      _transmitGadgetInfo();
      _transmitAnalyticsInfo();
    });
  }

  void _configureAlertSystem() {
    FirebaseMessaging.onMessage.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _navigateToLink(link.toString());
      } else {
        _refreshCorePortal();
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _navigateToLink(link.toString());
      } else {
        _refreshCorePortal();
      }
    });
  }

  void _configureAlertChannel() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        final url =payload["uri"];
        // Проверяем, что "uri" реально есть в payload
        if (url != null && !url.contains("Нет URI")) {
          final targetUrl = payload["uri"];
          // Можно добавить доп.проверку, что uri не пустой
          if (targetUrl != null && targetUrl.toString().isNotEmpty) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => GalaxyStreamPortal(targetUrl)),
                  (route) => false,
            );
          }
        }
      }
    });
  }

  Future<void> _initializeGadget() async {
    try {
      await _gadgetHub.configureDevice();
      await _initAlertMessaging();
      if (_portalEngine != null) {
        _transmitGadgetInfo();
      }
    } catch (e) {
      sl<Logger>().e("Gadget initialization failed: $e");
    }
  }

  Future<void> _initAlertMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupPrivacyAuth() async {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    sl<Logger>().i("ATT AdvertisingIdentifier: $uuid");
  }

  void _navigateToLink(String link) async {
    if (_portalEngine != null) {
      await _portalEngine.loadUrl(urlRequest: URLRequest(url: WebUri(link)));
    }
  }

  void _refreshCorePortal() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (_portalEngine != null) {
        _portalEngine.loadUrl(urlRequest: URLRequest(url: WebUri(_coreEndpoint)));
      }
    });
  }

  Future<void> _transmitGadgetInfo() async {
    setState(() => _isFetching = true);
    try {
      final gadgetData = _gadgetHub.toDataPacket(alertToken: widget.signalKey);

      print("LStorage "+jsonEncode(gadgetData));
      await _portalEngine.evaluateJavascript(source: '''
      localStorage.setItem('app_data', JSON.stringify(${jsonEncode(gadgetData)}));
      ''');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  Future<void> _transmitAnalyticsInfo() async {
    final data = {
      "content": {
        "af_data": _analyticsHub.trackMetrics,
        "af_id": _analyticsHub.trackIdentity,
        "fb_app_name": "rollprestigex",
        "app_name": "rollprestigex",
        "deep": null,
        "bundle_identifier": "com.ghipxo.rollprestigex.rollprestigex",
        "app_version": "1.0.0",
        "apple_id": "6748404377",
        "fcm_token": widget.signalKey ?? "no_token",
        "device_id": _gadgetHub.gadgetIdentifier ?? "no_device",
        "instance_id": _gadgetHub.sessionMarker ?? "no_instance",
        "platform": _gadgetHub.systemType ?? "no_type",
        "os_version": _gadgetHub.systemBuild ?? "no_os",
        "app_version": _gadgetHub.appBuild ?? "no_app",
        "language": _gadgetHub.userLocale ?? "en",
        "timezone": _gadgetHub.regionZone ?? "UTC",
        "push_enabled": _gadgetHub.alertsActive,
        "useruid": _analyticsHub.trackIdentity,
      },
    };
    print("Load UR "+data.toString());
    final jsonString = jsonEncode(data);
    sl<Logger>().i("SendRawData: $jsonString");

    await _portalEngine.evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonString)});",
    );
  }



  void _initiateProgress() {
    int counter = 0;
    _progressValue = 0.0;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        counter++;
        _progressValue = counter / (_waitDuration * 10);
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          _progressTimer.cancel();
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _suspendedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS && _suspendedAt != null) {
        final now = DateTime.now();
        final backgroundDuration = now.difference(_suspendedAt!);
        if (backgroundDuration > const Duration(minutes: 25)) {
          _forcePortalRebuild();
        }
      }
      _suspendedAt = null;
    }
  }

  void _forcePortalRebuild() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => GalaxyPortalView(signalKey: widget.signalKey),
        ),
            (route) => false,
      );
    });
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _configureAlertChannel();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            InAppWebView(
              key: ValueKey(_portalInstanceId),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                disableDefaultErrorPage: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                allowsPictureInPictureMediaPlayback: true,
                useOnDownloadStart: true,
                javaScriptCanOpenWindowsAutomatically: true,
              ),
              initialUrlRequest: URLRequest(url: WebUri(_coreEndpoint)),
              onWebViewCreated: (controller) {
                _portalEngine = controller;
                _portalEngine.addJavaScriptHandler(
                  handlerName: 'onGatewayReply',
                  callback: (args) {
                    sl<Logger>().i("JS response: $args");
                    return args.reduce((curr, next) => curr + next);
                  },
                );
              },
              onLoadStart: (controller, url) {
                setState(() => _isFetching = true);
              },
              onLoadStop: (controller, url) async {

                print("Load URL: "+url.toString());
                await controller.evaluateJavascript(
                  source: "console.log('Portal loaded!');",
                );
                await _transmitGadgetInfo();
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
            ),
            Visibility(
              visible: !_displayPortal,
              child: SizedBox.expand(
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularWidgetLoading(
                          loading: true,
                          dotRadius: 10.0, // Увеличен радиус для видимости
                          dotColor: Colors.amber, // Яркий желтый цвет для контраста
                          dotCount: 8,
                          loadingDuration: const Duration(milliseconds: 8000),
                          child: const SizedBox.shrink(),
                        ),
                        _AnimatedDotsText(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Класс для обработки фоновых сообщений
@pragma('vm:entry-point')
Future<void> _shadowMessageProcessor(RemoteMessage message) async {
  sl<Logger>().i("Background alert: ${message.messageId}");
  sl<Logger>().i("Background payload: ${message.data}");
}

class _AnimatedDotsText extends StatefulWidget {
  const _AnimatedDotsText();

  @override
  __AnimatedDotsTextState createState() => __AnimatedDotsTextState();
}

class __AnimatedDotsTextState extends State<_AnimatedDotsText> {
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Обновляем количество точек каждые 500 миллисекунд
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // Цикл от 0 до 3
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Отменяем таймер при уничтожении виджета
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String dots = '.' * _dotCount; // Создаем строку с нужным количеством точек
    return Text(
      "Loading$dots",
      style: const TextStyle(
        color: Colors.amber,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

