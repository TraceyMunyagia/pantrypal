import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/cooking_post.dart';
import '../models/recipe.dart';
import '../services/cooking_post_service.dart';

class CookingPostProvider extends ChangeNotifier {
  CookingPostProvider({
    CookingPostService? cookingPostService,
    ImagePicker? imagePicker,
  }) : _cookingPostService = cookingPostService ?? CookingPostService(),
       _imagePicker = imagePicker ?? ImagePicker() {
    loadPosts();
  }

  final CookingPostService _cookingPostService;
  final ImagePicker _imagePicker;
  final List<CookingPost> _posts = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<CookingPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPosts() async {
    final posts = await _cookingPostService.loadPosts();
    _posts
      ..clear()
      ..addAll(posts);
    notifyListeners();
  }

  Future<CookingPost?> createPostFromRecipe(
    Recipe recipe,
    ImageSource source,
  ) async {
    if (_isLoading) return null;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1800,
      );
      if (image == null) return null;

      final post = CookingPost.fromRecipe(
        recipe: recipe,
        imageBytes: await image.readAsBytes(),
        imageMimeType: image.mimeType ?? 'image/jpeg',
      );

      _posts.insert(0, post);
      await _cookingPostService.savePosts(_posts);
      return post;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(CookingPost post) async {
    _posts.removeWhere((saved) => saved.id == post.id);
    await _cookingPostService.savePosts(_posts);
    notifyListeners();
  }

  Future<void> shareRecipeText(Recipe recipe) async {
    await SharePlus.instance.share(
      ShareParams(
        title: recipe.title,
        subject: recipe.title,
        text: _recipeShareText(recipe),
      ),
    );
  }

  Future<void> sharePost(CookingPost post) async {
    final extension = post.imageMimeType.contains('png') ? 'png' : 'jpg';
    await SharePlus.instance.share(
      ShareParams(
        title: post.recipeTitle,
        subject: post.recipeTitle,
        text: post.toShareText(),
        files: [
          XFile.fromData(
            post.imageBytes,
            mimeType: post.imageMimeType,
            name: 'pantrypal-${post.id}.$extension',
          ),
        ],
        fileNameOverrides: ['pantrypal-${post.id}.$extension'],
      ),
    );
  }

  String _recipeShareText(Recipe recipe) {
    final buffer = StringBuffer()
      ..writeln('${recipe.title} from PantryPal AI')
      ..writeln('Cooking time: ${recipe.cookTime}')
      ..writeln()
      ..writeln('Ingredients:');

    for (final ingredient in recipe.ingredients) {
      buffer.writeln('- $ingredient');
    }

    buffer
      ..writeln()
      ..writeln('Steps:');

    for (var index = 0; index < recipe.steps.length; index += 1) {
      buffer.writeln('${index + 1}. ${recipe.steps[index]}');
    }

    buffer
      ..writeln()
      ..writeln('#PantryPalAI #HomeCooking');

    return buffer.toString().trim();
  }
}
