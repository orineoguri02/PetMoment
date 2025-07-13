import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 첫 빌드 이후에 소셜 로그인 체크 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserLoginMethod();
    });
  }

  /// 기존에는 providerData에 'kakao.com', 'google.com', 'apple.com' 등을 확인했지만,
  /// 카카오 로그인은 익명 로그인으로 진행되므로,
  /// 'password' provider가 없거나, 사용자가 익명로그인인 경우 소셜 로그인으로 간주합니다.
  Future<void> _checkUserLoginMethod() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // providerData에 등록된 providerId 리스트
    final providers =
        user.providerData.map((userInfo) => userInfo.providerId).toList();

    // 비밀번호 로그인(providerId == 'password')이 없는 경우 또는 익명 로그인인 경우
    if (user.isAnonymous || !providers.contains('password')) {
      if (mounted) {
        _showSocialLoginDialog();
      }
    }
  }

  void _showSocialLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFFE94A39),
                size: 36,
              ),
              SizedBox(height: 16),
              Text(
                '소셜 계정 안내',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '소셜 로그인(카카오/구글/애플)으로 가입한 계정은\n해당 서비스에서 비밀번호를 변경해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 현재 비밀번호 검증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // 새 비밀번호로 변경
      await user.updatePassword(_newPasswordController.text);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'lastPasswordChange': FieldValue.serverTimestamp()});

      if (mounted) {
        showCustomSnackbar(context, '비밀번호가 성공적으로 변경되었습니다.');

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, '현재 비밀번호가 올바르지 않거나 비밀번호 변경 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '계정 비밀번호 변경',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE94A39),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFE94A39),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '소중한 계정 보호를 위해\n비밀번호를 변경해 주세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '사용중인 비밀번호를 입력해주세요',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: '현재 비밀번호',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '현재 비밀번호를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '새 비밀번호를 입력해주세요 (영문+숫자+특수문자 포함 8-32자)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: '새 비밀번호',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '새 비밀번호를 입력해주세요';
                        }
                        if (value.length < 8 || value.length > 32) {
                          return '비밀번호는 8-32자 사이여야 합니다';
                        }
                        if (!RegExp(
                                r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]+$')
                            .hasMatch(value)) {
                          return '영문, 숫자, 특수문자를 모두 포함해야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '새 비밀번호를 한번 더 입력해주세요',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: '새 비밀번호 확인',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _newPasswordController.text) {
                          return '새 비밀번호가 일치하지 않습니다';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94A39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '변경하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
