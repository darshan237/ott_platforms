import 'package:equatable/equatable.dart';

class VideoModel extends Equatable {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String userId;
  final String userName;
  final int likes;
  final bool isLiked;
  final Duration duration;

  const VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.userId,
    required this.userName,
    required this.likes,
    required this.isLiked,
    required this.duration,
  });

  VideoModel copyWith({
    int? likes,
    bool? isLiked,
  }) {
    return VideoModel(
      id: id,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      userId: userId,
      userName: userName,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      duration: duration,
    );
  }

  @override
  List<Object?> get props => [id, videoUrl, likes, isLiked];
}
