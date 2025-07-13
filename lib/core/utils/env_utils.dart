import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvUtils {
  // Kakao SDK
  static String get kakaoNativeAppKey => dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  
  // Firebase Web
  static String get firebaseWebApiKey => dotenv.env['FIREBASE_WEB_API_KEY'] ?? '';
  static String get firebaseWebAppId => dotenv.env['FIREBASE_WEB_APP_ID'] ?? '';
  static String get firebaseWebMessagingSenderId => dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseWebProjectId => dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? '';
  static String get firebaseWebAuthDomain => dotenv.env['FIREBASE_WEB_AUTH_DOMAIN'] ?? '';
  static String get firebaseWebStorageBucket => dotenv.env['FIREBASE_WEB_STORAGE_BUCKET'] ?? '';
  
  // Firebase iOS
  static String get firebaseIosApiKey => dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get firebaseIosAppId => dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String get firebaseIosMessagingSenderId => dotenv.env['FIREBASE_IOS_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseIosProjectId => dotenv.env['FIREBASE_IOS_PROJECT_ID'] ?? '';
  static String get firebaseIosStorageBucket => dotenv.env['FIREBASE_IOS_STORAGE_BUCKET'] ?? '';
  static String get firebaseIosClientId => dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '';
  static String get firebaseIosBundleId => dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';
  
  // Firebase macOS
  static String get firebaseMacosApiKey => dotenv.env['FIREBASE_MACOS_API_KEY'] ?? '';
  static String get firebaseMacosAppId => dotenv.env['FIREBASE_MACOS_APP_ID'] ?? '';
  static String get firebaseMacosMessagingSenderId => dotenv.env['FIREBASE_MACOS_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseMacosProjectId => dotenv.env['FIREBASE_MACOS_PROJECT_ID'] ?? '';
  static String get firebaseMacosStorageBucket => dotenv.env['FIREBASE_MACOS_STORAGE_BUCKET'] ?? '';
  static String get firebaseMacosClientId => dotenv.env['FIREBASE_MACOS_CLIENT_ID'] ?? '';
  static String get firebaseMacosBundleId => dotenv.env['FIREBASE_MACOS_BUNDLE_ID'] ?? '';
  
  // Firebase Windows
  static String get firebaseWindowsApiKey => dotenv.env['FIREBASE_WINDOWS_API_KEY'] ?? '';
  static String get firebaseWindowsAppId => dotenv.env['FIREBASE_WINDOWS_APP_ID'] ?? '';
  static String get firebaseWindowsMessagingSenderId => dotenv.env['FIREBASE_WINDOWS_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseWindowsProjectId => dotenv.env['FIREBASE_WINDOWS_PROJECT_ID'] ?? '';
  static String get firebaseWindowsAuthDomain => dotenv.env['FIREBASE_WINDOWS_AUTH_DOMAIN'] ?? '';
  static String get firebaseWindowsStorageBucket => dotenv.env['FIREBASE_WINDOWS_STORAGE_BUCKET'] ?? '';
  
  // 환경변수 존재 여부 확인
  static bool hasRequiredEnvVars() {
    final required = [
      'KAKAO_NATIVE_APP_KEY',
      'FIREBASE_WEB_API_KEY',
      'FIREBASE_IOS_API_KEY',
      'FIREBASE_MACOS_API_KEY',
      'FIREBASE_WINDOWS_API_KEY',
    ];
    
    for (final key in required) {
      if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
        print('Missing required environment variable: $key');
        return false;
      }
    }
    return true;
  }
  
  // 환경변수 값 가져오기 (기본값 포함)
  static String getEnvVar(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }
  
  // 개발 환경 여부 확인
  static bool get isDevelopment => getEnvVar('ENVIRONMENT') == 'development';
  static bool get isProduction => getEnvVar('ENVIRONMENT') == 'production';
  static bool get isStaging => getEnvVar('ENVIRONMENT') == 'staging';
  
  // 디버그 모드에서 환경변수 출력
  static void printEnvVars() {
    if (isDevelopment) {
      print('=== Environment Variables ===');
      print('KAKAO_NATIVE_APP_KEY: ${kakaoNativeAppKey.isNotEmpty ? "✓ Set" : "✗ Missing"}');
      print('FIREBASE_WEB_API_KEY: ${firebaseWebApiKey.isNotEmpty ? "✓ Set" : "✗ Missing"}');
      print('FIREBASE_IOS_API_KEY: ${firebaseIosApiKey.isNotEmpty ? "✓ Set" : "✗ Missing"}');
      print('=============================');
    }
  }
} 