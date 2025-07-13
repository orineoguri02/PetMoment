import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pet_moment/core/utils/snackbar_utils.dart';
import 'package:pet_moment/presentation/pages/home/home.dart';
import 'package:pet_moment/presentation/pages/login/SNSLogin/login.dart';

class CreateProfileScreen extends StatefulWidget {
  final String email;
  final String? docId;
  const CreateProfileScreen({Key? key, required this.email, this.docId})
      : super(key: key);

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Uint8List? _imageBytes;
  bool _buttonActive = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nicknameController.addListener(_checkFormCompletion);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final docRef =
        _firestore.collection('users').doc(widget.docId ?? currentUser.uid);
    try {
      final userDoc = await docRef.get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _nicknameController.text = data['nickname'] ?? '';
        _profileImageUrl = data['profileImageUrl'] ?? '';
        setState(() {});
        _checkFormCompletion();
      }
    } catch (e) {
      debugPrint("프로필 불러오기 오류: $e");
    }
  }

  void _checkFormCompletion() {
    if (!mounted) return;
    setState(() {
      _buttonActive = _nicknameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        _imageBytes = await pickedFile.readAsBytes();
        _checkFormCompletion();
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, '이미지 선택 중 오류가 발생했습니다.');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_buttonActive || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('사용자 인증 정보가 없습니다.');

      String? downloadUrl = _profileImageUrl;
      if (_imageBytes != null) {
        final user = currentUser;
        final emailFolder = user.email!;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('Album')
            .child(emailFolder)
            .child('profile')
            .child('$emailFolder.png');

        await storageRef.putData(_imageBytes!);
        downloadUrl = await storageRef.getDownloadURL();
      }

      final docRef =
          _firestore.collection('users').doc(widget.docId ?? currentUser.uid);
      await docRef.set({
        'userId': widget.docId ?? currentUser.uid,
        'email': widget.email,
        'nickname': _nicknameController.text.trim(),
        'profileImageUrl': downloadUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        showCustomSnackbar(context, '프로필 저장 중 오류가 발생했습니다.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUserAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.delete();
      } catch (_) {
        await _auth.signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _deleteUserAccount();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            '계정 만들기',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            onPressed: () async {
              await _deleteUserAccount();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '프로필을 \n입력해 주세요',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFFE94A39),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 223,
                        width: 223,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0XFFD9D9D9),
                        ),
                        child: _imageBytes != null
                            ? ClipOval(
                                child: Image.memory(_imageBytes!,
                                    fit: BoxFit.cover),
                              )
                            : (_profileImageUrl != null &&
                                    _profileImageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                    Icons.edit_outlined,
                                    size: 55,
                                    color: Colors.white,
                                  ))),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    hintText: '닉네임',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB1B1B1),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFFE4E4E4), width: 2),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          const BorderSide(color: Color(0xFFE94A39), width: 2),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 355,
                    height: 50,
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
                          ? () async {
                              await _saveProfile();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HomePage(isFromProfileCreation: true),
                                ),
                              );
                            }
                          : null,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '시작하기',
                              style: TextStyle(
                                fontSize: 22,
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
        ),
      ),
    );
  }
}
