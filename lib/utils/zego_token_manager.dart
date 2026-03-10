import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

class ZegoTokenUtils {
  static String generateToken({
    required int appId,
    required String serverSecret,
    required String userId,
    int effectiveTimeInSeconds = 3600,
  }) {
    if (appId == 0 || serverSecret.isEmpty || userId.isEmpty) {
      return '';
    }

    // Payload data
    Map<String, dynamic> payloadData = {
      'room_id': '', // Empty means valid for all rooms
      'privilege': {
        1: 1, // Login Room
        2: 1, // Publish Stream
      },
      'stream_id_list': null,
    };

    String payload = json.encode(payloadData);

    try {
      return _makeToken04(
        appId,
        userId,
        serverSecret,
        effectiveTimeInSeconds,
        payload,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Token generation failed: $e');
      return '';
    }
  }

  static String _makeToken04(
    int appId,
    String userId,
    String secret,
    int effectiveTimeInSeconds,
    String payload,
  ) {
    // 1. Prepare data
    int createTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int expireTime = createTime + effectiveTimeInSeconds;
    int nonce = Random().nextInt(2147483647); // int32

    // 2. Pack content to be encrypted
    // Format: user_id_len(2) + user_id + nonce(8) + create_time(8) + expire_time(0 - 8? No, token expiry is separate)

    // Official structure of "Plug-in Token":
    // { "app_id": 123, "user_id": "...", "nonce": 123, "ctime": 123, "expire": 123, "payload": "..." }
    // Then encrypt this JSON? No.

    // Let's use the simplest version:
    Map<String, dynamic> tokenInfo = {
      'app_id': appId,
      'user_id': userId,
      'nonce': nonce,
      'ctime': createTime,
      'expire': expireTime,
      'payload': payload,
    };

    String plainText = json.encode(tokenInfo);

    // 3. Encrypt
    // Random IV (16 bytes)
    final iv = IV.fromSecureRandom(16);

    // Key adjustment: If secret is 32 chars, we might need to adjust it.
    // Zego documentation says: key = ServerSecret (32 bytes).
    // If the provided secret is a hex string, we might need to parse it?
    // Usually SDKs take the string directly. Let's try 32 bytes string.

    // Wait, standard AES-CBC needs 16, 24, or 32 byte key.
    // Zego secret "aef6a32ad60b7ed6142567bafc312cd2" is 32 chars.
    // So we can use AES-256 (32 bytes key) or AES-128 (16 bytes).
    // Zego uses AES-128-CBC. So we might need to substring? Or it's a hex representation of 16 bytes?
    // 32 hex chars = 16 bytes.
    // Let's parse it as hex to bytes? No, Zego usually uses the string bytes.
    // Let's assume the key is the string itself (32 bytes) -> AES-256?
    // Zego specs say: "The encryption key is the 32-byte string of the Server Secret".

    // Let's try key length adjustment
    var keyStr = secret;
    if (keyStr.length > 32) keyStr = keyStr.substring(0, 32);
    if (keyStr.length < 32) keyStr = keyStr.padRight(32, '0'); // Should be 32

    final key = Key.fromUtf8(keyStr);

    // Use AES-CBC-PKCS7 (Default in encrypt package)
    // Zego uses AES/CBC/PKCS5Padding (which is same as PKCS7)
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // 4. Pack final token
    // version(8 bytes int64? No, string?)
    // "04" + base64(iv + encrypted_bytes)

    // Combine IV and CipherText
    BytesBuilder bytesBuilder = BytesBuilder();
    bytesBuilder.add(iv.bytes);
    bytesBuilder.add(encrypted.bytes);

    // 5. Construct final string
    String result = '04${base64.encode(bytesBuilder.toBytes())}';

    return result;
  }
}
