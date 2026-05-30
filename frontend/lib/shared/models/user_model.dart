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
    // legacy fields
    this.college,
    this.academicYear,
    this.city,
    this.state,
    // new fields
    this.collegeName,
    this.collegeCity,
    this.collegeState,
    this.university,
    this.yearOfStudy,
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
    // verification
    this.isVerifiedBool = false,
    this.isSuspended = false,
    this.reportCount = 0,
    this.vouchCount = 0,
    this.verificationProofUrl,
    // pro filters
    this.proFilterMatchBds = false,
    this.proFilterSameCollege = false,
    this.proFilterSameCity = false,
    this.proFilterSameState = false,
    // extended profile
    this.tags = const [],
    this.languages = const [],
    this.leaderboardRank,
    this.sessionCount = 0,
  });

  final String id;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String fullName;
  final String? avatarUrl;

  // Legacy fields (kept for existing data)
  final String? college;
  final int? academicYear;
  final String? city;
  final String? state;

  // New registration fields
  final String? collegeName;
  final String? collegeCity;
  final String? collegeState;
  final String? university;
  final String? yearOfStudy;
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

  // Verification
  final bool isVerifiedBool;
  final bool isSuspended;
  final int reportCount;
  final int vouchCount;
  final String? verificationProofUrl;

  // Pro filters
  final bool proFilterMatchBds;
  final bool proFilterSameCollege;
  final bool proFilterSameCity;
  final bool proFilterSameState;

  // Extended profile
  final List<String> tags;
  final List<String> languages;
  final int? leaderboardRank;
  final int sessionCount;

  bool get isDoctor  => role == 'doctor';
  bool get isStudent => role.startsWith('student_') || role == 'student';

  bool get isVerified =>
      isVerifiedBool ||
      status == 'verified' ||
      status == 'verified_student' ||
      status == 'verified_practitioner';

  bool get isProofSubmitted => status == 'proof_submitted';
  bool get isPendingVerification => status == 'pending_verification';

  /// Display name for the role
  String get roleLabel {
    switch (role) {
      case 'student_mbbs': return 'MBBS Student';
      case 'student_bds':  return 'BDS Student';
      case 'student_bams': return 'BAMS Student';
      case 'doctor':       return 'Doctor';
      case 'student':      return 'Medical Student';
      default:             return role;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id:        j['id'] as String,
    email:     j['email'] as String,
    phone:     j['phone'] as String?,
    role:      j['role'] as String? ?? 'student',
    status:    j['status'] as String? ?? 'pending_verification',
    fullName:  j['full_name'] as String? ?? '',
    avatarUrl: j['avatar_url'] as String?,
    // legacy
    college:      j['college'] as String?,
    academicYear: j['academic_year'] as int?,
    city:         j['city'] as String?,
    state:        j['state'] as String?,
    // new
    collegeName:  j['college_name'] as String?,
    collegeCity:  j['college_city'] as String?,
    collegeState: j['college_state'] as String?,
    university:   j['university'] as String?,
    yearOfStudy:  j['year_of_study'] as String?,
    specialty:    j['specialty'] as String?,
    hospital:     j['hospital'] as String?,
    mrn:          j['mrn'] as String?,
    idPhotoUrl:   j['id_photo_url'] as String?,
    yearsExperience: j['years_experience'] as int?,
    bio:          j['bio'] as String?,
    isPro:        j['is_pro'] as bool? ?? false,
    proExpiresAt: j['pro_expires_at'] != null
        ? DateTime.parse(j['pro_expires_at'] as String)
        : null,
    followerCount:     j['follower_count'] as int? ?? 0,
    followingCount:    j['following_count'] as int? ?? 0,
    postCount:         j['post_count'] as int? ?? 0,
    currentStreak:     j['current_streak'] as int? ?? 0,
    longestStreak:     j['longest_streak'] as int? ?? 0,
    sessionsThisMonth: j['sessions_this_month'] as int? ?? 0,
    subscriptionPrice: j['subscription_price'] as int?,
    fameTier:          j['fame_tier'] as String? ?? 'none',
    handle:            j['handle'] as String?,
    createdAt: j['created_at'] != null
        ? DateTime.parse(j['created_at'] as String)
        : null,
    isVerifiedBool:       j['is_verified'] as bool? ?? false,
    isSuspended:          j['is_suspended'] as bool? ?? false,
    reportCount:          j['report_count'] as int? ?? 0,
    vouchCount:           j['vouch_count'] as int? ?? 0,
    verificationProofUrl: j['verification_proof_url'] as String?,
    proFilterMatchBds:    j['pro_filter_match_bds'] as bool? ?? false,
    proFilterSameCollege: j['pro_filter_same_college'] as bool? ?? false,
    proFilterSameCity:    j['pro_filter_same_city'] as bool? ?? false,
    proFilterSameState:   j['pro_filter_same_state'] as bool? ?? false,
    tags:         (j['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    languages:    (j['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    leaderboardRank: j['leaderboard_rank'] as int?,
    sessionCount:    j['session_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'phone': phone,
    'role': role, 'status': status, 'full_name': fullName,
    'avatar_url': avatarUrl, 'college': college,
    'academic_year': academicYear, 'city': city, 'state': state,
    'college_name': collegeName, 'college_city': collegeCity,
    'college_state': collegeState, 'university': university,
    'year_of_study': yearOfStudy, 'specialty': specialty,
    'hospital': hospital, 'mrn': mrn, 'id_photo_url': idPhotoUrl,
    'years_experience': yearsExperience, 'bio': bio,
    'is_pro': isPro, 'pro_expires_at': proExpiresAt?.toIso8601String(),
    'follower_count': followerCount, 'following_count': followingCount,
    'post_count': postCount, 'current_streak': currentStreak,
    'longest_streak': longestStreak, 'sessions_this_month': sessionsThisMonth,
    'subscription_price': subscriptionPrice, 'fame_tier': fameTier,
    'handle': handle, 'created_at': createdAt?.toIso8601String(),
    'is_verified': isVerifiedBool, 'is_suspended': isSuspended,
    'report_count': reportCount, 'vouch_count': vouchCount,
    'verification_proof_url': verificationProofUrl,
    'pro_filter_match_bds': proFilterMatchBds,
    'pro_filter_same_college': proFilterSameCollege,
    'pro_filter_same_city': proFilterSameCity,
    'pro_filter_same_state': proFilterSameState,
  };

  UserModel copyWith({
    String? fullName, String? avatarUrl, String? bio,
    String? city, String? state, String? phone, String? handle,
    String? college, int? academicYear,
    String? collegeName, String? collegeCity, String? collegeState,
    String? university, String? yearOfStudy,
    String? specialty, String? hospital, int? yearsExperience,
    bool? isPro, DateTime? proExpiresAt,
    int? followerCount, int? followingCount, int? currentStreak,
    bool? isVerifiedBool, String? status,
    int? vouchCount,
    bool? proFilterMatchBds, bool? proFilterSameCollege,
    bool? proFilterSameCity, bool? proFilterSameState,
  }) => UserModel(
    id: id, email: email, phone: phone ?? this.phone,
    role: role, status: status ?? this.status,
    fullName: fullName ?? this.fullName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    college: college ?? this.college,
    academicYear: academicYear ?? this.academicYear,
    city: city ?? this.city, state: state ?? this.state,
    collegeName: collegeName ?? this.collegeName,
    collegeCity: collegeCity ?? this.collegeCity,
    collegeState: collegeState ?? this.collegeState,
    university: university ?? this.university,
    yearOfStudy: yearOfStudy ?? this.yearOfStudy,
    specialty: specialty ?? this.specialty,
    hospital: hospital ?? this.hospital,
    mrn: mrn, idPhotoUrl: idPhotoUrl,
    yearsExperience: yearsExperience ?? this.yearsExperience,
    bio: bio ?? this.bio,
    isPro: isPro ?? this.isPro,
    proExpiresAt: proExpiresAt ?? this.proExpiresAt,
    followerCount: followerCount ?? this.followerCount,
    followingCount: followingCount ?? this.followingCount,
    postCount: postCount, currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak, sessionsThisMonth: sessionsThisMonth,
    subscriptionPrice: subscriptionPrice, fameTier: fameTier,
    handle: handle ?? this.handle, createdAt: createdAt,
    isVerifiedBool: isVerifiedBool ?? this.isVerifiedBool,
    isSuspended: isSuspended, reportCount: reportCount,
    vouchCount: vouchCount ?? this.vouchCount,
    verificationProofUrl: verificationProofUrl,
    proFilterMatchBds: proFilterMatchBds ?? this.proFilterMatchBds,
    proFilterSameCollege: proFilterSameCollege ?? this.proFilterSameCollege,
    proFilterSameCity: proFilterSameCity ?? this.proFilterSameCity,
    proFilterSameState: proFilterSameState ?? this.proFilterSameState,
  );
}
