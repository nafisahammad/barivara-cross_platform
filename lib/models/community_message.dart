import 'firestore_utils.dart';

class CommunityMessage {
  final String id;
  final String buildingId;
  final String userId;
  final String userName;
  final String flatNumber;
  final String content;
  final String? mediaData;
  final DateTime? createdAt;

  const CommunityMessage({
    required this.id,
    required this.buildingId,
    required this.userId,
    required this.userName,
    required this.flatNumber,
    required this.content,
    this.mediaData,
    this.createdAt,
  });

  factory CommunityMessage.fromMap(String id, Map<String, dynamic> data) {
    return CommunityMessage(
      id: id,
      buildingId: (data['buildingId'] ?? '') as String,
      userId: (data['userId'] ?? '') as String,
      userName: (data['userName'] ?? '') as String,
      flatNumber: (data['flatNumber'] ?? '') as String,
      content: (data['content'] ?? '') as String,
      mediaData: data['mediaData'] as String?,
      createdAt: parseDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buildingId': buildingId,
      'userId': userId,
      'userName': userName,
      'flatNumber': flatNumber,
      'content': content,
      'mediaData': mediaData,
      'createdAt': toTimestamp(createdAt),
    };
  }
}
