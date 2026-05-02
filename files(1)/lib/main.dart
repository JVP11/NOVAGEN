// ============================================================
// main.dart — NovaGen SafeInk Scanner
//
// Boots the app, locks portrait, requests permissions, preloads
// available cameras (faster hop into the SafeInk tab), applies
// the NovaGen theme, and lands on [HomeScreen].
// ============================================================

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_theme.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';

/// Preloaded cameras (also used by named `/scanner` route).
List<CameraDescription> kGlobalCameras = <CameraDescription>[];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Mobile: runtime permissions for camera + in-use location (GPS screen).
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();
  }

  try {
    kGlobalCameras = await availableCameras();
  } catch (_) {
    kGlobalCameras = <CameraDescription>[];
  }

  runApp(const NovaGenSafeInkApp());
}

class NovaGenSafeInkApp extends StatelessWidget {
  const NovaGenSafeInkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NovaGen SafeInk Scanner',
      debugShowCheckedModeBanner: false,
      theme: novagenDarkTheme(),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (_) => HomeScreen(cameras: kGlobalCameras),
        '/scanner': (_) => ScannerScreen(cameras: kGlobalCameras),
      },
    );
  }
}
