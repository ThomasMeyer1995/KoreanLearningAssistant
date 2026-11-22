enum VocabType { vocabulary, grammar }

class VocabItem {
  final String id;
  final String korean;
  final String english;
  final VocabType type;
  final String exampleKr;
  final String exampleEn;
  final int questionNumber;
  final String section;
  final bool missed;
  final int knownCount;

  VocabItem({
    required this.id,
    required this.korean,
    required this.english,
    required this.type,
    this.exampleKr = '',
    this.exampleEn = '',
    this.questionNumber = 0,
    this.section = '',
    this.missed = false,
    this.knownCount = 0,
  });

  String get typeLabel => type == VocabType.grammar ? 'Grammar' : 'Vocabulary';

  bool get hasExample => exampleKr.isNotEmpty || exampleEn.isNotEmpty;

  VocabItem copyWith({
    String? id,
    String? korean,
    String? english,
    VocabType? type,
    String? exampleKr,
    String? exampleEn,
    int? questionNumber,
    String? section,
    bool? missed,
    int? knownCount,
  }) {
    return VocabItem(
      id: id ?? this.id,
      korean: korean ?? this.korean,
      english: english ?? this.english,
      type: type ?? this.type,
      exampleKr: exampleKr ?? this.exampleKr,
      exampleEn: exampleEn ?? this.exampleEn,
      questionNumber: questionNumber ?? this.questionNumber,
      section: section ?? this.section,
      missed: missed ?? this.missed,
      knownCount: knownCount ?? this.knownCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'korean': korean,
        'english': english,
        'type': type == VocabType.grammar ? 'grammar' : 'vocabulary',
        'exampleKr': exampleKr,
        'exampleEn': exampleEn,
        'questionNumber': questionNumber,
        'section': section,
        'missed': missed,
        'knownCount': knownCount,
      };

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      id: json['id'] as String,
      korean: json['korean'] as String,
      english: json['english'] as String? ?? '',
      type: json['type'] == 'grammar' ? VocabType.grammar : VocabType.vocabulary,
      exampleKr: json['exampleKr'] as String? ?? '',
      exampleEn: json['exampleEn'] as String? ?? '',
      questionNumber: (json['questionNumber'] as num?)?.toInt() ?? 0,
      section: json['section'] as String? ?? '',
      missed: json['missed'] as bool? ?? false,
      knownCount: (json['knownCount'] as num?)?.toInt() ?? 0,
    );
  }
}
