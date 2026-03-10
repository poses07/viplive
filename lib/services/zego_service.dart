import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

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
    // Use HighQualityChatroom for voice chat apps
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(
        appID,
        ZegoScenario.HighQualityChatroom,
        appSign: appSign,
      ),
    );

    _isEngineCreated = true;

    // Enable sound level monitoring
    await ZegoExpressEngine.instance.startSoundLevelMonitor();

    _registerEventHandlers();
    debugPrint("Zego Engine Created");
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
        }
      } else {
        for (var stream in streamList) {
          ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
        }
      }
    };
  }

import '../utils/zego_token_manager.dart'; // Import token manager

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
      serverSecret: "aef6a32ad60b7ed6142567bafc312cd2", // Should be in env or remote config
      userId: userID
    );
    config.token = token;

    await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
    debugPrint("Logging into room: $roomID as $userID with token");

    // Default settings
    isMicOn = true;
    isCameraOn = isHost; // Host starts with camera, audience without

    if (isHost) {
      // Start Preview and Publishing immediately for Host
      await ZegoExpressEngine.instance.startPreview();
      await ZegoExpressEngine.instance.startPublishingStream("${roomID}_host");
    }
  }

  // Stream Management
  Future<void> startPublishingStream(
    String streamID, {
    bool video = true,
  }) async {
    await ZegoExpressEngine.instance.enableCamera(video);
    await ZegoExpressEngine.instance.muteMicrophone(false); // Ensure mic is on
    await ZegoExpressEngine.instance.muteSpeaker(false); // Ensure speaker is on
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
  }

  // Camera/Mic Controls
  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    await ZegoExpressEngine.instance.muteMicrophone(!isMicOn);
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    await ZegoExpressEngine.instance.muteSpeaker(false);
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
  }

  Future<void> startPlayingStream(String streamID, int viewID) async {
    ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
    await ZegoExpressEngine.instance.startPlayingStream(
      streamID,
      canvas: canvas,
    );
  }
}
