import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import 'api_interceptor.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get a custom token from Laravel and sign into Firebase.
  // Firebase authentication is required for multiplayer game access; do not
  // silently downgrade a failed authenticated session to an anonymous user.
  static Future<void> signInWithCustomToken(String laravelToken) async {
    final dio = Dio(
      BaseOptions(baseUrl: AppConfig.baseUrl),
    );
    dio.interceptors.add(ApiInterceptor());

    final response = await dio.post(
      '/auth/firebase-token',
      options: Options(
        headers: {'Authorization': 'Bearer $laravelToken'},
      ),
    );

    final customToken = response.data['firebase_token'] as String;
    await _auth.signInWithCustomToken(customToken);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static String? get uid => _auth.currentUser?.uid;
}
