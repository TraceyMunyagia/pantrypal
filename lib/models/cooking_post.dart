import 'dart:convert';
import 'dart:typed_data';

import 'recipe.dart';

class CookingPost {
  const CookingPost({
    required this.id,
    required this.recipeTitle,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.cookTime,
    required this.imageBase64,
    required this.imageMimeType,
    required this.createdAt,
  });

  final String id;
  final String recipeTitle;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String cookTime;
  final String imageBase64;
  final String imageMimeType;
  final DateTime createdAt;

  Uint8List get imageBytes => base64Decode(imageBase64);

  factory CookingPost.fromRecipe({
    required Recipe recipe,
    required Uint8List imageBytes,
    required String imageMimeType,
  }) {
    return CookingPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      recipeTitle: recipe.title,
      description: recipe.description,
      ingredients: recipe.ingredients,
      steps: recipe.steps,
      cookTime: recipe.cookTime,
      imageBase64: base64Encode(imageBytes),
      imageMimeType: imageMimeType,
      createdAt: DateTime.now(),
    );
  }

  factory CookingPost.fromJson(Map<String, dynamic> json) {
    return CookingPost(
      id: json['id'] as String? ?? DateTime.now().toIso8601String(),
      recipeTitle: json['recipeTitle'] as String? ?? 'Cooked meal',
      description: json['description'] as String? ?? '',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      cookTime: json['cookTime'] as String? ?? 'Not specified',
      imageBase64: json['imageBase64'] as String? ?? '',
      imageMimeType: json['imageMimeType'] as String? ?? 'image/jpeg',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeTitle': recipeTitle,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'cookTime': cookTime,
      'imageBase64': imageBase64,
      'imageMimeType': imageMimeType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toShareText() {
    final buffer = StringBuffer()
      ..writeln('I made $recipeTitle using PantryPal AI')
      ..writeln()
      ..writeln('Ingredients:');

    for (final ingredient in ingredients) {
      buffer.writeln('- $ingredient');
    }

    buffer
      ..writeln()
      ..writeln('Steps:');

    for (var index = 0; index < steps.length; index += 1) {
      buffer.writeln('${index + 1}. ${steps[index]}');
    }

    buffer
      ..writeln()
      ..writeln('#PantryPalAI #HomeCooking');

    return buffer.toString().trim();
  }
}
