import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';

class ResetPage extends StatefulWidget {
  const ResetPage(
      {super.key, required String userName, required String phoneNumber});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final TextEditingController _doublecheckController = TextEditingController();

  bool get _buttonActive =>
      _emailController.text.isNotEmpty &&
      _doublecheckController.text.isNotEmpty;

  void _onTextChanged() {
    setState(() {
      // 텍스트 변경시 버튼 상태 업데이트를 위한 setState
    });
  }

  @override
  void initState() {
    super.initState();
    // 텍스트 필드 변경 리스너 추가
    _emailController.addListener(_onTextChanged);
    _doublecheckController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _emailController.dispose();
    _doublecheckController.dispose();
    super.dispose();
  }

// 비밀번호 재설정 이메일 전송 (핵심 기능)
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      showCustomSnackbar(context, '이메일을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 Firebase의 핵심 기능 - 이게 전부!
      await _auth.sendPasswordResetEmail(email: email);

      showCustomSnackbar(context, '비밀번호 재설정 이메일을 전송했습니다!');

      // 성공 다이얼로그 표시
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = '등록되지 않은 이메일입니다';
          break;
        case 'invalid-email':
          message = '올바르지 않은 이메일 형식입니다';
          break;
        default:
          message = '오류가 발생했습니다: ${e.message}';
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이메일 전송 완료'),
        content:
            const Text('이메일함을 확인하고 링크를 클릭하여 비밀번호를 재설정하세요.\n\n스팸함도 확인해보세요!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 페이지 닫기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('비밀번호 재설정',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0XFFE94A39))),
            ),
            const Text(
              '이메일 입력',
              style: TextStyle(fontSize: 14, color: Colors.black),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0XFFE94A39), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
            ),
            const Text('- 비밀번호 재설정 이메일을 통해 변경해주세요',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            // const Text(
            //   '새로운 비밀번호 확인',
            //   style: TextStyle(fontSize: 14, color: Colors.black),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(vertical: 12),
            //   child: TextField(
            //     controller: _doublecheckController,
            //     decoration: InputDecoration(
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide(color: Colors.grey[400]!),
            //       ),
            //       focusedBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide:
            //             const BorderSide(color: Color(0XFFE94A39), width: 2),
            //       ),
            //       enabledBorder: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(12),
            //         borderSide: BorderSide(color: Colors.grey[400]!),
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.47),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: // 전송 버튼
                        SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0XFFE94A39),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _resetPassword,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                '비밀번호 재설정 이메일 전송',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
