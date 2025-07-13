import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:pet_moment/presentation/pages/home/first_album.dart';
import 'package:provider/provider.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'index.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env.local");

  cameras = await availableCameras();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  KakaoSdk.init(nativeAppKey: AppConstants.kakaoNativeAppKey);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<List<CameraDescription>>.value(value: cameras),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        fontFamily: AppConstants.pretendardFont,
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          elevation: 1,
        ),
        colorScheme: AppColors.lightColorScheme,
      ),
      initialRoute: AppConstants.homeRoute,
      routes: {
        //AppConstants.homeRoute: (context) => const VerificationSelfPage(),
        AppConstants.homeRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.homePageRoute: (context) => const HomePage(),
        AppConstants.firstAlbumRoute: (context) => const FirstAlbum(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateBasedOnAuthState();
    });
  }

  Future<void> _navigateBasedOnAuthState() async {
    final user = FirebaseAuth.instance.currentUser;
    await Future.delayed(
        const Duration(milliseconds: AppConstants.splashDelayMs));

    if (user != null) {
      Navigator.of(context).pushReplacementNamed(AppConstants.homePageRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: GifView.asset(
                  AppConstants.logoGif,
                  frameRate: AppConstants.gifFrameRate,
                  height: MediaQuery.of(context).size.width * 0.6,
                  width: MediaQuery.of(context).size.width * 0.55,
                  fit: BoxFit.cover,
                  loop: false,
                ),
              ),
              Container(
                  height: MediaQuery.of(context).size.width * 0.4,
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: Image.asset(AppConstants.logoImage))
            ],
          ),
        ),
      ),
    );
  }
}
