class Recipe {
  const Recipe({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.cookTime,
    required this.rawText,
    required this.createdAt,
    this.isFavorite = false,
  });

  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String cookTime;
  final String rawText;
  final DateTime createdAt;
  final bool isFavorite;

  factory Recipe.fromAiText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final title = _findTitle(lines);
    final ingredients = _findSectionItems(lines, 'ingredients');
    final steps = _findSectionItems(lines, 'steps');
    final cookTime = _findCookingTime(lines);

    return Recipe(
      title: title,
      description: _findDescription(lines, title),
      ingredients: ingredients,
      steps: steps,
      cookTime: cookTime,
      rawText: text,
      createdAt: DateTime.now(),
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] as String? ?? 'Saved Recipe',
      description: json['description'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      cookTime: json['cookTime'] as String? ?? 'Not specified',
      rawText: json['rawText'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'cookTime': cookTime,
      'rawText': rawText,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  Recipe copyWith({bool? isFavorite}) {
    return Recipe(
      title: title,
      description: description,
      ingredients: ingredients,
      steps: steps,
      cookTime: cookTime,
      rawText: rawText,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  static String _findTitle(List<String> lines) {
    if (lines.isEmpty) return 'Pantry Recipe';

    final titleLine = lines.firstWhere(
      (line) => line.toLowerCase().startsWith('title:'),
      orElse: () => lines.first,
    );

    return titleLine
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .replaceFirst(RegExp(r'^title:\s*', caseSensitive: false), '')
        .trim();
  }

  static String _findDescription(List<String> lines, String title) {
    return lines.firstWhere(
      (line) =>
          line != title &&
          !line.contains(':') &&
          !line.startsWith('-') &&
          !RegExp(r'^\d+\.').hasMatch(line),
      orElse: () => 'A simple recipe generated from your pantry request.',
    );
  }

  static String _findCookingTime(List<String> lines) {
    final timeLine = lines.firstWhere(
      (line) => line.toLowerCase().contains('cooking time'),
      orElse: () => '',
    );

    if (timeLine.isEmpty) return 'Not specified';

    return timeLine
        .replaceFirst(RegExp(r'^cooking time:\s*', caseSensitive: false), '')
        .trim();
  }

  static List<String> _findSectionItems(List<String> lines, String section) {
    final start = lines.indexWhere(
      (line) => line.toLowerCase().startsWith(section),
    );
    if (start == -1) return const [];

    final items = <String>[];
    for (final line in lines.skip(start + 1)) {
      final normalized = line.toLowerCase();
      if (normalized.startsWith('ingredients') ||
          normalized.startsWith('steps') ||
          normalized.startsWith('cooking time')) {
        break;
      }

      final cleaned = line
          .replaceFirst(RegExp(r'^[-*]\s*'), '')
          .replaceFirst(RegExp(r'^\d+\.\s*'), '')
          .trim();
      if (cleaned.isNotEmpty) items.add(cleaned);
    }

    return items;
  }
}
