import 'package:hive/hive.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: 0)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String studentId;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String universityId;

  @HiveField(4)
  final String attendanceDate; // Formatted YYYY-MM-DD

  @HiveField(5)
  final String attendanceTime; // Formatted HH:mm:ss

  @HiveField(6)
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.universityId,
    required this.attendanceDate,
    required this.attendanceTime,
    required this.createdAt,
  });

  Map toJson() => {
    'id': id,
    'studentId': studentId,
    'fullName': fullName,
    'universityId': universityId,
    'attendanceDate': attendanceDate,
    'attendanceTime': attendanceTime,
    'createdAt': createdAt.toIso8601String(),
  };
}