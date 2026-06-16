class ItemModel {
  final String? id;
  final String reporterId;
  final String type; // 'lost' | 'found'
  final String name;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final String?
  distinctiveFeatures; // Kolom sensitif — hanya ada saat user lihat miliknya
  final List<String> photoUrls;
  final String
  status; // 'pending' | 'published' | 'claimed' | 'completed' | 'rejected'
  final String? rejectionReason;
  final DateTime itemDate;
  final String? dropPoint;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemModel({
    this.id,
    required this.reporterId,
    required this.type,
    required this.name,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.distinctiveFeatures,
    this.photoUrls = const [],
    this.status = 'pending',
    this.rejectionReason,
    required this.itemDate,
    this.dropPoint,
    this.createdAt,
    this.updatedAt,
  });

  //───── Parse dari response Supabase ─────
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String?,
      reporterId: json['reporter_id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      description: json['description'] as String?,
      distinctiveFeatures: json['distinctive_features'] as String?,
      photoUrls:
          (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      itemDate: DateTime.parse(json['item_date'] as String),
      dropPoint: json['drop_point'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  //───── Serialisasi untuk INSERT ke Supabase ─────
  // Tidak menyertakan id, createdAt, updatedAt — di-generate oleh DB.
  Map<String, dynamic> toJson() {
    return {
      'reporter_id': reporterId,
      'type': type,
      'name': name,
      'category': category,
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (description != null) 'description': description,
      if (distinctiveFeatures != null)
        'distinctive_features': distinctiveFeatures,
      'photo_urls': photoUrls,
      'status': status,
      'item_date': itemDate
          .toIso8601String()
          .split('T')
          .first, // format: YYYY-MM-DD
    };
  }

  //───── CopyWith untuk update partial ─────
  ItemModel copyWith({
    String? id,
    String? reporterId,
    String? type,
    String? name,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    String? distinctiveFeatures,
    List<String>? photoUrls,
    String? status,
    String? rejectionReason,
    DateTime? itemDate,
  }) {
    return ItemModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      type: type ?? this.type,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      distinctiveFeatures: distinctiveFeatures ?? this.distinctiveFeatures,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      itemDate: itemDate ?? this.itemDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
