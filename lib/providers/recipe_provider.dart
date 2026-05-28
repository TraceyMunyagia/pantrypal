import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../models/recipe.dart';
import '../services/ai_recipe_service.dart';
import '../services/saved_recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  RecipeProvider({
    AiRecipeService? recipeService,
    SavedRecipeService? savedRecipeService,
  }) : _recipeService = recipeService ?? AiRecipeService(),
       _savedRecipeService = savedRecipeService ?? SavedRecipeService() {
    _loadSavedRecipes();
  }

  final AiRecipeService _recipeService;
  final SavedRecipeService _savedRecipeService;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hi, I am PantryPal AI. Tell me what ingredients you have and I will turn them into a recipe.',
      isUser: false,
      createdAt: DateTime.now(),
    ),
  ];
  final List<Recipe> _savedRecipes = [];

  Recipe? _recipe;
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<Recipe> get savedRecipes => List.unmodifiable(_savedRecipes);
  Recipe? get recipe => _recipe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String value) async {
    final prompt = value.trim();
    if (prompt.isEmpty || _isLoading) return;

    _messages.add(
      ChatMessage(text: prompt, isUser: true, createdAt: DateTime.now()),
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _recipeService.sendRecipePrompt(prompt);
      final parsedRecipe = Recipe.fromAiText(response);
      _recipe = _applySavedState(parsedRecipe);
      _messages.add(
        ChatMessage(
          text: response,
          isUser: false,
          createdAt: DateTime.now(),
          recipe: _recipe,
        ),
      );
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _messages.add(
        ChatMessage(
          text: 'I could not generate a recipe. $_errorMessage',
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateRecipe() async {
    await sendMessage('Generate a simple recipe using pantry staples.');
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final index = _savedRecipes.indexWhere(
      (saved) =>
          saved.createdAt == recipe.createdAt || saved.title == recipe.title,
    );

    if (index == -1) {
      final savedRecipe = recipe.copyWith(isFavorite: true);
      _savedRecipes.insert(0, savedRecipe);
      _recipe = _recipe?.createdAt == recipe.createdAt ? savedRecipe : _recipe;
      _replaceRecipeInMessages(recipe, savedRecipe);
    } else {
      _savedRecipes.removeAt(index);
      final unsavedRecipe = recipe.copyWith(isFavorite: false);
      if (_recipe?.createdAt == recipe.createdAt) {
        _recipe = unsavedRecipe;
      }
      _replaceRecipeInMessages(recipe, unsavedRecipe);
    }

    await _savedRecipeService.saveRecipes(_savedRecipes);
    notifyListeners();
  }

  Future<void> _loadSavedRecipes() async {
    final recipes = await _savedRecipeService.loadRecipes();
    _savedRecipes
      ..clear()
      ..addAll(recipes);
    notifyListeners();
  }

  Recipe _applySavedState(Recipe recipe) {
    final isSaved = _savedRecipes.any((saved) => saved.title == recipe.title);
    return recipe.copyWith(isFavorite: isSaved);
  }

  void _replaceRecipeInMessages(Recipe oldRecipe, Recipe newRecipe) {
    for (var index = 0; index < _messages.length; index += 1) {
      final messageRecipe = _messages[index].recipe;
      if (messageRecipe == null) continue;
      if (messageRecipe.createdAt == oldRecipe.createdAt ||
          messageRecipe.title == oldRecipe.title) {
        _messages[index] = _messages[index].copyWith(recipe: newRecipe);
      }
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}
