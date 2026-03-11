// Feature: brewmaster-offline-sync
// Model representing a queued offline operation to be replayed when connectivity returns.
//
// Requirements: 22.1, 22.2
// Developer: Developer 3 (Ryan)

enum OfflineSyncOperationType { create, update, delete }

class OfflineSyncOperation {
  final String id;
  final OfflineSyncOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  const OfflineSyncOperation({
    required this.id,
    required this.type,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'collection': collection,
        'documentId': documentId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory OfflineSyncOperation.fromJson(Map<String, dynamic> json) =>
      OfflineSyncOperation(
        id: json['id'] as String,
        type: OfflineSyncOperationType.values.firstWhere(
          (e) => e.name == json['type'],
        ),
        collection: json['collection'] as String,
        documentId: json['documentId'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
        retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      );

  OfflineSyncOperation copyWith({
    String? id,
    OfflineSyncOperationType? type,
    String? collection,
    String? documentId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) =>
      OfflineSyncOperation(
        id: id ?? this.id,
        type: type ?? this.type,
        collection: collection ?? this.collection,
        documentId: documentId ?? this.documentId,
        data: data ?? this.data,
        timestamp: timestamp ?? this.timestamp,
        retryCount: retryCount ?? this.retryCount,
      );
}
