import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_moment/presentation/pages/home/home.dart';

class CreateAlbumPage extends StatefulWidget {
  final bool isEditMode;
  const CreateAlbumPage({super.key, this.isEditMode = false});

  @override
  State<CreateAlbumPage> createState() => _CreateAlbumPageState();
}

class _CreateAlbumPageState extends State<CreateAlbumPage> {
  final TextEditingController _animalNameController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _animalBirthController = TextEditingController();

  // 날짜 관련 변수들
  final int _startYear = 2001;
  // 현재 날짜를 최대값으로 사용
  final DateTime _today = DateTime.now();
  // 선택된 날짜 (null로 시작해서 사용자가 날짜를 선택하도록 함)
  DateTime? _selectedDate;

  bool _buttonActive = false;
  File? _coverImageFile;
  String? _coverImageUrl;
  String? _albumId;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animalNameController.addListener(_checkFormCompletion);
    _albumNameController.addListener(_checkFormCompletion);
    _animalBirthController.addListener(_checkFormCompletion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized && widget.isEditMode) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _animalNameController.text = args['animalName'] ?? '';
        _albumNameController.text = args['albumName'] ?? '';
        _animalBirthController.text = args['birthDate'] ?? '';
        _coverImageUrl = args['coverImageUrl'];
        _albumId = args['albumId'];
      }
      _initialized = true;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showIOSDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        // 현재 선택된 날짜가 있으면 사용, 없으면 오늘 날짜 사용
        DateTime tempPickedDate = _selectedDate ?? _today;
        return Container(
          height: MediaQuery.of(context).size.height * 0.3,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 40,
                color: const Color(0xFFF8F8F8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('취소'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    CupertinoButton(
                      child: const Text('완료'),
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempPickedDate;
                          _animalBirthController.text =
                              _formatDate(tempPickedDate);
                        });
                        Navigator.pop(context);
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempPickedDate,
                  minimumDate: DateTime(_startYear),
                  maximumDate: _today,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedDate = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteAlbum() async {
    if (!widget.isEditMode || _albumId == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('albums')
          .doc(_albumId)
          .delete();

      if (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(_coverImageUrl!).delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      debugPrint('Error deleting album: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('앨범 삭제에 실패했습니다.')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditMode) {
        await _updateAlbum();
      } else {
        await _saveAlbum();
      }
    } catch (e) {
      debugPrint('Error handling save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateAlbum() async {
    if (!_buttonActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 인증이 필요합니다.')),
      );
      return;
    }

    try {
      String? imageUrl = _coverImageUrl;
      if (_coverImageFile != null) {
        imageUrl = await _uploadCoverImage();
      }

      final albumData = {
        'animalName': _animalNameController.text.trim(),
        'albumName': _albumNameController.text.trim(),
        'birthDate': _animalBirthController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        albumData['coverImageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('albums')
          .doc(_albumId)
          .update(albumData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              newAlbumData: {
                'albumName': _albumNameController.text,
                'updatedAt': DateTime.now(),
                'albumId': _albumId,
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating album: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('앨범 수정에 실패했습니다: $e')),
      );
    }
  }

  Future<void> _saveAlbum() async {
    if (!_buttonActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 인증이 필요합니다.')),
      );
      return;
    }

    try {
      final uploadedImageUrl = await _uploadCoverImage();

      final albumData = {
        'animalName': _animalNameController.text.trim(),
        'albumName': _albumNameController.text.trim(),
        'birthDate': _animalBirthController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'coverImageUrl': uploadedImageUrl ?? '',
      };

      final albumRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('albums')
          .add(albumData);

      await albumRef.update({'id': albumRef.id});

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              newAlbumData: {
                'albumName': _albumNameController.text,
                'createdAt': DateTime.now(),
                'albumId': albumRef.id,
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving album: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('앨범 저장에 실패했습니다: $e')),
        );
      }
      rethrow;
    }
  }

  Future<String?> _uploadCoverImage() async {
    if (_coverImageFile == null) return null;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final email = user.email ?? user.uid;
      final albumName = _albumNameController.text.trim();

      final storageRef =
          FirebaseStorage.instance.ref('Album/$email/$albumName/$fileName');
      final uploadTask = await storageRef.putFile(_coverImageFile!);

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  void _checkFormCompletion() {
    setState(() {
      _buttonActive = _animalNameController.text.isNotEmpty &&
          _albumNameController.text.isNotEmpty &&
          _animalBirthController.text.isNotEmpty;
    });
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _coverImageFile = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _animalNameController.dispose();
    _albumNameController.dispose();
    _animalBirthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        actions: widget.isEditMode
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: GestureDetector(
                    onTap: deleteDialog,
                    child: const Text('삭제하기',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                  ),
                )
              ]
            : null,
        centerTitle: false,
        title: const Text(
          '앨범 설정',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickCoverImage,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: _coverImageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.asset(
                                      'assets/albumshadow.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                          topRight: Radius.circular(34),
                                          bottomRight: Radius.circular(38),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                            offset: const Offset(-3, 3),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 0, 8, 6),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(6),
                                            bottomLeft: Radius.circular(8),
                                            topRight: Radius.circular(26),
                                            bottomRight: Radius.circular(26),
                                          ),
                                          child: Image.file(
                                            _coverImageFile!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            : (_coverImageUrl != null &&
                                    _coverImageUrl!.isNotEmpty)
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(30),
                                        child: Image.asset(
                                          'assets/albumshadow.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(20),
                                              bottomLeft: Radius.circular(20),
                                              topRight: Radius.circular(34),
                                              bottomRight: Radius.circular(38),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                                offset: const Offset(-3, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 0, 8, 6),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(6),
                                                bottomLeft: Radius.circular(8),
                                                topRight: Radius.circular(26),
                                                bottomRight:
                                                    Radius.circular(26),
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: _coverImageUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Icon(Icons.error),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : Image.asset(
                                    'assets/defaultcoverplus.png',
                                    fit: BoxFit.cover,
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '반려동물의 이름을 설정해 주세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _animalNameController,
                    decoration: InputDecoration(
                      hintText: 'ex) 보리',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFFE94A39), width: 1),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFFE94A39), width: 1),
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '앨범 제목을 설정해 주세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _albumNameController,
                    decoration: InputDecoration(
                      hintText: 'ex) 보리와 첫번째 이야기',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFFE94A39), width: 1),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFFE94A39), width: 1),
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '반려동물의 생일을 알려주세요',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showIOSDatePicker,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _animalBirthController,
                        decoration: InputDecoration(
                          hintText: '2000/00/00',
                          suffixIcon: const Icon(Icons.calendar_today),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE94A39), width: 1.5),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFFE94A39), width: 1.5),
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 45),
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_buttonActive && !_isSaving)
                                ? const Color(0XFFE94A39)
                                : const Color(0XFFEC766A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          onPressed: _buttonActive
                              ? (_isSaving ? null : _handleSave)
                              : null,
                          child: const Text(
                            '완료',
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
      ),
    );
  }

  void deleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/deleteAlbum.png'),
              Positioned(
                bottom: -4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Color(0XFFE94A39),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 100),
                      TextButton(
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            color: Color(0XFFE94A39),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteAlbum();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
