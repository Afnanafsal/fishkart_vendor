import 'package:fishkart_vendor/models/Model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review extends Model {
  static const String REVIEWER_UID_KEY = "reviewer_uid";
  static const String RATING_KEY = "rating";
  static const String FEEDBACK_KEY = "review";
  static const String CREATED_AT_KEY = "createdAt";
  static const String LIKES_KEY = "likes";
  static const String REPLY_COUNT_KEY = "replyCount";
  static const String USER_AVATAR_KEY = "userAvatar";
  static const String USER_NAME_KEY = "userName";

  String? reviewerUid;
  int rating;
  String? feedback;
  DateTime? createdAt;
  int likes;
  int replyCount;
  String? userAvatar;
  String? userName;

  Review(
    String? id, {
    this.reviewerUid,
    this.rating = 3,
    this.feedback,
    this.createdAt,
    this.likes = 0,
    this.replyCount = 0,
    this.userAvatar,
    this.userName,
  }) : super(id ?? '');

  factory Review.fromMap(Map<String, dynamic> map, {String? id}) {
    return Review(
      id,
      reviewerUid: map[REVIEWER_UID_KEY],
      rating: map[RATING_KEY] ?? 3,
      feedback: map[FEEDBACK_KEY],
      createdAt: map[CREATED_AT_KEY] != null
          ? (map[CREATED_AT_KEY] is Timestamp
                ? (map[CREATED_AT_KEY] as Timestamp).toDate()
                : DateTime.tryParse(map[CREATED_AT_KEY].toString()))
          : null,
      likes: map[LIKES_KEY] ?? 0,
      replyCount: map[REPLY_COUNT_KEY] ?? 0,
      userAvatar: map[USER_AVATAR_KEY],
      userName: map[USER_NAME_KEY],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      REVIEWER_UID_KEY: reviewerUid,
      RATING_KEY: rating,
      FEEDBACK_KEY: feedback,
      CREATED_AT_KEY:
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      LIKES_KEY: likes,
      REPLY_COUNT_KEY: replyCount,
      USER_AVATAR_KEY: userAvatar,
      USER_NAME_KEY: userName,
    };
  }

  @override
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (reviewerUid != null) map[REVIEWER_UID_KEY] = reviewerUid;
    map[RATING_KEY] = rating;
    if (feedback != null) map[FEEDBACK_KEY] = feedback;
    if (createdAt != null) map[CREATED_AT_KEY] = createdAt!.toIso8601String();
    map[LIKES_KEY] = likes;
    map[REPLY_COUNT_KEY] = replyCount;
    if (userAvatar != null) map[USER_AVATAR_KEY] = userAvatar;
    if (userName != null) map[USER_NAME_KEY] = userName;
    return map;
  }

  Review copyWith({
    String? id,
    String? reviewerUid,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    int? likes,
    int? replyCount,
    String? userAvatar,
    String? userName,
  }) {
    return Review(
      id ?? this.id,
      reviewerUid: reviewerUid ?? this.reviewerUid,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      replyCount: replyCount ?? this.replyCount,
      userAvatar: userAvatar ?? this.userAvatar,
      userName: userName ?? this.userName,
    );
  }
}
