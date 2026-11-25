import 'dart:convert';

import 'package:flutter/foundation.dart';

class StudentQRPayload {
  final String studentId;
  final String fullName;
  final String universityId;
  final String type;
  final int version;
  final String keyId;
  final String signature;

  StudentQRPayload({
    required this.studentId,
    required this.fullName,
    required this.universityId,
    required this.type,
    required this.version,
    required this.keyId,
    required this.signature,
  });

  factory StudentQRPayload.fromJsonString(
      String rawJson,
      ) {
    try {
      final decoded = jsonDecode(rawJson);

      if (decoded is! Map) {
        throw const FormatException(
          'بيانات QR غير صالحة',
        );
      }

      final Map data = decoded;

      // QR type must be exactly the new student QR type.
      if (data['type'] != 'univ_att_std') {
        throw const FormatException(
          'نوع البطاقة غير مدعوم',
        );
      }

      // Only version 2 is accepted.
      //
      // Version 1 QR codes were unsigned and are no longer
      // accepted by the secure scanner.
      if (data['v'] != 2) {
        throw const FormatException(
          'إصدار بطاقة QR غير مدعوم',
        );
      }

      final studentId = data['sid'];
      final fullName = data['fn'];
      final universityId = data['uid'];
      final keyId = data['kid'];
      final signature = data['sig'];

      if (studentId == null ||
          fullName == null ||
          universityId == null ||
          keyId == null ||
          signature == null) {
        throw const FormatException(
          'بيانات الأمان داخل QR ناقصة',
        );
      }

      final studentIdString =
      studentId.toString().trim();

      final fullNameString =
      fullName.toString().trim();

      final universityIdString =
      universityId.toString().trim();

      final keyIdString =
      keyId.toString().trim();

      final signatureString =
      signature.toString().trim();

      if (studentIdString.isEmpty ||
          fullNameString.isEmpty ||
          universityIdString.isEmpty ||
          keyIdString.isEmpty ||
          signatureString.isEmpty) {
        throw const FormatException(
          'بيانات QR تحتوي على قيم فارغة',
        );
      }

      return StudentQRPayload(
        studentId: studentIdString,
        fullName: fullNameString,
        universityId: universityIdString,
        type: data['type'].toString(),
        version: data['v'] as int,
        keyId: keyIdString,
        signature: signatureString,
      );
    } catch (e) {
      debugPrint(
        'Error parsing Student QR Payload: $e',
      );

      rethrow;
    }
  }
}