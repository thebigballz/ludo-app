import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import 'api_interceptor.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get a custom token from Laravel and sign into Firebase
  static Future<void> signInWithCustomToken(String laravelToken) async {
    try {
      // Get Firebase custom token from Laravel
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
    } catch (e) {
      // Fall back to anonymous auth if custom token fails
      await _auth.signInAnonymously();
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static User? get currentUser => _auth.currentUser;

  static String? get uid => _auth.currentUser?.uid;
}