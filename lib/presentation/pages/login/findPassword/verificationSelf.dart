import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_moment/presentation/pages/login/findPassword/agreeP1.dart';
import 'package:pet_moment/presentation/pages/login/findPassword/agreeP2.dart';
import 'package:pet_moment/presentation/pages/login/findPassword/agreeP3.dart';
import 'package:pet_moment/presentation/pages/login/findPassword/agreeP4.dart';
import 'package:pet_moment/presentation/pages/login/findPassword/reset.dart';

class VerificationSelfPage extends StatefulWidget {
  const VerificationSelfPage({super.key});

  @override
  State<VerificationSelfPage> createState() => _VerificationSelfPageState();
}

class _VerificationSelfPageState extends State<VerificationSelfPage> {
  bool _isChecked = false;
  bool _isVerificationSent = false;
  bool _isVerificationCompleted = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _residentnumberController1 =
      TextEditingController();
  final TextEditingController _residentnumberController2 =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _certificationController =
      TextEditingController();

  // Firebase Auth 관련
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  // 타이머 관련 변수
  int _verificationTimer = 180; // 3분 = 180초
  bool _isTimerActive = false;

  // 버튼 활성화 조건
  bool get _canSendVerification =>
      _isChecked &&
      _nameController.text.isNotEmpty &&
      _residentnumberController1.text.length == 6 &&
      _residentnumberController2.text.length == 7 &&
      _phoneController.text.length >= 10;

  bool get _buttonActive => _canSendVerification && _isVerificationCompleted;

  void _updateCheckState() {
    setState(() {
      _isChecked = !_isChecked;
    });
  }

  void _onTextChanged() {
    setState(() {
      // 텍스트 변경시 버튼 상태 업데이트를 위한 setState
    });
  }

  // 휴대폰 번호 포맷팅 (국가코드 추가)
  String _formatPhoneNumber(String phoneNumber) {
    // 한국 국가코드 +82 추가 및 첫 번째 0 제거
    if (phoneNumber.startsWith('0')) {
      return '+82${phoneNumber.substring(1)}';
    }
    return '+82$phoneNumber';
  }

  // Firebase Phone Auth - 인증번호 전송
  Future<void> _sendVerificationCode() async {
    if (!_canSendVerification || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String formattedPhone = _formatPhoneNumber(_phoneController.text);

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 완료 (Android only)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
          });
          _showErrorMessage('인증번호 전송 실패: ${_getErrorMessage(e.code)}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isVerificationSent = true;
            _isLoading = false;
            _isTimerActive = true;
            _verificationTimer = 180;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('인증번호가 전송되었습니다.'),
              backgroundColor: Color(0XFFE94A39),
            ),
          );

          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('인증번호 전송 중 오류가 발생했습니다.');
    }
  }

  // Firebase Phone Auth - 인증번호 확인
  Future<void> _verifyCode() async {
    if (_certificationController.text.length != 6 || _verificationId == null) {
      _showErrorMessage('6자리 인증번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _certificationController.text,
      );

      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('잘못된 인증번호입니다.');
    }
  }

  // Firebase 인증 처리
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        setState(() {
          _isVerificationCompleted = true;
          _isTimerActive = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('본인인증이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 인증 완료 후 Firebase 사용자 로그아웃 (임시 인증용이므로)
        await _auth.signOut();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('인증 처리 중 오류가 발생했습니다.');
    }
  }

  // 에러 메시지 처리
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return '잘못된 휴대폰 번호입니다.';
      case 'too-many-requests':
        return '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'invalid-verification-code':
        return '잘못된 인증번호입니다.';
      case 'session-expired':
        return '인증 세션이 만료되었습니다. 다시 시도해주세요.';
      default:
        return '인증 중 오류가 발생했습니다.';
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 타이머 시작
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isTimerActive && _verificationTimer > 0) {
        setState(() {
          _verificationTimer--;
        });
        _startTimer();
      } else if (_verificationTimer == 0) {
        setState(() {
          _isTimerActive = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증시간이 만료되었습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  // 인증번호 재전송
  Future<void> _resendVerificationCode() async {
    await _sendVerificationCode();
  }

  // 타이머 표시 형식
  String _formatTimer(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _residentnumberController1.addListener(_onTextChanged);
    _residentnumberController2.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _certificationController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _residentnumberController1.dispose();
    _residentnumberController2.dispose();
    _phoneController.dispose();
    _certificationController.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('본인확인을 위해 \n인증을 진행해 주세요',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0XFFE94A39))),
              ),
              _renderCheckbox(),
              _buildListTiles(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(),
              ),

              // 이름 입력
              _buildTextField(
                controller: _nameController,
                hintText: '이름을 입력하세요',
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 15),

              // 주민번호 입력
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _residentnumberController1,
                      hintText: '주민번호 앞 6자리',
                      maxLength: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('ㅡ', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _residentnumberController2,
                      hintText: '뒤 7자리',
                      isPassword: true,
                      maxLength: 7,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 휴대폰 번호 입력
              _buildTextField(
                controller: _phoneController,
                hintText: '휴대폰 번호 (- 없이 입력)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),

              // 인증번호 전송/입력
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _certificationController,
                      hintText: _isVerificationSent ? '인증번호 6자리 입력' : '인증번호',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: _isVerificationSent && !_isLoading,
                      suffix: _isTimerActive
                          ? Text(
                              _formatTimer(_verificationTimer),
                              style: const TextStyle(
                                color: Color(0XFFE94A39),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 80,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVerificationCompleted
                            ? Colors.green
                            : (_canSendVerification && !_isLoading)
                                ? const Color(0XFFE94A39)
                                : const Color(0XFFEC766A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : _isVerificationCompleted
                              ? null
                              : _isVerificationSent
                                  ? _verifyCode
                                  : _sendVerificationCode,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _isVerificationCompleted
                                  ? '완료'
                                  : _isVerificationSent
                                      ? '확인'
                                      : '전송',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              // 재전송 버튼
              if (_isVerificationSent &&
                  !_isTimerActive &&
                  !_isVerificationCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : _resendVerificationCode,
                        child: const Text(
                          '인증번호 재전송',
                          style: TextStyle(
                            color: Color(0XFFE94A39),
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  '- 타인의 개인정보를 도용하여 가입한 경우, 서비스 이용 제한 및 법적 제재를 받으실 수 있습니다.\n- 인증번호는 3분간 유효합니다.\n- SMS 요금이 발생할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0XFFACACAC)),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.08),

              // 다음 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
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
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResetPage(
                                        // 인증된 사용자 정보 전달
                                        userName: _nameController.text,
                                        phoneNumber: _phoneController.text,
                                        // 추가로 주민번호도 전달 가능 (보안상 해시 처리 권장)
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  '다음',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
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
      ),
    );
  }

  Widget _renderCheckbox() {
    return GestureDetector(
      onTap: _updateCheckState,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isChecked
                    ? const Color(0XFFE94A39)
                    : const Color(0XFFE6E6E6),
              ),
              child: Icon(
                Icons.check,
                color: _isChecked ? Colors.white : const Color(0XFF000000),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('[필수] 본인 인증 서비스 약관 전체 동의',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildListTiles() {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          ListTile(
            leading: const Text(
              '휴대폰 본인 인증 서비스 이용약관 동의',
              style: TextStyle(color: Color(0XFF1F1F1F), fontSize: 18),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0XFF1F1F1F),
              size: 15,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Agreep1Page(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Text(
              '휴대폰 통신사 이동약관 동의',
              style: TextStyle(color: Color(0XFF1F1F1F), fontSize: 18),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0XFF1F1F1F),
              size: 15,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Agreep2Page(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Text(
              '개인정보 제공 및 이용동의',
              style: TextStyle(color: Color(0XFF1F1F1F), fontSize: 18),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0XFF1F1F1F),
              size: 15,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Agreep3Page(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Text(
              '고유식별정보 처리',
              style: TextStyle(color: Color(0XFF1F1F1F), fontSize: 18),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0XFF1F1F1F),
              size: 15,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Agreep4Page(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool enabled = true,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      obscuringCharacter: '*',
      keyboardType: keyboardType,
      maxLength: maxLength,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16,
        color: enabled ? Colors.black : Colors.grey,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: suffix,
              )
            : null,
        border: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0XFFE94A39), width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        counterText: '', // 글자수 카운터 숨김
      ),
    );
  }
}
