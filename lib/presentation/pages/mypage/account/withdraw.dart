import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:pet_moment/presentation/pages/login/SNSLogin/login.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// 1) Firestore 문서 + 모든 서브컬렉션을 재귀 삭제
  Future<void> _deleteDocumentRecursively(DocumentReference docRef) async {
    const sub = ['albums', 'addresses', 'polaroid'];
    for (final name in sub) {
      final snap = await docRef.collection(name).get();
      for (final subDoc in snap.docs) {
        await _deleteDocumentRecursively(subDoc.reference);
        await subDoc.reference.delete();
      }
    }
    await docRef.delete();
  }

  /// 2) users/{uid} 및 전역 컬렉션(posts/comments/likes) 데이터 삭제
  Future<void> _deleteAllUserData(String uid) async {
    // 2-1) 전역 컬렉션에서 userId 일치 문서 삭제
    for (final col in ['posts', 'comments', 'likes']) {
      final snap = await _firestore
          .collection(col)
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in snap.docs) {
        await _deleteDocumentRecursively(doc.reference);
      }
    }

    // 2-2) users/{uid} 문서와 그 아래 서브컬렉션 전부 삭제
    final userRef = _firestore.collection('users').doc(uid);
    await _deleteDocumentRecursively(userRef);
  }

  /// 3) Storage 내 특정 경로(폴더) 이하 모든 파일·폴더 재귀 삭제
  Future<void> _deleteStorageRecursively(String path) async {
    final ref = _storage.ref(path);
    final result = await ref.listAll();

    // 3-1) 이 폴더 안의 모든 파일 삭제
    for (final item in result.items) {
      await item.delete();
    }
    // 3-2) 하위 폴더(prefixes)도 재귀 삭제
    for (final prefix in result.prefixes) {
      await _deleteStorageRecursively(prefix.fullPath);
    }
  }

  /// 4) 사용자 관련 Storage 전체 삭제
  Future<void> _deleteAllStorageFiles() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 이메일이 있으면 이메일, 없으면 uid 사용
    final emailOrId = user.email ?? user.uid;

    // 실제 업로드 경로에 맞춰 여기에 prefix를 추가하세요.
    await _deleteStorageRecursively('Album/$emailOrId');
    // 예) 프로필 이미지를 Profile 폴더에 올렸다면:
    // await _deleteStorageRecursively('Profile/$emailOrId');
  }

  /// 5) Firestore + Storage + Auth 삭제 → 로그아웃 → 로그인 화면 이동
  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Firestore 데이터 삭제
    await _deleteAllUserData(user.uid);
    // Storage 파일 삭제
    await _deleteAllStorageFiles();

    // Auth 계정 삭제 (재인증 오류 등은 무시)
    try {
      await user.delete();
    } catch (_) {}

    // 로그아웃 및 로그인 화면으로
    await _auth.signOut();
    showCustomSnackbar(context, '계정이 삭제되었습니다.');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// 탈퇴 버튼 클릭 → 확인 페이지로 이동
  void _navigateToConfirmation() {
    final user = _auth.currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WithdrawConfirmationPage(
          deleteAccount: _deleteAccount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '내 계정',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 0,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '계정 탈퇴',
              style: TextStyle(
                color: Color(0xFF2D2D2D),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '계정을 탈퇴하면 모든 데이터가 삭제되며 복구할 수 없습니다.',
              style: TextStyle(
                color: Color(0xFF818181),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _navigateToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC5524C),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '계정 탈퇴하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WithdrawConfirmationPage extends StatefulWidget {
  final Future<void> Function() deleteAccount;

  const WithdrawConfirmationPage({
    super.key,
    required this.deleteAccount,
  });

  @override
  _WithdrawConfirmationPageState createState() =>
      _WithdrawConfirmationPageState();
}

class _WithdrawConfirmationPageState extends State<WithdrawConfirmationPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserNickname;

  @override
  void initState() {
    super.initState();
    _loadUserNickname();
  }

  Future<void> _loadUserNickname() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _currentUserNickname = doc.data()?['nickname'] as String?;
      });
    } catch (e) {
      showCustomSnackbar(context, '사용자 정보를 불러오는 데 실패했습니다.');
    }
  }

  Future<void> _confirmWithdrawal() async {
    final enteredNickname = _nicknameController.text.trim();

    if (enteredNickname.isEmpty) {
      showCustomSnackbar(context, '닉네임을 입력해주세요.');
      return;
    }

    if (enteredNickname != _currentUserNickname) {
      showCustomSnackbar(context, '닉네임이 일치하지 않습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.deleteAccount();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showCustomSnackbar(context, '계정 탈퇴 중 오류가 발생했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '계정 탈퇴 확인',
            style: TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 0,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC5524C),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const Text(
                  //   '정말 탈퇴하시겠습니까?',
                  //   style: TextStyle(
                  //     color: Color(0xFF2D2D2D),
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // const Text(
                  //   '탈퇴를 진행하시려면 현재 사용중인 닉네임을 입력해주세요.\n탈퇴 시 모든 데이터는 영구적으로 삭제되며 복구할 수 없습니다.',
                  //   style: TextStyle(
                  //     color: Color(0xFF818181),
                  //     fontSize: 15,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  //const SizedBox(height: 32),
                  const Text(
                    '현재 닉네임을 입력해주세요',
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      //hintText: '현재 닉네임을 입력해주세요',
                      filled: true,
                      fillColor: Color(0xFFF0F0F0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide:
                            BorderSide(color: Color(0xFFF0F0F0), width: 2),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmWithdrawal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5524C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        '계정 탈퇴하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0xFF818181),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }
}
