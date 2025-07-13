import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_moment/presentation/pages/home/home.dart';
import 'package:pet_moment/presentation/pages/login/SNSLogin/login_buttion.dart';
import 'package:pet_moment/presentation/pages/login/create_profile.dart';
import 'package:pet_moment/presentation/pages/login/id_login.dart';
import 'package:pet_moment/presentation/pages/login/signup2.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple_sign_in;
import 'package:pet_moment/data/models/kakao_sign_in_result.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  Future<void> _navigateToProfileOrHome({
    required String userId,
    required String email,
    String? authToken,
    String? nickname,
  }) async {
    QuerySnapshot userQuery;
    if (authToken != null) {
      // 익명 로그인인 경우 email과 authToken 모두 일치하는지 확인합니다.
      userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('authToken', isEqualTo: authToken)
          .limit(1)
          .get();
    } else {
      // 일반 로그인인 경우 email만으로 확인합니다.
      userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
    }

    if (userQuery.docs.isNotEmpty) {
      // 사용자가 존재하면 홈 페이지로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    } else {
      // 사용자가 없으면 프로필 생성 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateProfileScreen(email: email),
        ),
      );
    }
  }

  Future<void> _handleLogin(
      Future<void> Function() loginMethod, String errorMessage) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await loginMethod();
    } catch (error) {
      if (!(error.toString().toLowerCase().contains('cancel') ||
          error.toString().toLowerCase().contains('취소') ||
          error.toString().toLowerCase().contains('닫기'))) {
        _showErrorDialog(errorMessage);
      }
      debugPrint('Login error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    await _handleLogin(() async {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final googleAuth = await account.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final authResult = await firebase_auth.FirebaseAuth.instance
            .signInWithCredential(credential);
        await _navigateToProfileOrHome(
          userId: authResult.user?.uid ?? '',
          email: account.email,
          nickname: account.displayName ?? '닉네임 없음',
        );
      }
    }, '구글 로그인 중 오류가 발생했습니다.');
  }

// 1) signInWithKakao: Firestore 쓰기 완전 제거
  Future<KakaoSignInResult> signInWithKakao() async {
    try {
      // 1) 카카오 로그인
      final kakao.OAuthToken token =
          await kakao.UserApi.instance.loginWithKakaoAccount();
      // 2) 사용자 정보 조회
      final kakao.User kakaoUser = await kakao.UserApi.instance.me();
      final email = kakaoUser.kakaoAccount?.email ?? '';
      final name = kakaoUser.kakaoAccount?.profile?.nickname ?? '';
      await isLoginMethodMatching(email, 'Kakao');

      // 3) Firebase 인증
      final credential = firebase_auth.OAuthProvider('oidc.kakao').credential(
        accessToken: token.accessToken,
        idToken: token.idToken ?? '',
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 4) 로그인 결과만 반환 (Firestore 쓰기 없음)
      return KakaoSignInResult(
        userCredential: userCredential,
        email: email,
        name: name,
      );
    } catch (error) {
      throw firebase_auth.FirebaseAuthException(
        code: 'ERROR_KAKAO_LOGIN_FAILED',
        message: 'Failed to login with Kakao: $error',
      );
    }
  }

// 2) _kakaoLogin: 신규/기존 분기만
  Future<void> _kakaoLogin() async {
    await _handleLogin(() async {
      final result = await signInWithKakao();
      final uid = result.userCredential.user!.uid;
      final email = result.email;

      // Firestore 문서 존재 여부 확인
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) {
        // 신규 가입자 → 프로필 생성 화면으로
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateProfileScreen(
              email: email,
              docId: uid,
            ),
          ),
        );
      } else {
        // 기존 가입자 → 홈으로
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(isFromProfileCreation: false),
          ),
        );
      }
    }, '카카오 로그인 중 오류가 발생했습니다.');
  }

  Future<void> _appleLogin() async {
    await _handleLogin(() async {
      if (!await apple_sign_in.TheAppleSignIn.isAvailable()) {
        throw Exception('애플 로그인을 지원하지 않는 기기입니다.');
      }
      final result = await apple_sign_in.TheAppleSignIn.performRequests([
        const apple_sign_in.AppleIdRequest(
          requestedScopes: [
            apple_sign_in.Scope.email,
            apple_sign_in.Scope.fullName,
          ],
        )
      ]);
      if (result.status != apple_sign_in.AuthorizationStatus.authorized ||
          result.credential == null) {
        throw Exception('Apple 로그인 실패');
      }

      // Apple OAuthProvider로 Firebase 로그인
      final oauthCred = OAuthProvider("apple.com").credential(
        idToken: String.fromCharCodes(result.credential!.identityToken!),
        accessToken:
            String.fromCharCodes(result.credential!.authorizationCode!),
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(oauthCred);
      final email = result.credential!.email ??
          userCred.user!.email!; // 가려진 이메일도 Firebase user.email에 저장됨

      await _navigateToProfileOrHome(
        userId: userCred.user!.uid,
        email: email,
      );
    }, '애플 로그인 중 오류가 발생했습니다.');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오류 발생'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 소셜 로그인 버튼들을 구성하는 위젯
  Widget _buildLoginButtons() {
    return Column(
      children: [
        LoginButton(
          color: const Color(0xFFFFE812),
          image: Image.asset('assets/kakao.png'),
          text: "카카오로 시작하기",
          textColor: Colors.black,
          onPressed: _kakaoLogin,
        ),
        const SizedBox(height: 10),
        LoginButton(
          color: Colors.white,
          image: Image.asset('assets/goo.png'),
          text: "구글로 시작하기",
          textColor: Colors.black,
          onPressed: _googleLogin,
          borderColor: const Color(0XFFD5D5D5),
        ),
        const SizedBox(height: 10),
        LoginButton(
          color: const Color(0XFF111111),
          image: Image.asset('assets/Alogo.png'),
          text: "Apple로 시작하기",
          textColor: Colors.white,
          onPressed: _appleLogin,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text(
              "로그인",
              style: TextStyle(
                fontSize: 16,
                color: Color(0XFFE94A39),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Color(0XFFE94A39),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUpPage2()),
              );
            },
            child: const Text(
              "회원가입",
              style: TextStyle(
                fontSize: 16,
                color: Color(0XFFE94A39),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Color(0XFFE94A39),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/gradient.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: Transform.scale(
                  scale: 1.0,
                  child: Image.asset(
                    'assets/login.png',
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
              const Text(
                "반려동물과 함께하는\n소중한 순간들",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFFE94A39),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "폴라로이드 형식으로 소중한 일상을\n더욱 특별하게 간직해요 :)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF6E6E6E),
                ),
              ),
              const SizedBox(height: 30),
              _buildLoginButtons(),
              const SizedBox(height: 30),
              _buildBottomNavigation(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// Firebase Firestore에 사용자 정보를 추가하는 함수
Future<void> addUserToFirestore(firebase_auth.User user, String email,
    String name, String loginMethod) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();
  if (!docSnapshot.exists) {
    await userDoc.set({
      'email': email,
      'name': name,
      'loginMethod': loginMethod,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// 사용자 로그인 방식이 일치하는지 확인하는 함수
Future<void> isLoginMethodMatching(String email, String loginMethod) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    if (data.containsKey('loginMethod') && data['loginMethod'] != loginMethod) {
      throw Exception("로그인 방법이 일치하지 않습니다. 기존 가입한 방법으로 로그인 해주세요.");
    }
  }
}
