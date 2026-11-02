class Photo {
  final String id;
  final String recordId;
  final String filePath;
  final String caption;
  final int sortOrder;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.recordId,
    required this.filePath,
    this.caption = '',
    this.sortOrder = 0,
    required this.createdAt,
  });

  /// Every `record_id` a record's photos are stored under: the photos tab
  /// plus the soil and vertical structure sections.
  static List<String> keysFor(String recordId) =>
      [recordId, '${recordId}_soil', '${recordId}_vertStruct'];

  Photo withCaption(String value) => Photo(
        id: id,
        recordId: recordId,
        filePath: filePath,
        caption: value,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'record_id': recordId,
        'file_path': filePath,
        'caption': caption,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory Photo.fromMap(Map<String, dynamic> m) => Photo(
        id: m['id'] as String,
        recordId: m['record_id'] as String,
        filePath: m['file_path'] as String,
        caption: m['caption'] as String? ?? '',
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
