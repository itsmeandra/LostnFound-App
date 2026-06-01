import 'package:flutter/material.dart';
import '../../report/data/item_model.dart';

enum ClaimStatus {
  pending,
  approved,
  rejected,
  completed;

  String get label => switch (this) {
    ClaimStatus.pending => 'Menunggu Verifikasi',
    ClaimStatus.approved => 'Disetujui',
    ClaimStatus.rejected => 'Ditolak',
    ClaimStatus.completed => 'Selesai',
  };

  Color get color => switch (this) {
    ClaimStatus.pending => const Color(0xFFF57C00),
    ClaimStatus.approved => const Color(0xFF388E3C),
    ClaimStatus.rejected => const Color(0xFFD32F2F),
    ClaimStatus.completed => const Color(0xFF1976D2),
  };

  static ClaimStatus fromString(String s) => switch (s) {
    'approved' => ClaimStatus.approved,
    'rejected' => ClaimStatus.rejected,
    'completed' => ClaimStatus.completed,
    _ => ClaimStatus.pending,
  };
}

class ClaimModel {
  final String id;
  final String itemId;
  final String claimantId;
  final List<String> proofPhotos;
  final String secretDescription;
  final ClaimStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ItemModel? item; // join dari items(*)

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.proofPhotos,
    required this.secretDescription,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.item,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    ItemModel? item;
    if (json['item'] != null) {
      item = ItemModel.fromJson(json['item'] as Map<String, dynamic>);
    }
    return ClaimModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      claimantId: json['claimant_id'] as String,
      proofPhotos:
          (json['proof_photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      secretDescription: json['secret_description'] as String? ?? '',
      status: ClaimStatus.fromString(json['status'] as String? ?? 'pending'),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      item: item,
    );
  }

  bool get isPending => status == ClaimStatus.pending;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;
  bool get isCompleted => status == ClaimStatus.completed;
}
