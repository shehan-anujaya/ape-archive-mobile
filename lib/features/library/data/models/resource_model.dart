import 'package:json_annotation/json_annotation.dart';
import '../../../auth/data/models/user_model.dart';
import 'tag_model.dart';

part 'resource_model.g.dart';

enum ResourceStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@JsonSerializable()
class ResourceModel {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'driveFileId')
  final String? driveFileId;
  @JsonKey(name: 'mimeType')
  final String? mimeType;
  @JsonKey(name: 'fileSize')
  final int? fileSize;
  final String? thumbnail;
  @JsonKey(defaultValue: ResourceStatus.pending)
  final ResourceStatus? status;
  @JsonKey(name: 'uploaderId')
  final String? uploaderId;
  final UserModel? uploader;
  @JsonKey(defaultValue: [])
  final List<TagModel> tags;
  @JsonKey(name: 'viewCount', defaultValue: 0)
  final int viewCount;
  @JsonKey(name: 'downloadCount', defaultValue: 0)
  final int downloadCount;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  ResourceModel({
    required this.id,
    required this.title,
    this.description,
    this.driveFileId,
    this.mimeType,
    this.fileSize,
    this.thumbnail,
    this.status,
    this.uploaderId,
    this.uploader,
    this.tags = const [],
    this.viewCount = 0,
    this.downloadCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) =>
      _$ResourceModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceModelToJson(this);

  String get formattedSize {
    if (fileSize == null || fileSize == 0) return 'Unknown size';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

@JsonSerializable()
class PaginatedResourceResponse {
  final List<ResourceModel> data;
  final int total;
  final int page;
  final int limit;

  PaginatedResourceResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedResourceResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginatedResourceResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedResourceResponseToJson(this);

  bool get hasMore => (page * limit) < total;
}
