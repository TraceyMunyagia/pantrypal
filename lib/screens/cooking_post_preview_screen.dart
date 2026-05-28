import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cooking_post.dart';
import '../providers/cooking_post_provider.dart';

class CookingPostPreviewScreen extends StatelessWidget {
  const CookingPostPreviewScreen({super.key});

  static const routeName = '/cooking-post-preview';

  @override
  Widget build(BuildContext context) {
    final post = ModalRoute.of(context)?.settings.arguments as CookingPost?;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Post',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: post == null
            ? const Center(child: Text('No cooking post selected.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _PostPreviewCard(post: post),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<CookingPostProvider>().sharePost(post),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share Post'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({required this.post});

  final CookingPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.memory(post.imageBytes, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.recipeTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.cookTime,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Ingredients'),
                const SizedBox(height: 8),
                ...post.ingredients.map(
                  (ingredient) => _BulletLine(ingredient),
                ),
                const SizedBox(height: 16),
                const _SectionTitle(title: 'Steps'),
                const SizedBox(height: 8),
                ...post.steps.asMap().entries.map(
                  (entry) =>
                      _NumberedLine(number: entry.key + 1, text: entry.value),
                ),
              ],
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
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '- ',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
