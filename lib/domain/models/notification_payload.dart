class NotificationPayload {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {'type': type, 'title': title, 'body': body, 'data': data};
  }

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }

  NotificationPayload copyWith({
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) {
    return NotificationPayload(
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationPayload &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        _mapsEqual(other.data, data);
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return type.hashCode ^ title.hashCode ^ body.hashCode ^ data.hashCode;
  }

  @override
  String toString() {
    return 'NotificationPayload(type: $type, title: $title, body: $body, data: $data)';
  }
}
