import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/meal_plan.dart';

class AiMealPlanService {
  Future<MealPlan> generateMealPlan(MealPlanRequest request) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final apiUrl =
        dotenv.env['GEMINI_API_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta';
    final model = dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty || apiUrl.isEmpty) {
      return _fallbackPlan(request);
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
                    {'text': _buildPrompt(request)},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.65,
                'maxOutputTokens': 4000,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw Exception('The meal plan request timed out. Please try again.');
    } catch (_) {
      throw Exception(
        'Could not reach the meal plan service. Check your connection.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Meal plan generation failed (${response.statusCode}). Please try again.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractGeminiText(decoded);
    if (text.isEmpty) {
      throw Exception('The meal plan service returned an empty plan.');
    }

    try {
      final planJson =
          jsonDecode(_stripJsonFence(text)) as Map<String, dynamic>;
      return MealPlan.fromJson({
        ...planJson,
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'durationDays': request.durationDays,
        'preferences': request.preferences,
        'goal': request.goal,
        'budget': request.budget,
      });
    } catch (_) {
      return _fallbackPlan(request);
    }
  }

  String _buildPrompt(MealPlanRequest request) {
    return '''
Generate a healthy ${request.durationDays}-day meal plan using:
${request.ingredients.map((ingredient) => '- $ingredient').join('\n')}

Goal: ${request.goal.isEmpty ? 'balanced eating' : request.goal}
Budget: ${request.budget.isEmpty ? 'flexible' : request.budget}
Preferences: ${request.preferences.isEmpty ? 'none' : request.preferences.join(', ')}

Return only valid JSON with this shape:
{
  "title": "string",
  "days": [
    {
      "dayNumber": 1,
      "meals": [
        {
          "type": "Breakfast",
          "name": "string",
          "ingredients": ["string"],
          "instructions": ["string"],
          "prepTime": "string",
          "calories": 450
        }
      ]
    }
  ]
}

Every day must include Breakfast, Lunch, Dinner, and Snacks.
Keep ingredients practical and reuse the user's ingredients where possible.
''';
  }

  String _extractGeminiText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return '';

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? [];

    return parts
        .map((part) => part is Map<String, dynamic> ? part['text'] : null)
        .whereType<String>()
        .join('\n')
        .trim();
  }

  String _stripJsonFence(String value) {
    return value
        .replaceFirst(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'^```\s*', multiLine: true), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  MealPlan _fallbackPlan(MealPlanRequest request) {
    final ingredients = request.ingredients.isEmpty
        ? ['rice', 'chicken', 'vegetables']
        : request.ingredients;
    final protein = request.preferences.contains('High protein')
        ? 'extra protein'
        : ingredients.first;

    return MealPlan(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '${request.durationDays}-Day Pantry Meal Plan',
      durationDays: request.durationDays,
      preferences: request.preferences,
      goal: request.goal,
      budget: request.budget,
      createdAt: DateTime.now(),
      days: List.generate(request.durationDays, (index) {
        final day = index + 1;
        final base = ingredients[index % ingredients.length];
        final side = ingredients[(index + 1) % ingredients.length];
        return MealPlanDay(
          dayNumber: day,
          meals: [
            Meal(
              type: 'Breakfast',
              name: '$protein breakfast bowl',
              ingredients: [base, 'eggs or beans', 'greens', 'seasoning'],
              instructions: [
                'Cook $base until tender.',
                'Add eggs or beans with greens and seasoning.',
                'Serve warm in a bowl.',
              ],
              prepTime: '20 min',
              calories: 420,
            ),
            Meal(
              type: 'Lunch',
              name: '$base and $side power plate',
              ingredients: [base, side, 'olive oil', 'lemon or vinegar'],
              instructions: [
                'Prepare $base and $side in separate pans.',
                'Toss with olive oil and a bright acid.',
                'Pack with extra vegetables for volume.',
              ],
              prepTime: '25 min',
              calories: 560,
            ),
            Meal(
              type: 'Dinner',
              name: 'One-pan ${ingredients.last} dinner',
              ingredients: [ingredients.last, base, 'onions', 'tomatoes'],
              instructions: [
                'Saute onions and tomatoes until soft.',
                'Add ${ingredients.last} and cook through.',
                'Serve with $base and adjust seasoning.',
              ],
              prepTime: '35 min',
              calories: 640,
            ),
            Meal(
              type: 'Snacks',
              name: 'Budget snack box',
              ingredients: [side, 'fruit', 'nuts or yogurt'],
              instructions: [
                'Slice $side and fruit.',
                'Portion with nuts or yogurt for a quick snack.',
              ],
              prepTime: '10 min',
              calories: 240,
            ),
          ],
        );
      }),
    );
  }
}
