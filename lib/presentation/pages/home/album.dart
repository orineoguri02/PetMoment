import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_moment/presentation/pages/home/pdf_dialog.dart';
import 'package:pet_moment/presentation/pages/home/calendar.dart';
import 'package:pet_moment/presentation/pages/home/polaroid_add_screen.dart';
import 'package:pet_moment/presentation/pages/home/polaroid_grid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pet_moment/index.dart';

class AlbumScreen extends StatefulWidget {
  final String userId;
  final String albumId;

  const AlbumScreen({
    Key? key,
    required this.userId,
    required this.albumId,
  }) : super(key: key);

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCalendarView = false;
  Map<DateTime, List<Map<String, dynamic>>> _polaroidEntries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolaroidData();
  }

  Future<void> _loadPolaroidData() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return setState(() => _isLoading = false);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('albums')
        .doc(widget.albumId)
        .collection('polaroid')
        .orderBy('timestamp', descending: false)
        .get();

    final Map<DateTime, List<Map<String, dynamic>>> entries = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = (data['timestamp'] as Timestamp).toDate();
      final day = DateTime(ts.year, ts.month, ts.day);
      entries[day] = (entries[day] ?? [])
        ..add({
          'id': doc.id,
          'imageUrl': data['imageUrl'] ?? '',
          'text': (data['text'] ?? '').replaceAll(r'\n', '\n'),
          'timestamp': ts,
        });
    }

    setState(() {
      _polaroidEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _addPolaroid() async {
    final images = await _picker.pickMultiImage();
    if (images == null || images.isEmpty) return;

    final albumDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('albums')
        .doc(widget.albumId)
        .get();
    final albumName = albumDoc.data()?['albumName'] ?? '';

    for (final image in images) {
      final result = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => PolaroidAddScreen(
          userId: widget.userId,
          albumId: widget.albumId,
          imagePath: image.path,
          albumName: albumName,
        ),
        transitionBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );
      if (result == true && mounted) {
        await _loadPolaroidData();
      }
    }
  }

  Future<String> generateAndUploadAlbumPdf() async {
    final fontData = await rootBundle.load('assets/fonts/HS유지체.ttf');
    final hsFont = pw.Font.ttf(fontData);

    final uid = widget.userId;
    final albumId = widget.albumId;
    final albumDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('albums')
        .doc(albumId)
        .get();
    final albumName = albumDoc.data()?['albumName'] as String? ?? 'album';

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('albums')
        .doc(albumId)
        .collection('polaroid')
        .orderBy('timestamp', descending: true)
        .get();

    final pdf = pw.Document();
    final tmpDir = await getTemporaryDirectory();

    for (final doc in snap.docs) {
      final data = doc.data();
      final rawText = (data['text'] as String).replaceAll(r'\n', '\n');
      final ts = (data['timestamp'] as Timestamp).toDate();
      final imgPath = data['imageStoragePath'] as String;

      try {
        final ref = FirebaseStorage.instance.ref(imgPath);
        final tmpFile = File(p.join(tmpDir.path, p.basename(imgPath)));
        await ref.writeToFile(tmpFile);
        final originalBytes = await tmpFile.readAsBytes();

        final compressedBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: 800,
          minHeight: 1000,
          quality: 80,
        );

        final image = pw.MemoryImage(compressedBytes);

        // 최종 이미지와 정확히 일치하는 폴라로이드 스타일 구현
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat(
            8.8 * PdfPageFormat.cm,
            10.8 * PdfPageFormat.cm,
            marginAll: 0,
          ),
          build: (_) => pw.Container(
            width: 8.8 * PdfPageFormat.cm,
            height: 10.8 * PdfPageFormat.cm,
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                pw.Container(
                  margin: const pw.EdgeInsets.only(
                    left: 0.5 * PdfPageFormat.cm,
                    right: 0.5 * PdfPageFormat.cm,
                    top: 0.5 * PdfPageFormat.cm,
                  ),
                  height: 7.8 * PdfPageFormat.cm,
                  width: 7.8 * PdfPageFormat.cm,
                  child: pw.Image(image, fit: pw.BoxFit.cover),
                ),

                // 텍스트 영역
                pw.Container(
                  margin: const pw.EdgeInsets.only(
                    left: 0.5 * PdfPageFormat.cm,
                    right: 0.5 * PdfPageFormat.cm,
                    top: 0.25 * PdfPageFormat.cm,
                  ),
                  child: pw.Text(
                    rawText,
                    style: pw.TextStyle(
                      font: hsFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                // 날짜 영역 (우측 하단에 강제 배치)
                pw.Expanded(
                  child: pw.Align(
                    alignment: pw.Alignment.bottomRight,
                    child: pw.Container(
                      margin: const pw.EdgeInsets.only(
                        right: 0.5 * PdfPageFormat.cm,
                        bottom: 0.5 * PdfPageFormat.cm,
                      ),
                      child: pw.Text(
                        "${ts.year}.${ts.month.toString().padLeft(2, '0')}.${ts.day.toString().padLeft(2, '0')}",
                        style: pw.TextStyle(
                          font: hsFont,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
      } catch (e) {
        print('이미지 처리 중 오류 발생: $e');
      }
    }

    // 임시 파일 정리
    Future.delayed(const Duration(minutes: 1), () {
      try {
        tmpDir.list().forEach((entity) {
          if (entity is File) {
            entity.deleteSync();
          }
        });
      } catch (e) {
        print('임시 파일 삭제 실패: $e');
      }
    });

    final pdfBytes = await pdf.save();
    final email = FirebaseAuth.instance.currentUser?.email ?? uid;
    final path = 'Album/$email/$albumName/album_$albumId.pdf';
    final outRef = FirebaseStorage.instance.ref(path);
    await outRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    return outRef.getDownloadURL();
  }

  void pdfDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PdfDialog(generatePdf: generateAndUploadAlbumPdf),
    );
  }

  void _toggleView() => setState(() => _isCalendarView = !_isCalendarView);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = (size.width * 0.9).clamp(300.0, 390.0);
    final h = (size.height * 0.6).clamp(400.0, 520.0);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/gradient.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                onPressed: pdfDialog,
                icon: const Icon(
                  Icons.unarchive_outlined,
                  size: 30,
                  color: Color(0XFFE94A39),
                ),
              ),
              IconButton(
                onPressed: _addPolaroid,
                icon: const Icon(
                  Icons.add,
                  size: 30,
                  color: Color(0XFFE94A39),
                ),
              ),
              IconButton(
                onPressed: _toggleView,
                icon: Icon(
                  _isCalendarView
                      ? Icons.book_outlined
                      : Icons.calendar_today_outlined,
                  size: _isCalendarView ? 26 : 24,
                  color: const Color(0XFFE94A39),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.02),
                Expanded(
                  child: _isCalendarView
                      ? AlbumCalendarView(
                          containerWidth: w,
                          containerHeight: h,
                          polaroidEntries: _polaroidEntries,
                          isLoading: _isLoading,
                          userId: widget.userId,
                          albumId: widget.albumId,
                          onDataChanged: _loadPolaroidData,
                        )
                      : PolaroidGrid(
                          userId: widget.userId,
                          albumId: widget.albumId,
                          onDelete: () async {
                            await _loadPolaroidData();
                            final url = await generateAndUploadAlbumPdf();
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('albums')
                                .doc(widget.albumId)
                                .update({'albumPdfUrl': url});
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
