class Mistake {
  final String id;
  final String subject;
  final String grade;
  final String questionText;
  final String answerText;
  final String mistakeReason;
  final int difficulty;
  final List<String> tags;
  final String? imageUrl;
  final String source;
  final int correctCount;
  final DateTime? nextReviewAt;
  final DateTime createdAt;

  Mistake({
    required this.id,
    required this.subject,
    this.grade = '',
    this.questionText = '',
    this.answerText = '',
    this.mistakeReason = '',
    this.difficulty = 3,
    this.tags = const [],
    this.imageUrl,
    this.source = '',
    this.correctCount = 0,
    this.nextReviewAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
    id: json['id'] as String,
    subject: json['subject'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    questionText: json['question_text'] as String? ?? '',
    answerText: json['answer_text'] as String? ?? '',
    mistakeReason: json['mistake_reason'] as String? ?? '',
    difficulty: json['difficulty'] as int? ?? 3,
    tags: List<String>.from(json['tags'] ?? []),
    imageUrl: json['image_url'] as String?,
    source: json['source'] as String? ?? '',
    correctCount: json['correct_count'] as int? ?? 0,
    nextReviewAt: json['next_review_at'] != null ? DateTime.parse(json['next_review_at']) : null,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'grade': grade,
    'question_text': questionText,
    'answer_text': answerText,
    'mistake_reason': mistakeReason,
    'difficulty': difficulty,
    'tags': tags,
    'source': source,
  };
}
