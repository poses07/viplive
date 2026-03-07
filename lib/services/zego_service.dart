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

  Future<void> initEngine() async {
    if (_isEngineCreated) return;

    // Create Engine
    await ZegoExpressEngine.createEngineWithProfile(
      ZegoEngineProfile(appID, ZegoScenario.Default, appSign: appSign),
    );

    _isEngineCreated = true;
    _registerEventHandlers();
    debugPrint("Zego Engine Created");
  }

  void _registerEventHandlers() {
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

    await ZegoExpressEngine.instance.loginRoom(roomID, user, config: config);
    debugPrint("Logging into room: $roomID as $userID");

    // Default settings
    isMicOn = true;
    isCameraOn = isHost; // Host starts with camera, audience without

    if (isHost) {
      // Start Preview and Publishing immediately for Host
      await ZegoExpressEngine.instance.startPreview();
      await ZegoExpressEngine.instance.startPublishingStream("${roomID}_host");
    }
  }

  Future<void> logoutRoom() async {
    if (!isInRoom) return;
    await ZegoExpressEngine.instance.stopPublishingStream();
    await ZegoExpressEngine.instance.stopPreview();
    await ZegoExpressEngine.instance.logoutRoom();
  }

  // Camera/Mic Controls
  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    await ZegoExpressEngine.instance.muteMicrophone(!isMicOn);
    notifyListeners();
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
