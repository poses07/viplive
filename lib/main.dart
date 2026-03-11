import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/splash_screen.dart';
import 'providers/user_provider.dart';
// import 'services/zego_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // ChangeNotifierProvider(create: (_) => ZegoService()),
      ],
      child: const VipLiveApp(),
    ),
  );
}

class VipLiveApp extends StatelessWidget {
  const VipLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipLive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF66B4FF)),
        useMaterial3: true,
      ),
      home: const PermissionCheckWrapper(child: SplashScreen()),
    );
  }
}

class PermissionCheckWrapper extends StatefulWidget {
  final Widget child;
  const PermissionCheckWrapper({super.key, required this.child});

  @override
  State<PermissionCheckWrapper> createState() => _PermissionCheckWrapperState();
}

class _PermissionCheckWrapperState extends State<PermissionCheckWrapper> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request Camera and Microphone permissions at app start
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
