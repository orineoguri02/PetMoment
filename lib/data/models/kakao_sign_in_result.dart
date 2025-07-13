import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// Kakao 로그인 결과를 담기 위한 클래스
class KakaoSignInResult {
  final firebase_auth.UserCredential userCredential;
  final String email;
  final String name;

  KakaoSignInResult({
    required this.userCredential,
    required this.email,
    required this.name,
  });
} 