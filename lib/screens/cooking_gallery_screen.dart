import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cooking_post.dart';
import '../providers/cooking_post_provider.dart';
import 'cooking_post_preview_screen.dart';

class CookingGalleryScreen extends StatelessWidget {
  const CookingGalleryScreen({super.key});

  static const routeName = '/cooking-gallery';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CookingPostProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cooking Gallery',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: provider.posts.isEmpty
            ? const _EmptyGallery()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemCount: provider.posts.length,
                itemBuilder: (context, index) {
                  final post = provider.posts[index];
                  return _GalleryTile(
                    post: post,
                    onOpen: () => Navigator.of(context).pushNamed(
                      CookingPostPreviewScreen.routeName,
                      arguments: post,
                    ),
                    onShare: () => provider.sharePost(post),
                    onDelete: () => provider.deletePost(post),
                  );
                },
              ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.post,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  final CookingPost post;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.memory(post.imageBytes, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      post.recipeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Post actions',
                    onSelected: (value) {
                      if (value == 'share') onShare();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.ios_share),
                          title: Text('Share'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          title: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 54,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No cooking posts yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a food photo from a recipe to build your cooking portfolio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
