class SessionModel {
  const SessionModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.roomId,
    required this.topic,
    required this.mode,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    required this.createdAt,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerCollege,
    this.partnerSpecialty,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final String roomId;
  final String topic;
  final String mode; // 'study' | 'clinical' | 'casual'
  final String status; // 'scheduled' | 'active' | 'completed' | 'cancelled'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final DateTime createdAt;

  // Populated client-side from join
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? partnerCollege;
  final String? partnerSpecialty;

  factory SessionModel.fromJson(Map<String, dynamic> j) => SessionModel(
    id: j['id'] as String,
    user1Id: j['user1_id'] as String,
    user2Id: j['user2_id'] as String,
    roomId: j['room_id'] as String,
    topic: j['topic'] as String? ?? '',
    mode: j['mode'] as String,
    status: j['status'] as String,
    startedAt: j['started_at'] != null ? DateTime.parse(j['started_at']) : null,
    endedAt: j['ended_at'] != null ? DateTime.parse(j['ended_at']) : null,
    durationMinutes: j['duration_minutes'] as int?,
    createdAt: DateTime.parse(j['created_at'] as String),
    partnerName: j['partner_name'] as String?,
    partnerAvatarUrl: j['partner_avatar_url'] as String?,
    partnerCollege: j['partner_college'] as String?,
    partnerSpecialty: j['partner_specialty'] as String?,
  );
}

class SessionRequestModel {
  const SessionRequestModel({
    required this.id,
    required this.userId,
    required this.topic,
    required this.date,
    required this.time,
    required this.mode,
    required this.status,
    this.matchedSessionId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String topic;
  final DateTime date;
  final String time;
  final String mode;
  final String status; // 'pending' | 'matched' | 'expired' | 'cancelled'
  final String? matchedSessionId;
  final DateTime createdAt;

  factory SessionRequestModel.fromJson(Map<String, dynamic> j) =>
      SessionRequestModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        topic: j['topic'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        time: j['time'] as String,
        mode: j['mode'] as String,
        status: j['status'] as String,
        matchedSessionId: j['matched_session_id'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
