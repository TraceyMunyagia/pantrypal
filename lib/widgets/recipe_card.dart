import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/cooking_post_provider.dart';
import '../screens/cooking_post_preview_screen.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({required this.recipe, required this.onFavorite, super.key});

  final Recipe recipe;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  recipe.title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy recipe',
                onPressed: () => _copyRecipe(context),
                icon: Icon(Icons.copy, color: colorScheme.primary),
              ),
              IconButton(
                tooltip: 'Share recipe',
                onPressed: () =>
                    context.read<CookingPostProvider>().shareRecipeText(recipe),
                icon: Icon(Icons.ios_share, color: colorScheme.primary),
              ),
              IconButton(
                tooltip: recipe.isFavorite
                    ? 'Remove favorite'
                    : 'Save favorite',
                onPressed: onFavorite,
                icon: Icon(
                  recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: recipe.isFavorite
                      ? colorScheme.error
                      : colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoPill(icon: Icons.schedule, label: recipe.cookTime),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showPhotoSourceSheet(context),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Add Food Photo'),
          ),
          const SizedBox(height: 14),
          Text(
            recipe.description,
            style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Ingredients'),
          const SizedBox(height: 8),
          if (recipe.ingredients.isEmpty)
            const Text('No ingredients detected.')
          else
            ...recipe.ingredients.map((item) => _BulletLine(text: item)),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Steps'),
          const SizedBox(height: 8),
          if (recipe.steps.isEmpty)
            Text(recipe.rawText)
          else
            ...recipe.steps.asMap().entries.map(
              (entry) =>
                  _NumberedLine(number: entry.key + 1, text: entry.value),
            ),
        ],
      ),
    );
  }

  Future<void> _copyRecipe(BuildContext context) async {
    final buffer = StringBuffer()
      ..writeln(recipe.title)
      ..writeln('Cooking time: ${recipe.cookTime}')
      ..writeln()
      ..writeln(recipe.description)
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

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Recipe copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showPhotoSourceSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null || !context.mounted) return;

    final provider = context.read<CookingPostProvider>();
    final post = await provider.createPostFromRecipe(recipe, source);

    if (!context.mounted) return;
    if (post == null) {
      final message = provider.errorMessage ?? 'No photo selected.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      return;
    }

    Navigator.of(
      context,
    ).pushNamed(CookingPostPreviewScreen.routeName, arguments: post);
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSecondaryContainer, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: TextStyle(
        color: colorScheme.primary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('- ', style: TextStyle(color: colorScheme.primary)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
