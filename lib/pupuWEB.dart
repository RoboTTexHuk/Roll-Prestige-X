import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tzd;
import 'package:timezone/timezone.dart' as tzu;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart'
    show AppTrackingTransparency, TrackingStatus;
import 'package:appsflyer_sdk/appsflyer_sdk.dart'
    show AppsFlyerOptions, AppsflyerSdk;

import 'main.dart' show CrazyUniWebPage, ChubbyTokenInitPage, GalaxyPortalView, HorizonSetupView, QuantumWebWatermelon;

// --- MVVM/Provider слои ---

// Модель-комета
class CometHardwareData {
  final String? cometCoreId;
  final String? nebulaCluster;
  final String? systemFramework;
  final String? systemRelease;
  final String? appBuildNumber;
  final String? userDialect;
  final String? galaxyZone;
  final bool alertActivation;

  CometHardwareData({
    this.cometCoreId,
    this.nebulaCluster,
    this.systemFramework,
    this.systemRelease,
    this.appBuildNumber,
    this.userDialect,
    this.galaxyZone,
    required this.alertActivation,
  });

  Map<String, dynamic> toDataMap({String? signalBeacon}) => {
    "fcm_token": signalBeacon ?? "no_fcm_token",
    "device_id": cometCoreId ?? 'no_penguin',
    "app_name": "rollprestigex",
    "instance_id": nebulaCluster ?? 'no_iceberg',
    "platform": systemFramework ?? 'no_type',
    "os_version": systemRelease ?? 'no_os',
    "app_version": appBuildNumber ?? 'no_app',
    "language": userDialect ?? 'en',
    "timezone": galaxyZone ?? 'UTC',
    "push_enabled": alertActivation,
  };
}

// Репозиторий-Космос
class CosmosDataVault {
  Future<CometHardwareData> retrieveCometStats() async {
    final hardwareScanner = DeviceInfoPlugin();
    String? cometCoreId, systemFramework, systemRelease;
    if (Platform.isAndroid) {
      final stats = await hardwareScanner.androidInfo;
      cometCoreId = stats.id;
      systemFramework = "android";
      systemRelease = stats.version.release;
    } else if (Platform.isIOS) {
      final stats = await hardwareScanner.iosInfo;
      cometCoreId = stats.identifierForVendor;
      systemFramework = "ios";
      systemRelease = stats.systemVersion;
    }
    final appMeta = await PackageInfo.fromPlatform();
    final userDialect = Platform.localeName.split('_')[0];
    final galaxyZone = tzu.local.name;

    return CometHardwareData(
      cometCoreId: cometCoreId ?? 'no_penguin',
      nebulaCluster: "iceberg-${DateTime.now().millisecondsSinceEpoch}",
      systemFramework: systemFramework ?? 'unknown',
      systemRelease: systemRelease ?? 'unknown',
      appBuildNumber: appMeta.version,
      userDialect: userDialect,
      galaxyZone: galaxyZone,
      alertActivation: true,
    );
  }
}

// ViewModel-Метеор (логика для данных)
class MeteorLogicHub extends ChangeNotifier {
  CometHardwareData? celestialBody;
  Future<void> gatherCometDetails() async {
    celestialBody = await CosmosDataVault().retrieveCometStats();
    notifyListeners();
  }
}

// ViewModel для сигналов
class NebulaSignalCore extends ChangeNotifier {
  String? orbitSignal;
  bool isInTransit = true;

  Future<void> acquireOrbitSignal() async {
    FirebaseMessaging signalHub = FirebaseMessaging.instance;
    await signalHub.requestPermission(alert: true, badge: true, sound: true);
    orbitSignal = await signalHub.getToken();
    isInTransit = false;
    notifyListeners();
  }
}

// ViewModel для аналитики
class StarshipTrackModule extends ChangeNotifier {
  AppsflyerSdk? _starshipEngine;
  String starshipCode = "";
  String starshipMetrics = "";

  void launchStarshipTracker(VoidCallback onSync) {
    final configParams = AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6748404377",
      showDebug: true,
    );
    _starshipEngine = AppsflyerSdk(configParams);
    _starshipEngine?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _starshipEngine?.startSDK(
      onSuccess: () => print("Squid Analytics swim!"),
      onError: (int code, String msg) => print("Squid error $code $msg"),
    );
    _starshipEngine?.onInstallConversionData((result) {
      starshipMetrics = result.toString();
      onSync();
    });
    _starshipEngine?.getAppsFlyerUID().then((val) {
      starshipCode = val.toString();
      onSync();
    });
  }
}

// ViewModel-квазар для ATT
class QuasarPrivacyUnit extends ChangeNotifier {
  TrackingStatus privacyLevel = TrackingStatus.notDetermined;
  String uniqueMarker = "";

  Future<void> initiatePrivacyCheck() async {
    privacyLevel = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (privacyLevel == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await AppTrackingTransparency.requestTrackingAuthorization();
      privacyLevel = await AppTrackingTransparency.trackingAuthorizationStatus;
    }
    uniqueMarker = await AppTrackingTransparency.getAdvertisingIdentifier();
    notifyListeners();
  }
}

// ---------- WIDGET+MVVM Вебвью (GalaxyStreamPortal) -----------

class GalaxyStreamPortal extends StatelessWidget {
  final String endpointPath;
  const GalaxyStreamPortal(this.endpointPath, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeteorLogicHub()..gatherCometDetails()),
        ChangeNotifierProvider(create: (_) => NebulaSignalCore()..acquireOrbitSignal()),
        ChangeNotifierProvider(create: (_) => StarshipTrackModule()..launchStarshipTracker(() {})),
        ChangeNotifierProvider(create: (_) => QuasarPrivacyUnit()..initiatePrivacyCheck()),
      ],
      child: _GalaxyStreamInterface(endpointPath: endpointPath),
    );
  }
}

class _GalaxyStreamInterface extends StatefulWidget {
  final String endpointPath;
  const _GalaxyStreamInterface({required this.endpointPath});

  @override
  State<_GalaxyStreamInterface> createState() => _GalaxyStreamInterfaceState();
}

class _GalaxyStreamInterfaceState extends State<_GalaxyStreamInterface> with WidgetsBindingObserver {
  late InAppWebViewController _starfieldNavigator;
  bool _isProcessing = false;
  final List<ContentBlocker> _signalFilters = [];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  Future<void> fetchAndUseInstanceId() async {
    final cometLogic = context.read<MeteorLogicHub>();
    await cometLogic.gatherCometDetails(); // Убедитесь, что данные загружены
    if (cometLogic.celestialBody != null) {
      String instanceId = cometLogic.celestialBody!.nebulaCluster ?? 'default_instance_id';
      print("Using Instance ID: $instanceId");
      // Здесь можно использовать instanceId, например, передать в WebView или логи
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchAndUseInstanceId();

    _configureAlertChannel2();
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _redirectToDestination(msg.data['uri'].toString());
      } else {
        _revertToOrigin();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      if (msg.data['uri'] != null) {
        _redirectToDestination(msg.data['uri'].toString());
      } else {
        _revertToOrigin();
      }
    });

    Future.delayed(const Duration(seconds: 6), () {
      _transmitStarshipData();
    });
  }

  void _configureAlertChannel2() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(call.arguments);
        final targetUrl = payload["uri"];
        if (targetUrl != null && !targetUrl.contains("No URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => GalaxyStreamPortal(targetUrl)),
                (route) => false,
          );
        }
      }
    });
  }

  void _redirectToDestination(String targetUri) async {
    await _starfieldNavigator.loadUrl(urlRequest: URLRequest(url: WebUri(targetUri)));
  }

  void _revertToOrigin() async {
    Future.delayed(const Duration(seconds: 3), () {
      _starfieldNavigator.loadUrl(urlRequest: URLRequest(url: WebUri(widget.endpointPath)));
    });
  }

  Future<void> _transmitStarshipData() async {
    final cometLogic = context.read<MeteorLogicHub>();
    final starshipLogic = context.read<StarshipTrackModule>();

    if (cometLogic.celestialBody == null) return;

    final payload = {
      "content": {
        "af_data": starshipLogic.starshipMetrics,
        "af_id": starshipLogic.starshipCode,
        "fb_app_name": "rollprestigex",
        "app_name": "rollprestigex",
        "deep": null,
        "bundle_identifier": "com.ghipxo.rollprestigex.rollprestigex",
        "app_version": "1.0.0",
        "apple_id": "6748404377",
        "device_id": cometLogic.celestialBody!.cometCoreId ?? "default_device_id",
        "instance_id": cometLogic.celestialBody!.nebulaCluster ?? "default_instance_id",
        "platform": cometLogic.celestialBody!.systemFramework ?? "unknown_platform",
        "os_version": cometLogic.celestialBody!.systemRelease ?? "default_os_version",
        "app_version": cometLogic.celestialBody!.appBuildNumber ?? "default_app_version",
        "language": cometLogic.celestialBody!.userDialect ?? "en",
        "timezone": cometLogic.celestialBody!.galaxyZone ?? "UTC",
        "push_enabled": cometLogic.celestialBody!.alertActivation,
        "useruid": starshipLogic.starshipCode,
      },
    };
    final encodedPayload = jsonEncode(payload);
    print("SUSHI SQUID JSON $encodedPayload");
    await _starfieldNavigator.evaluateJavascript(
      source: "sendRawData(${jsonEncode(encodedPayload)});",
    );
  }

  DateTime? _suspendedMoment;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _suspendedMoment = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS && _suspendedMoment != null) {
        final currentTime = DateTime.now();
        final backgroundSpan = currentTime.difference(_suspendedMoment!);
        if (backgroundSpan > const Duration(minutes: 25)) {
          _initiateReconstruction();
        }
      }
      _suspendedMoment = null;
    }
  }

  void _initiateReconstruction() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HorizonSetupView(),
        ),
            (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _configureAlertChannel2();
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              disableDefaultErrorPage: true,
              mediaPlaybackRequiresUserGesture: true,
              allowsInlineMediaPlayback: true,
              allowsPictureInPictureMediaPlayback: true,
              useOnDownloadStart: true,
              supportZoom: true,
              contentBlockers: _signalFilters,
              javaScriptCanOpenWindowsAutomatically: true,
            ),
            initialUrlRequest: URLRequest(url: WebUri(widget.endpointPath)),
            onWebViewCreated: (controller) {
              _starfieldNavigator = controller;
              _starfieldNavigator.addJavaScriptHandler(
                  handlerName: 'onServerResponse',
                  callback: (args) {
                    print("🐟 JS args: $args");
                    return args.reduce((curr, next) => curr + next);
                  });
            },
            onLoadStop: (controller, url) async {
              await controller.evaluateJavascript(source: "console.log('Hello from JS!');");
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}