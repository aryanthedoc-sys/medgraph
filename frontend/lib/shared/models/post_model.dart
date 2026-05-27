class PostModel {
  const PostModel({
    required this.id,
    required this.authorId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.mediaType,
    this.topicTag,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewCount = 0,
    this.isPremium = false,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.authorHandle,
    this.isVerifiedDoctor,
    this.isLiked = false,
    // MCQ fields
    this.mcqQuestion,
    this.mcqOptionA,
    this.mcqOptionB,
    this.mcqOptionC,
    this.mcqOptionD,
    this.mcqCorrectAnswer,
    this.mcqExplanation,
    this.userAnswer,
  });

  final String id;
  final String authorId;
  final String type; // 'rounds' | 'cases' | 'life'
  final String content;
  final String? mediaUrl;
  final String? mediaType; // 'video' | 'image' | 'pdf'
  final String? topicTag;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool isPremium;
  final DateTime createdAt;

  // Joined fields
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorHandle;
  final bool? isVerifiedDoctor;
  final bool isLiked;

  // MCQ
  final String? mcqQuestion;
  final String? mcqOptionA;
  final String? mcqOptionB;
  final String? mcqOptionC;
  final String? mcqOptionD;
  final String? mcqCorrectAnswer;
  final String? mcqExplanation;
  final String? userAnswer;

  bool get hasMcq => mcqQuestion != null;

  factory PostModel.fromJson(Map<String, dynamic> j) => PostModel(
    id: j['id'] as String,
    authorId: j['author_id'] as String,
    type: j['type'] as String,
    content: j['content'] as String? ?? '',
    mediaUrl: j['media_url'] as String?,
    mediaType: j['media_type'] as String?,
    topicTag: j['topic_tag'] as String?,
    likeCount: j['like_count'] as int? ?? 0,
    commentCount: j['comment_count'] as int? ?? 0,
    viewCount: j['view_count'] as int? ?? 0,
    isPremium: j['is_premium'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    authorName: j['author_name'] as String?,
    authorAvatarUrl: j['author_avatar_url'] as String?,
    authorHandle: j['author_handle'] as String?,
    isVerifiedDoctor: j['is_verified_doctor'] as bool?,
    isLiked: j['is_liked'] as bool? ?? false,
    mcqQuestion: j['mcq_question'] as String?,
    mcqOptionA: j['mcq_option_a'] as String?,
    mcqOptionB: j['mcq_option_b'] as String?,
    mcqOptionC: j['mcq_option_c'] as String?,
    mcqOptionD: j['mcq_option_d'] as String?,
    mcqCorrectAnswer: j['mcq_correct_answer'] as String?,
    mcqExplanation: j['mcq_explanation'] as String?,
    userAnswer: j['user_answer'] as String?,
  );
}

class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.isCorrectAnswer = false,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });

  final String id;
  final String postId;
  final String authorId;
  final String content;
  final bool isCorrectAnswer;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
    id: j['id'] as String,
    postId: j['post_id'] as String,
    authorId: j['author_id'] as String,
    content: j['content'] as String,
    isCorrectAnswer: j['is_correct_answer'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    authorName: j['author_name'] as String?,
    authorAvatarUrl: j['author_avatar_url'] as String?,
  );
}
