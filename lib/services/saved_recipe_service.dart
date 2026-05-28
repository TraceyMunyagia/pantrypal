import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

class SavedRecipeService {
  static const _recipesKey = 'saved_recipes';

  Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_recipesKey) ?? [];

    return values
        .map(
          (value) => Recipe.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final values = recipes
        .map((recipe) => jsonEncode(recipe.toJson()))
        .toList();
    await prefs.setStringList(_recipesKey, values);
  }
}
