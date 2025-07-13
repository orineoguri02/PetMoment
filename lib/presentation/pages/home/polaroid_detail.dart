import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PolaroidDetail extends StatefulWidget {
  final String userId;
  final String albumId;
  final String polaroidId;
  final bool isCalendarView;

  const PolaroidDetail({
    super.key,
    required this.userId,
    required this.albumId,
    required this.polaroidId,
    this.isCalendarView = false,
  });

  @override
  State<PolaroidDetail> createState() => _PolaroidDetailState();
}

class _PolaroidDetailState extends State<PolaroidDetail>
    with AutomaticKeepAliveClientMixin {
  ImageProvider? _imageProvider;
  bool isEditing = false;
  final TextEditingController textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // 날짜 선택을 위한 변수
  DateTime _selectedDate = DateTime.now();
  final int _startYear = 2001;
  // 현재 날짜를 최대값으로 사용
  final DateTime _today = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged(String text) {
    List<String> lines = text.split('\n');
    if (lines.length > 2) {
      String limitedText = lines.sublist(0, 2).join('\n');
      textController.value = TextEditingValue(
        text: limitedText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: limitedText.length),
        ),
      );
      _textFocusNode.unfocus();
    }
  }

  void _toggleEdit(String currentText, DateTime currentDate) {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        textController.text = currentText.replaceAll("\\n", "\n");
        _selectedDate = currentDate;
      }
    });
  }

  void _showIOSDatePicker() {
    // iOS 스타일 데이트피커 표시
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: MediaQuery.of(context).copyWith().size.height * 0.25,
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
                        setState(() {});
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
                  initialDateTime: _selectedDate,
                  minimumDate: DateTime(_startYear),
                  // 오늘 날짜까지만 선택 가능하도록 설정
                  maximumDate: _today,
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      _selectedDate = newDateTime;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePolaroid(String imageUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('albums')
          .doc(widget.albumId)
          .collection('polaroid')
          .doc(widget.polaroidId)
          .update({
        'text': textController.text,
        'timestamp': Timestamp.fromDate(_selectedDate),
      });

      setState(() => isEditing = false);
      // 항상 true를 반환하여 변경 가능성을 나타냄
      // 텍스트만 변경되더라도 캘린더를 새로고침하도록 함
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 중 오류가 발생했습니다')),
      );
      Navigator.pop(context, false);
    }
  }

  Future<void> _deletePolaroid() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('albums')
          .doc(widget.albumId)
          .collection('polaroid')
          .doc(widget.polaroidId);
      final docSnapshot = await docRef.get();
      final data = docSnapshot.data();
      if (data != null && data.containsKey('imageStoragePath')) {
        await FirebaseStorage.instance
            .ref()
            .child(data['imageStoragePath'] as String)
            .delete();
      }
      await docRef.delete();

      // 항상 변경 사항 표시
      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context, true); // 오류가 있어도 변경 사항 표시
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // mixin 사용 시 필수 호출
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('albums')
            .doc(widget.albumId)
            .collection('polaroid')
            .doc(widget.polaroidId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final imageUrl = data['imageUrl'] as String? ?? '';
          final text = data['text'] as String? ?? '';
          final timestamp = (data['timestamp'] as Timestamp).toDate();

          // 편집 모드가 아닐 때 선택된 날짜 업데이트
          if (!isEditing) {
            _selectedDate = timestamp;
          }

          if (_imageProvider == null && imageUrl.isNotEmpty) {
            _imageProvider = CachedNetworkImageProvider(imageUrl);
          }

          return Center(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!widget.isCalendarView)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 30),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        AspectRatio(
                          aspectRatio: 0.76,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: AspectRatio(
                                          aspectRatio: 0.8,
                                          child: ClipRRect(
                                            child: imageUrl.isNotEmpty
                                                ? Image(
                                                    image: _imageProvider!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.image,
                                                      size: 100,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            if (isEditing)
                                              Positioned.fill(
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            textController,
                                                        focusNode:
                                                            _textFocusNode,
                                                        onChanged:
                                                            _handleTextChanged,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily: 'HS유지체',
                                                          color: Colors.black,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          20),
                                                        ),
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.bottomRight,
                                                      child: GestureDetector(
                                                        onTap:
                                                            _showIOSDatePicker,
                                                        child: Container(
                                                          width: 100,
                                                          height: 42,
                                                          alignment:
                                                              Alignment.center,
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  right: 20,
                                                                  bottom: 10),
                                                          child: Text(
                                                            DateFormat(
                                                                    'yyyy.MM.dd')
                                                                .format(
                                                                    _selectedDate),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.black,
                                                              fontFamily:
                                                                  'HS유지체',
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Positioned.fill(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 20),
                                                        child: Text(
                                                          text.replaceAll(
                                                              "\\n", "\n"),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily: 'HS유지체',
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 20,
                                                              bottom: 10),
                                                      child: Align(
                                                        alignment: Alignment
                                                            .bottomRight,
                                                        child: Text(
                                                          DateFormat(
                                                                  'yyyy.MM.dd')
                                                              .format(
                                                                  timestamp),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.black,
                                                            fontFamily: 'HS유지체',
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
                                    ],
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: isEditing
                                        ? IconButton(
                                            icon: Container(
                                              width: 35,
                                              height: 35,
                                              decoration: const BoxDecoration(
                                                color: Color(0XFFE94A39),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 26,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _savePolaroid(imageUrl),
                                          )
                                        : PopupMenuButton<String>(
                                            color: Colors.white,
                                            icon: Container(
                                              width: 35,
                                              height: 35,
                                              decoration: const BoxDecoration(
                                                color: Color(0XFFE94A39),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.more_horiz,
                                                size: 26,
                                                color: Colors.white,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            offset: const Offset(0, 10),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _toggleEdit(text, timestamp);
                                              } else if (value == 'delete') {
                                                deleteDialog();
                                              }
                                            },
                                            position: PopupMenuPosition.under,
                                            itemBuilder:
                                                (BuildContext context) => [
                                              const PopupMenuItem<String>(
                                                value: 'edit',
                                                height: 25,
                                                child: Center(
                                                  child: Text(
                                                    '수정하기',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                height: 25,
                                                child: Center(
                                                  child: Text(
                                                    '삭제하기',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              Image.asset('assets/deletePolaroid.png'),
              Positioned(
                bottom: -4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: Color(0XFFE94A39),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 100),
                    TextButton(
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          color: Color(0XFFE94A39),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        _deletePolaroid();
                        Navigator.pop(context, true);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
