import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class QrVerificationService {
  static final Ed25519 _algorithm = Ed25519();

  // ============================================================
  // PERMANENT SYSTEM PUBLIC KEY
  // ============================================================

  static const String publicKeyBase64 =
      'ps1nJrqeUooz4h5V4L36qK-oVKlOR7QgKdCcg5QL-8U=';

  static const String expectedKeyId =
      'ps1nJrqeUooz';

  static SimplePublicKey get _publicKey {
    final bytes = base64Url.decode(
      publicKeyBase64,
    );

    return SimplePublicKey(
      bytes,
      type: KeyPairType.ed25519,
    );
  }

  static Future<bool> verify({
    required String studentId,
    required String fullName,
    required String universityId,
    required String keyId,
    required String signatureBase64,
  }) async {
    try {
      if (keyId != expectedKeyId) {
        return false;
      }

      final canonicalPayload = jsonEncode({
        'type': 'univ_att_std',
        'v': 2,
        'kid': keyId,
        'sid': studentId,
        'fn': fullName,
        'uid': universityId,
      });

      final signatureBytes =
      base64Url.decode(signatureBase64);

      final signature = Signature(
        signatureBytes,
        publicKey: _publicKey,
      );

      return await _algorithm.verify(
        utf8.encode(canonicalPayload),
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }
}