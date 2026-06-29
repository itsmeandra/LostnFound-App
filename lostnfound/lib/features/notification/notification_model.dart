import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>?) ?? {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  // Route yang dituju saat notifikasi di-tap
  String? get targetRoute {
    final itemId = data['item_id'] as String?;
    return switch (type) {
      'item_published' => itemId != null ? '/item/$itemId' : null,
      'item_rejected' => '/my-reports',
      'item_returned' => '/my-reports',
      'claim_approved' => '/my-claims',
      'claim_rejected' => '/my-claims',
      'match_found' => itemId != null ? '/item/$itemId' : null,
      _ => null,
    };
  }

  // Ikon per tipe notifikasi
  IconData get icon => switch (type) {
    'item_published' => Icons.check_circle_outline,
    'item_rejected' => Icons.error_outline,
    'item_returned' => Icons.verified_outlined,
    'claim_approved' => Icons.handshake_outlined,
    'claim_rejected' => Icons.cancel_outlined,
    'match_found' => Icons.search_outlined,
    _ => Icons.notifications_outlined,
  };

  Color get iconColor => switch (type) {
    'item_published' => const Color(0xFF388E3C),
    'item_rejected' => const Color(0xFFD32F2F),
    'item_returned' => const Color(0xFF1976D2),
    'claim_approved' => const Color(0xFF388E3C),
    'claim_rejected' => const Color(0xFFD32F2F),
    'match_found' => const Color(0xFFF57C00),
    _ => Colors.grey,
  };
}
