import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:pet_moment/presentation/pages/login/create_profile.dart';

class SignUpPage2 extends StatefulWidget {
  const SignUpPage2({Key? key}) : super(key: key);

  @override
  _SignupPage2State createState() => _SignupPage2State();
}

class _SignupPage2State extends State<SignUpPage2> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCheckController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _buttonActive = false;
  bool _isLoading = false;

  bool _isPasswordValid(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]')
        .hasMatch(password);
  }

  void _checkFormCompletion() {
    setState(() {
      _buttonActive = _idController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _passwordCheckController.text.isNotEmpty &&
          _isPasswordValid(_passwordController.text);
    });
  }

  Future<void> _signUpWithEmailPassword() async {
    if (_passwordController.text != _passwordCheckController.text) {
      showCustomSnackbar(context, '비밀번호가 일치하지 않습니다.');
      return;
    }

    if (!_isPasswordValid(_passwordController.text)) {
      showCustomSnackbar(context, '비밀번호는 영문, 숫자, 특수문자를 모두 포함해야 합니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _idController.text.trim();
      final List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        showCustomSnackbar(context, '이미 사용 중인 이메일입니다.');
        setState(() => _isLoading = false);
        return;
      }

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreateProfileScreen(
            email: email,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      showCustomSnackbar(context, _getErrorMessage(e.code));
    } catch (e) {
      showCustomSnackbar(context, '알 수 없는 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'weak-password':
        return '비밀번호는 최소 6자 이상이어야 합니다.';
      default:
        return '오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드로 인한 오버플로우 방지
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        title: const Text(
          '계정 만들기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          double horizontalPadding = screenWidth * 0.07;
          double buttonHeight = 50;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        '아이디 / 비밀번호를 \n입력해 주세요',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFFE94A39),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      TextField(
                        controller: _idController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '이메일',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB1B1B1),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE4E4E4), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE94A39), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onChanged: (_) => _checkFormCompletion(),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          helperText: '영문, 숫자, 특수문자(@\$!%*#?&)를 모두 포함해야 합니다',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB1B1B1),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE4E4E4), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE94A39), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onChanged: (_) => _checkFormCompletion(),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      TextField(
                        controller: _passwordCheckController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호 확인',
                          hintStyle: const TextStyle(
                            color: Color(0xFFB1B1B1),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE4E4E4), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE94A39), width: 2),
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        onChanged: (_) => _checkFormCompletion(),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.05),
                        child: Center(
                          child: SizedBox(
                            width: screenWidth * 0.9,
                            height: buttonHeight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _buttonActive
                                    ? const Color(0XFFE94A39)
                                    : const Color(0XFFEC766A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              onPressed: _buttonActive && !_isLoading
                                  ? _signUpWithEmailPassword
                                  : null,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      '다음으로',
                                      style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
