import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:pet_moment/presentation/pages/login/signup2.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _verificationId = '';
  bool _codeSent = false;
  bool _buttonActive = false;
  bool _isProcessing = false;

  bool _isPhoneNumberValid(String phoneNumber) {
    final phoneRegex = RegExp(r'^010\d{4}\d{4}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  void _checkFormCompletion() {
    setState(() {
      _buttonActive =
          _phoneController.text.isNotEmpty && _codeController.text.isNotEmpty;
    });
  }

  Future<void> _verifyPhoneNumber() async {
    if (!_isPhoneNumberValid(_phoneController.text)) {
      showCustomSnackbar(context, '유효한 전화번호를 입력하세요.');
      return;
    }

    String numericPhoneNumber =
        _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formattedPhoneNumber = '+82${numericPhoneNumber.substring(1)}';

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SignUpPage2()),
          );
        } catch (e) {
          showCustomSnackbar(context, '자동 인증 실패: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        showCustomSnackbar(context, '인증 실패: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
        showCustomSnackbar(context, '인증번호가 전송되었습니다.');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _signInWithSmsCode() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text,
      );
      await _auth.signInWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpPage2()),
      );
    } catch (e) {
      showCustomSnackbar(context, '인증 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드로 인한 UI 깨짐 방지
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: const Text('계정 만들기',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          double padding = screenWidth * 0.07;
          double buttonHeight = 50;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom), // 키보드가 올라오면 패딩 추가
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    '전화번호를 \n입력해 주세요',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0XFFE94A39)),
                  ),
                  const SizedBox(height: 44),
                  _buildTextField(
                      _phoneController, '010-0000-0000', Icons.phone, false),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 39,
                      width: 137,
                      child: OutlinedButton(
                        onPressed: _phoneController.text.isEmpty
                            ? null
                            : () async => await _verifyPhoneNumber(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _phoneController.text.isEmpty
                              ? const Color(0xFFEC766A)
                              : const Color(0XFFE94A39),
                          side: BorderSide.none,
                        ),
                        child: const Text('인증번호 받기',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(_codeController, '인증번호 입력', Icons.lock, true),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonActive
                              ? const Color(0XFFE94A39)
                              : const Color(0XFFEC766A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: (_buttonActive && !_isProcessing)
                            ? () async {
                                setState(() {
                                  _isProcessing = true;
                                });
                                await _signInWithSmsCode();
                              }
                            : null,
                        child: const Text(
                          '다음으로',
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText,
      IconData icon, bool isNumber) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        hintStyle: const TextStyle(
            color: Color(0xFFB1B1B1),
            fontSize: 18,
            fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE4E4E4), width: 2),
          borderRadius: BorderRadius.circular(17),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE94A39), width: 2),
          borderRadius: BorderRadius.circular(17),
        ),
      ),
      onChanged: (value) => _checkFormCompletion(),
    );
  }
}
