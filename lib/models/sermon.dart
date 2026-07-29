class Sermon {
  final String id;
  final String churchId;
  final String branchId;
  final String title;
  final String speaker;
  final String series;
  final String scriptureReference;
  final String notes;
  final String audioUrl;
  final String videoUrl;
  final String serviceType;
  final DateTime date;
  final String recordedById;
  final DateTime createdAt;

  const Sermon({
    required this.id,
    required this.churchId,
    required this.branchId,
    required this.title,
    required this.speaker,
    required this.series,
    required this.scriptureReference,
    required this.notes,
    required this.audioUrl,
    required this.videoUrl,
    required this.serviceType,
    required this.date,
    required this.recordedById,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'churchId': churchId,
        'branchId': branchId,
        'title': title,
        'speaker': speaker,
        'series': series,
        'scriptureReference': scriptureReference,
        'notes': notes,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'serviceType': serviceType,
        'date': date.toIso8601String(),
        'recordedById': recordedById,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Sermon.fromMap(Map<dynamic, dynamic> map) => Sermon(
        id: map['id'] as String,
        churchId: map['churchId'] as String,
        branchId: map['branchId'] as String,
        title: map['title'] as String,
        speaker: map['speaker'] as String,
        series: (map['series'] as String?) ?? '',
        scriptureReference: (map['scriptureReference'] as String?) ?? '',
        notes: (map['notes'] as String?) ?? '',
        audioUrl: (map['audioUrl'] as String?) ?? '',
        videoUrl: (map['videoUrl'] as String?) ?? '',
        serviceType: (map['serviceType'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        recordedById: map['recordedById'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Sermon copyWith({
    String? title,
    String? speaker,
    String? series,
    String? scriptureReference,
    String? notes,
    String? audioUrl,
    String? videoUrl,
    String? serviceType,
    DateTime? date,
    String? branchId,
  }) =>
      Sermon(
        id: id,
        churchId: churchId,
        branchId: branchId ?? this.branchId,
        title: title ?? this.title,
        speaker: speaker ?? this.speaker,
        series: series ?? this.series,
        scriptureReference: scriptureReference ?? this.scriptureReference,
        notes: notes ?? this.notes,
        audioUrl: audioUrl ?? this.audioUrl,
        videoUrl: videoUrl ?? this.videoUrl,
        serviceType: serviceType ?? this.serviceType,
        date: date ?? this.date,
        recordedById: recordedById,
        createdAt: createdAt,
      );
}
