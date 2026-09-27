import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveRecipe({
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> instructions,
    int? cookingTime,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    await _supabase.from('recipes').insert({
      'user_id': user.id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'cooking_time_minutes': cookingTime,
      'is_ai_generated': true,
    });
  }

  Future<List<Map<String, dynamic>>> fetchUserRecipes() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final response = await _supabase
        .from('recipes')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    await _supabase.from('favorites').insert({
      'user_id': user.id,
      'recipe_id': recipeId,
    });
  }

  Future<void> removeFavorite(String recipeId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('recipe_id', recipeId);
  }

  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final response = await _supabase
        .from('favorites')
        .select('recipe_id, recipes(*)')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }
}
