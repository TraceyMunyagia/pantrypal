import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cooking_post.dart';

class CookingPostService {
  static const _postsKey = 'cooking_posts';

  Future<List<CookingPost>> loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_postsKey) ?? [];

    return values
        .map(
          (value) =>
              CookingPost.fromJson(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> savePosts(List<CookingPost> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final values = posts.map((post) => jsonEncode(post.toJson())).toList();
    await prefs.setStringList(_postsKey, values);
  }
}
