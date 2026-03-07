import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class ZegoService extends ChangeNotifier {
  // Singleton instance
  static final ZegoService _instance = ZegoService._internal();
  factory ZegoService() => _instance;
  ZegoService._internal();

  // Zego Credentials - REPLACE THESE WITH YOUR OWN FROM ZEGO CONSOLE
  // Sign up at https://console.zegocloud.com/
  final int appID = 341179331; 
  final String appSign = "db22c1ed05e7f778e4624f656d96a252540090fcb20a3b0bec014bf2c1ddc599"; 
  final bool isTestEnv = true; // Use test environment

  bool _isEngineInitialized = false;
  bool _isInRoom = false;
  bool _isMicOn = true;
  bool _isSpeakerOn = true;

  // Getters
  bool get isInRoom => _isInRoom;
  bool get isMicOn => _isMicOn;
  bool get isSpeakerOn => _isSpeakerOn;

  // Initialize the Zego Engine
  Future<void> init() async {
    if (_isEngineInitialized) return;

    // Request permissions first
    await [Permission.microphone].request();

    // Create engine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        appID,
        ZegoScenario.StandardVoiceCall,
        appSign: kIsWeb ? null : appSign, // Web doesn't use AppSign
      ),
    );

    _isEngineInitialized = true;
    debugPrint("Zego Engine Initialized");

    // Set up event listeners
    ZegoExpressEngine.onRoomStateChanged = (
      String roomID,
      ZegoRoomStateChangedReason reason,
      int errorCode,
      Map<String, dynamic> extendedData,
    ) {
      debugPrint("Zego Room State Reason: $reason, Error: $errorCode");
      if (reason == ZegoRoomStateChangedReason.Logined ||
          reason == ZegoRoomStateChangedReason.Reconnected) {
        _isInRoom = true;
        notifyListeners();
      } else if (reason == ZegoRoomStateChangedReason.Logout ||
          reason == ZegoRoomStateChangedReason.KickOut) {
        _isInRoom = false;
        notifyListeners();
      }
    };
  }

  // Join a room
  Future<void> joinRoom(String roomID, String userID, String userName) async {
    if (!_isEngineInitialized) await init();

    ZegoUser user = ZegoUser(userID, userName);
    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    config.isUserStatusNotify = true;

    await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
    debugPrint("Zego: Joining room $roomID as $userName");

    // Default to publishing audio if joining
    await startPublishingStream(userID);
  }

  // Leave the room
  Future<void> leaveRoom() async {
    if (!_isInRoom) return;
    await ZegoExpressEngine.instance.logoutRoom();
    _isInRoom = false;
    notifyListeners();
  }

  // Start publishing audio (turn on mic)
  Future<void> startPublishingStream(String streamID) async {
    await ZegoExpressEngine.instance.startPublishingStream(streamID);
    _isMicOn = true;
    notifyListeners();
  }

  // Stop publishing audio
  Future<void> stopPublishingStream() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
    _isMicOn = false;
    notifyListeners();
  }

  // Toggle Microphone
  Future<void> toggleMic() async {
    _isMicOn = !_isMicOn;
    await ZegoExpressEngine.instance.muteMicrophone(!_isMicOn);
    notifyListeners();
  }

  // Toggle Speaker
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await ZegoExpressEngine.instance.muteSpeaker(!_isSpeakerOn);
    notifyListeners();
  }

  // Destroy engine
  Future<void> destroy() async {
    await ZegoExpressEngine.destroyEngine();
    _isEngineInitialized = false;
    _isInRoom = false;
  }
}
