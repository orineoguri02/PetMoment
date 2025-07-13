import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple_sign_in;
import '../models/index.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 사용자 가져오기
  static User? get currentUser => _auth.currentUser;

  // 사용자 상태 스트림
  static Stream<User?> get userStream => _auth.authStateChanges();

  // 이메일/패스워드 로그인
  static Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 이메일/패스워드 회원가입
  static Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // 구글 로그인
  static Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in aborted');
    
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    return await _auth.signInWithCredential(credential);
  }

  // 카카오 로그인
  static Future<KakaoSignInResult> signInWithKakao() async {
    final bool isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();
    
    if (isKakaoTalkInstalled) {
      await kakao.UserApi.instance.loginWithKakaoTalk();
    } else {
      await kakao.UserApi.instance.loginWithKakaoAccount();
    }

    final kakao.User user = await kakao.UserApi.instance.me();
    
    final email = user.kakaoAccount?.email ?? '';
    final name = user.kakaoAccount?.profile?.nickname ?? '';
    
    final customToken = await _createCustomToken(user.id.toString(), email, name);
    final userCredential = await _auth.signInWithCustomToken(customToken);
    
    return KakaoSignInResult(
      userCredential: userCredential,
      email: email,
      name: name,
    );
  }

  // 애플 로그인
  static Future<UserCredential> signInWithApple() async {
    final result = await apple_sign_in.TheAppleSignIn.performRequests([
      const apple_sign_in.AppleIdRequest(
        requestedScopes: [
          apple_sign_in.Scope.email,
          apple_sign_in.Scope.fullName,
        ],
      )
    ]);

    switch (result.status) {
      case apple_sign_in.AuthorizationStatus.authorized:
        final appleIdCredential = result.credential!;
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken: String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        return await _auth.signInWithCredential(oauthCredential);
      case apple_sign_in.AuthorizationStatus.error:
        throw Exception('Apple sign in error: ${result.error}');
      case apple_sign_in.AuthorizationStatus.cancelled:
        throw Exception('Apple sign in cancelled');
    }
  }

  // 패스워드 재설정
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 로그아웃
  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // 계정 삭제
  static Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  // 패스워드 변경
  static Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // 커스텀 토큰 생성 (카카오 로그인용)
  static Future<String> _createCustomToken(String uid, String email, String name) async {
    // 실제 구현에서는 서버에서 커스텀 토큰을 생성해야 합니다.
    // 이는 예시 코드입니다.
    throw UnimplementedError('Custom token creation should be implemented on server side');
  }
} 