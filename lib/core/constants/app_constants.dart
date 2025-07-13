import 'package:flutter_dotenv/flutter_dotenv.dart';

// 앱 기본 정보
class AppConstants {
  static const String appName = 'Pet Moment';
  static const String appVersion = '1.0.0+1';
  
  // 카카오 SDK 키 (환경변수에서 읽기)
  static String get kakaoNativeAppKey => dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  
  // 기본 이미지 경로
  static const String defaultProfileImage = 'assets/default_profile.jpg';
  static const String defaultAlbumCover = 'assets/defaultAlbumCover.png';
  static const String defaultAlbumCoverPlus = 'assets/defaultcoverplus.png';
  static const String logoImage = 'assets/logo.png';
  static const String logoGif = 'assets/loogo.gif';
  static const String gradientBackground = 'assets/gradient.png';
  static const String loginBackground = 'assets/login.png';
  
  // 기본 설정값
  static const int gifFrameRate = 12;
  static const int splashDelayMs = 1000;
  static const int imageCompressQuality = 85;
  static const int imageMinWidth = 1920;
  static const int imageMinHeight = 1080;
  
  // 컬렉션 이름
  static const String usersCollection = 'users';
  static const String albumsCollection = 'albums';
  static const String polaroidCollection = 'polaroid';
  static const String shoppingCollection = 'Shopping';
  static const String addressesCollection = 'addresses';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  
  // 스토리지 경로
  static const String profilesPath = 'profiles';
  static const String albumsPath = 'albums';
  static const String polaroidsPath = 'polaroids';
  static const String legacyAlbumPath = 'Album';
  
  // 페이지 라우트
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String homePageRoute = '/home';
  static const String firstAlbumRoute = '/first';
  
  // 에러 메시지
  static const String networkError = '네트워크 오류가 발생했습니다.';
  static const String authError = '인증 오류가 발생했습니다.';
  static const String uploadError = '업로드 중 오류가 발생했습니다.';
  static const String deleteError = '삭제 중 오류가 발생했습니다.';
  static const String saveError = '저장 중 오류가 발생했습니다.';
  
  // 성공 메시지
  static const String uploadSuccess = '업로드가 완료되었습니다.';
  static const String deleteSuccess = '삭제가 완료되었습니다.';
  static const String saveSuccess = '저장이 완료되었습니다.';
  static const String accountDeleted = '계정이 삭제되었습니다.';
  static const String passwordResetSent = '비밀번호 재설정 이메일이 발송되었습니다.';
  
  // 폰트 이름
  static const String pretendardFont = 'Pretendard Variable';
  static const String hsYujiFont = 'HS유지체';
  static const String bagelFont = 'BagelFatOne-Regular';
} 