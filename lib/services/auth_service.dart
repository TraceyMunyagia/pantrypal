import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
  }) async {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username, 'full_name': fullName},
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updateProfile({
    String? username,
    String? fullName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      ...?username == null ? null : {'username': username},
      ...?fullName == null ? null : {'full_name': fullName},
      ...?avatarUrl == null ? null : {'avatar_url': avatarUrl},
    };
    if (data.isNotEmpty) {
      await _supabase.auth.updateUser(UserAttributes(data: data));
    }
  }

  Future<void> updateEmail(String email) async {
    await _supabase.auth.updateUser(UserAttributes(email: email));
  }

  Future<void> updatePassword(String password) async {
    await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  Future<String> uploadProfilePhoto(XFile photo) async {
    final user = currentUser;
    if (user == null) throw Exception('User is not authenticated');

    final bytes = await photo.readAsBytes();
    final extension = photo.name.contains('.')
        ? photo.name.split('.').last.toLowerCase()
        : 'jpg';
    final path =
        '${user.id}/avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/$extension',
          ),
        );
    final url = _supabase.storage.from('avatars').getPublicUrl(path);
    await updateProfile(avatarUrl: url);
    return url;
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;
}
