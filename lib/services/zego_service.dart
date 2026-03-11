import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_zim/zego_zim.dart'; // Import ZIM
import '../utils/zego_token_manager.dart'; // Import token manager

class ZegoService with ChangeNotifier {
  static final ZegoService _instance = ZegoService._internal();
  factory ZegoService() => _instance;
  ZegoService._internal();

  final int appID = 341179331;
  final String appSign =
      'db22c1ed05e7f778e4624f656d96a252540090fcb20a3b0bec014bf2c1ddc599';
  bool _isEngineCreated = false;

  // State
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isInRoom = false;
  String? currentRoomId;

  // Stream tracking
  List<ZegoUser> remoteUsers = [];
  Map<String, double> soundLevels = {}; // Map<UserID, Level>

  Future<void> initEngine() async {
    if (_isEngineCreated) return;

    // Create Engine
    // Use Default for maximum compatibility
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(appID, ZegoScenario.Default, appSign: appSign),
    );

    _isEngineCreated = true;

    // Set Audio Configuration
    ZegoAudioConfig audioConfig = ZegoAudioConfig.preset(
      ZegoAudioConfigPreset.StandardQuality,
    );
    await ZegoExpressEngine.instance.setAudioConfig(audioConfig);

    // Advanced Audio Processing (Noise Suppression & Echo Cancellation)
    // Enable ANS (Acoustic Noise Suppression)
    await ZegoExpressEngine.instance.enableANS(true);
    // Enable AEC (Acoustic Echo Cancellation)
    await ZegoExpressEngine.instance.enableAEC(true);
    // Enable AGC (Automatic Gain Control)
    await ZegoExpressEngine.instance.enableAGC(true);

    // Force Audio to Speaker (Important for Live Streaming)
    await ZegoExpressEngine.instance.setAudioRouteToSpeaker(true);

    // Enable sound level monitoring
    await ZegoExpressEngine.instance.startSoundLevelMonitor();

    // Initialize ZIM (Instant Messaging)
    await _initZIM();

    _registerEventHandlers();
    debugPrint("Zego Engine Created");
  }

  Future<void> _initZIM() async {
    ZIMAppConfig appConfig = ZIMAppConfig();
    appConfig.appID = appID;
    appConfig.appSign = appSign;
    await ZIM.getInstance()!.create(appConfig);
    debugPrint("ZIM Engine Created");
  }

  void _registerEventHandlers() {
    // Sound Level Handler
    ZegoExpressEngine.onCapturedSoundLevelUpdate = (soundLevel) {
      // Local user sound level
      // We can use this to show wave animation for self
      // notifyListeners(); // Only notify if we track self level
    };

    ZegoExpressEngine.onRemoteSoundLevelUpdate = (soundLevels) {
      // Remote users sound level
      // We are just storing and notifying, no specific logic needed here yet
      this.soundLevels = soundLevels;
      notifyListeners();
    };

    ZegoExpressEngine.onRoomStateChanged = (
      roomID,
      reason,
      errorCode,
      extendedData,
    ) {
      debugPrint(
        "onRoomStateChanged: $roomID, reason: $reason, error: $errorCode",
      );
      if (reason == ZegoRoomStateChangedReason.Logined) {
        isInRoom = true;
        currentRoomId = roomID;
        notifyListeners();
      } else if (reason == ZegoRoomStateChangedReason.Logout) {
        isInRoom = false;
        currentRoomId = null;
        remoteUsers.clear();
        notifyListeners();
      }
    };

    ZegoExpressEngine.onRoomUserUpdate = (roomID, updateType, userList) {
      debugPrint("onRoomUserUpdate: $updateType, users: ${userList.length}");
      if (updateType == ZegoUpdateType.Add) {
        remoteUsers.addAll(userList);
      } else {
        for (var user in userList) {
          remoteUsers.removeWhere((u) => u.userID == user.userID);
        }
      }
      notifyListeners();
    };

    // Auto-Play Streams
    ZegoExpressEngine.onRoomStreamUpdate = (
      roomID,
      updateType,
      streamList,
      extendedData,
    ) {
      if (updateType == ZegoUpdateType.Add) {
        for (var stream in streamList) {
          // Play stream automatically (audio only by default unless view is set later)
          ZegoExpressEngine.instance.startPlayingStream(stream.streamID);
          // Ensure we are playing audio for this stream
          ZegoExpressEngine.instance.mutePlayStreamAudio(
            stream.streamID,
            false,
          );
        }
      } else {
        for (var stream in streamList) {
          ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        }
      }
    };
  }

  Future<void> loginRoom(
    String roomID,
    String userID,
    String userName, {
    bool isHost = false,
  }) async {
    await initEngine();

    ZegoUser user = ZegoUser(userID, userName);
    ZegoRoomConfig config = ZegoRoomConfig.defaultConfig();
    config.isUserStatusNotify = true;

    // Generate Token
    String token = ZegoTokenUtils.generateToken(
      appId: appID,
      serverSecret:
          "aef6a32ad60b7ed6142567bafc312cd2", // Should be in env or remote config
      userId: userID,
    );
    debugPrint("Generated Token for $userID: $token");
    config.token = token;

    // Login ZIM
    ZIMUserInfo zimUser = ZIMUserInfo();
    zimUser.userID = userID;
    zimUser.userName = userName;
    await ZIM.getInstance()!.login(zimUser, token);
    debugPrint("Logged into ZIM as $userID");

    await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
    debugPrint("Logging into room: $roomID as $userID with token");

    // Default settings
    isMicOn = true;
    isCameraOn = isHost; // Host starts with camera, audience without

    if (isHost) {
      // Start Preview and Publishing immediately for Host
      await ZegoExpressEngine.instance.startPreview();
      await startPublishingStream("${roomID}_host");
    }
  }

  // Stream Management
  Future<void> startPublishingStream(
    String streamID, {
    bool video = true,
  }) async {
    // 1. Ensure audio device is enabled
    await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);

    // 2. Ensure camera is enabled/disabled
    await ZegoExpressEngine.instance.enableCamera(video);

    // 3. Unmute Microphone (Software mute)
    await ZegoExpressEngine.instance.muteMicrophone(false);

    // 4. Set Audio Source (Default: Microphone)
    await ZegoExpressEngine.instance.setAudioSource(
      ZegoAudioSourceType.Microphone,
    );

    // 5. Start Publishing
    await ZegoExpressEngine.instance.startPublishingStream(streamID);

    isMicOn = true;
    isCameraOn = video;
    notifyListeners();
  }

  Future<void> stopPublishingStream() async {
    await ZegoExpressEngine.instance.stopPublishingStream();
    notifyListeners();
  }

  Future<void> logoutRoom() async {
    if (!isInRoom) return;
    await stopPublishingStream();
    await ZegoExpressEngine.instance.stopPreview();
    await ZegoExpressEngine.instance.logoutRoom();
    await ZIM.getInstance()!.logout(); // Logout ZIM
  }

  // Camera/Mic Controls
  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    // Mute/Unmute microphone (software level)
    await ZegoExpressEngine.instance.muteMicrophone(!isMicOn);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    // If speaker is muted, unmute it. If unmuted, mute it.
    // For now let's just force unmute (enable speaker)
    // await ZegoExpressEngine.instance.muteSpeaker(false);

    // Proper toggle logic if needed, but for "ses gitmiyor" usually we want to ensure speaker is ON
    // and also check if we are publishing audio.

    // Ensure audio capture is enabled
    await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
  }

  Future<void> toggleCamera() async {
    isCameraOn = !isCameraOn;
    await ZegoExpressEngine.instance.enableCamera(isCameraOn);
    notifyListeners();
  }

  // View Container Management
  Future<void> startPreview(int viewID) async {
    ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
    await ZegoExpressEngine.instance.startPreview(canvas: canvas);
    await ZegoExpressEngine.instance.enableAudioCaptureDevice(true);
  }

  Future<void> startPlayingStream(String streamID, int viewID) async {
    ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
    await ZegoExpressEngine.instance.startPlayingStream(
      streamID,
      canvas: canvas,
    );
    // Ensure audio is unmuted for this stream
    await ZegoExpressEngine.instance.mutePlayStreamAudio(streamID, false);
  }
}
