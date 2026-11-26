class NotificationEntry {
  const NotificationEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  factory NotificationEntry.fromJson(Map<String, dynamic> json) =>
      NotificationEntry(
        id: json['id'] as String,
        kind: json['kind'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.channelOrder,
    this.quietHours,
  });

  final List<String> channelOrder;
  final ({String start, String end})? quietHours;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final quiet = json['quietHours'] as Map<String, dynamic>?;
    return NotificationPreferences(
      channelOrder: (json['channelOrder'] as List<dynamic>).cast<String>(),
      quietHours: quiet == null
          ? null
          : (start: quiet['start'] as String, end: quiet['end'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'channelOrder': channelOrder,
        'quietHours': quietHours == null
            ? null
            : {'start': quietHours!.start, 'end': quietHours!.end},
      };
}
