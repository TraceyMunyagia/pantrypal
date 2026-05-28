import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class AiRecipeService {
  Future<Recipe> generateRecipe(List<String> ingredients) async {
    final text = await sendRecipePrompt(
      'Generate a simple recipe using: ${ingredients.join(', ')}',
    );

    return Recipe.fromAiText(text);
  }

  Future<String> sendRecipePrompt(String userPrompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final apiUrl =
        dotenv.env['GEMINI_API_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta';
    final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
    final prompt = _buildRecipePrompt(userPrompt);

    if (apiKey.isEmpty || apiUrl.isEmpty) {
      return _fallbackRecipeText(userPrompt);
    }

    final endpoint = Uri.parse(
      '${apiUrl.replaceFirst(RegExp(r'/$'), '')}/models/$model:generateContent',
    );

    late final http.Response response;
    try {
      response = await http
          .post(
            endpoint,
            headers: {
              'x-goog-api-key': apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 700},
            }),
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw Exception('The recipe request timed out. Please try again.');
    } catch (_) {
      throw Exception(
        'Could not reach the recipe service. Check your connection.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Recipe generation failed (${response.statusCode}). Please try again.',
      );
    }

    final Object decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('The recipe service returned an unreadable response.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('The recipe service returned an unexpected response.');
    }

    final data = decoded;
    final content = _extractGeminiText(data);

    if (content.isEmpty) {
      throw Exception('The recipe service returned an empty recipe.');
    }

    return content;
  }

  String _buildRecipePrompt(String userPrompt) {
    return '''
You are PantryPal AI, a concise recipe assistant.

User request:
$userPrompt

Return one practical recipe in this exact plain-text structure:
Title: ...
Cooking time: ...
Ingredients:
- ...
- ...
Steps:
1. ...
2. ...
''';
  }

  String _extractGeminiText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      return '';
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? [];

    return parts
        .map((part) => part is Map<String, dynamic> ? part['text'] : null)
        .whereType<String>()
        .join('\n')
        .trim();
  }

  String _fallbackRecipeText(String prompt) {
    final ingredients = _extractIngredients(prompt);

    return '''
Title: Sunny Pantry Skillet
Cooking time: 20 minutes
Ingredients:
- ${ingredients.join('\n- ')}
- Salt and pepper
- 1 tablespoon cooking oil
Steps:
1. Warm the oil in a skillet over medium heat.
2. Add ${ingredients.join(', ')} and cook until softened.
3. Season with salt and pepper.
4. Serve warm as-is, over rice, or with toast.
''';
  }

  List<String> _extractIngredients(String prompt) {
    final lower = prompt.toLowerCase();
    final marker = 'using:';
    final start = lower.indexOf(marker);
    final source = start == -1
        ? prompt
        : prompt.substring(start + marker.length);
    final firstLine = source.split('\n').first;
    final values = firstLine
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    return values.isEmpty ? ['pantry staples'] : values;
  }
}
