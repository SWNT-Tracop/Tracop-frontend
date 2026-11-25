class RatingSubmission {
  const RatingSubmission({
    required this.id,
    required this.orderId,
    required this.score,
    this.comment,
  });

  final String id;
  final String orderId;
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'ratee': 'provider',
        'score': score,
        if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
      };
}

class RatingResult {
  const RatingResult({required this.id, required this.score});

  final String id;
  final int score;

  factory RatingResult.fromJson(Map<String, dynamic> json) => RatingResult(
        id: json['id'] as String,
        score: (json['score'] as num).toInt(),
      );
}
