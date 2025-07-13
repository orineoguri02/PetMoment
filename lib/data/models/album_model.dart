import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumModel {
  final String albumId;
  final String albumName;
  final String animalName;
  final String? animalBirth;
  final String? coverImageUrl;
  final DateTime? createdAt;
  final int? pagesCount;

  AlbumModel({
    required this.albumId,
    required this.albumName,
    required this.animalName,
    this.animalBirth,
    this.coverImageUrl,
    this.createdAt,
    this.pagesCount,
  });

  factory AlbumModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AlbumModel(
      albumId: doc.id,
      albumName: data['albumName'] ?? '',
      animalName: data['animalName'] ?? '',
      animalBirth: data['animalBirth'],
      coverImageUrl: data['coverImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      pagesCount: data['pagesCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'albumName': albumName,
      'animalName': animalName,
      'animalBirth': animalBirth,
      'coverImageUrl': coverImageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'pagesCount': pagesCount,
    };
  }
} 