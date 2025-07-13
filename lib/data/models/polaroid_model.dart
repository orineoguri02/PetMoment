import 'package:cloud_firestore/cloud_firestore.dart';

class PolaroidModel {
  final String polaroidId;
  final String imageUrl;
  final String? title;
  final String? description;
  final DateTime? createdAt;
  final double? rotation;
  final int? page;

  PolaroidModel({
    required this.polaroidId,
    required this.imageUrl,
    this.title,
    this.description,
    this.createdAt,
    this.rotation,
    this.page,
  });

  factory PolaroidModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PolaroidModel(
      polaroidId: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      rotation: data['rotation']?.toDouble(),
      page: data['page'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'rotation': rotation,
      'page': page,
    };
  }
} 