import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recipe_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/recipe_card.dart';
import 'cooking_gallery_screen.dart';

class RecipeResultScreen extends StatelessWidget {
  const RecipeResultScreen({super.key});

  static const routeName = '/recipe';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final savedRecipes = provider.savedRecipes;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Cooking gallery',
            onPressed: () =>
                Navigator.of(context).pushNamed(CookingGalleryScreen.routeName),
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: themeProvider.toggleDarkMode,
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: savedRecipes.isEmpty
            ? const _EmptySavedRecipes()
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final recipe = savedRecipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        onFavorite: () => provider.toggleFavorite(recipe),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemCount: savedRecipes.length,
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptySavedRecipes extends StatelessWidget {
  const _EmptySavedRecipes();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bookmark_add_outlined,
                  color: colorScheme.onSecondaryContainer,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No saved recipes yet',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Favorite a recipe from chat and it will stay here for quick access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
