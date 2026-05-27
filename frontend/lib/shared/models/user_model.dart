/// User data model matching the Supabase `users` table.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.fullName,
    this.avatarUrl,
    this.college,
    this.academicYear,
    this.city,
    this.state,
    this.specialty,
    this.hospital,
    this.mrn,
    this.idPhotoUrl,
    this.yearsExperience,
    this.bio,
    this.isPro = false,
    this.proExpiresAt,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.sessionsThisMonth = 0,
    this.subscriptionPrice,
    this.fameTier = 'none',
    this.handle,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? phone;
  final String role;   // 'student' | 'doctor'
  final String status; // pending_verification | verified_student | verified_practitioner | suspended
  final String fullName;
  final String? avatarUrl;
  final String? college;
  final int? academicYear;
  final String? city;
  final String? state;
  final String? specialty;
  final String? hospital;
  final String? mrn;
  final String? idPhotoUrl;
  final int? yearsExperience;
  final String? bio;
  final bool isPro;
  final DateTime? proExpiresAt;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int currentStreak;
  final int longestStreak;
  final int sessionsThisMonth;
  final int? subscriptionPrice;
  final String fameTier;
  final String? handle;
  final DateTime? createdAt;

  bool get isDoctor => role == 'doctor';
  bool get isStudent => role == 'student';
  bool get isVerified =>
      status == 'verified_student' || status == 'verified_practitioner';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['id'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String?,
    role: j['role'] as String,
    status: j['status'] as String,
    fullName: j['full_name'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String?,
    college: j['college'] as String?,
    academicYear: j['academic_year'] as int?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    specialty: j['specialty'] as String?,
    hospital: j['hospital'] as String?,
    mrn: j['mrn'] as String?,
    idPhotoUrl: j['id_photo_url'] as String?,
    yearsExperience: j['years_experience'] as int?,
    bio: j['bio'] as String?,
    isPro: j['is_pro'] as bool? ?? false,
    proExpiresAt: j['pro_expires_at'] != null
        ? DateTime.parse(j['pro_expires_at'] as String)
        : null,
    followerCount: j['follower_count'] as int? ?? 0,
    followingCount: j['following_count'] as int? ?? 0,
    postCount: j['post_count'] as int? ?? 0,
    currentStreak: j['current_streak'] as int? ?? 0,
    longestStreak: j['longest_streak'] as int? ?? 0,
    sessionsThisMonth: j['sessions_this_month'] as int? ?? 0,
    subscriptionPrice: j['subscription_price'] as int?,
    fameTier: j['fame_tier'] as String? ?? 'none',
    handle: j['handle'] as String?,
    createdAt: j['created_at'] != null
        ? DateTime.parse(j['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'role': role,
    'status': status,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'college': college,
    'academic_year': academicYear,
    'city': city,
    'state': state,
    'specialty': specialty,
    'hospital': hospital,
    'mrn': mrn,
    'id_photo_url': idPhotoUrl,
    'years_experience': yearsExperience,
    'bio': bio,
    'is_pro': isPro,
    'pro_expires_at': proExpiresAt?.toIso8601String(),
    'follower_count': followerCount,
    'following_count': followingCount,
    'post_count': postCount,
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
    'sessions_this_month': sessionsThisMonth,
    'subscription_price': subscriptionPrice,
    'fame_tier': fameTier,
    'handle': handle,
    'created_at': createdAt?.toIso8601String(),
  };

  UserModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? city,
    String? state,
    String? phone,
    String? handle,
    String? college,
    int? academicYear,
    String? specialty,
    String? hospital,
    int? yearsExperience,
    bool? isPro,
    DateTime? proExpiresAt,
    int? followerCount,
    int? followingCount,
    int? currentStreak,
  }) => UserModel(
    id: id,
    email: email,
    phone: phone ?? this.phone,
    role: role,
    status: status,
    fullName: fullName ?? this.fullName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    college: college ?? this.college,
    academicYear: academicYear ?? this.academicYear,
    city: city ?? this.city,
    state: state ?? this.state,
    specialty: specialty ?? this.specialty,
    hospital: hospital ?? this.hospital,
    mrn: mrn,
    idPhotoUrl: idPhotoUrl,
    yearsExperience: yearsExperience ?? this.yearsExperience,
    bio: bio ?? this.bio,
    isPro: isPro ?? this.isPro,
    proExpiresAt: proExpiresAt ?? this.proExpiresAt,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount ?? this.followingCount,
    postCount: postCount,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak,
    sessionsThisMonth: sessionsThisMonth,
    subscriptionPrice: subscriptionPrice,
    fameTier: fameTier,
    handle: handle ?? this.handle,
    createdAt: createdAt,
  );
}
