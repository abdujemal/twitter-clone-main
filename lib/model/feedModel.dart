// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter_twitter_clone/model/user.dart';

class FeedModel {
  String? key;
  String? parentkey;
  String? childRetwetkey;
  String? description;
  String? userId;
  int? likeCount;
  List<String>? likeList;
  int? commentCount;
  int? retweetCount;
  String createdAt;
  String? imagePath;
  List<String>? tags;
  List<String>? replyTweetKeyList;
  UserModel? user;
  FeedModel({
     this.key,
    this.description,
     this.userId,
     this.likeCount,
    this.commentCount,
    this.retweetCount,
    required this.createdAt,
     this.imagePath,
     this.likeList,
    required this.tags,
    this.user,
     this.replyTweetKeyList,
     this.parentkey,
     this.childRetwetkey,
  });
  toJson() {
    return {
      "userId": userId,
      "description": description,
      "likeCount": likeCount,
      "commentCount": commentCount ?? 0,
      "retweetCount": retweetCount ?? 0,
      "createdAt": createdAt,
      "imagePath": imagePath,
      "likeList": likeList,
      "tags": tags,
      "replyTweetKeyList": replyTweetKeyList,
      "user": user == null ? null : user!.toJson(),
      "parentkey": parentkey,
      "childRetwetkey": childRetwetkey
    };
  }

  // FeedModel.fromJson(Map<dynamic, dynamic> map) {
  //   key = map['key'];
  //   description = map['description'];
  //   userId = map['userId'];
  //   //  name = map['name'];
  //   //  profilePic = map['profilePic'];
  //   likeCount = map['likeCount'];
  //   commentCount = map['commentCount'];
  //   retweetCount = map["retweetCount"] ?? 0;
  //   imagePath = map['imagePath'];
  //   createdAt = map['createdAt'];
  //   imagePath = map['imagePath'];
  //   //  username = map['username'];
  //   user = UserModel.fromJson(map['user']);
  //   parentkey = map['parentkey'];
  //   childRetwetkey = map['childRetwetkey'];
  //   if (map['tags'] != null) {
  //     tags = [];
  //     map['tags'].forEach((value) {
  //       tags!.add(value);
  //     });
  //   }
  //   if (map["likeList"] != null) {
  //     likeList = [];
  //     final list = map['likeList'];
  //     if (list is List) {
  //       map['likeList'].forEach((value) {
  //         likeList.add(value);
  //       });
  //       likeCount = likeList.length;
  //     }
  //   } else {
  //     likeList = [];
  //     likeCount = 0;
  //   }
  //   if (map['replyTweetKeyList'] != null &&
  //       map['replyTweetKeyList'].length > 0) {
  //     map['replyTweetKeyList'].forEach((value) {
  //       replyTweetKeyList = [];
  //       map['replyTweetKeyList'].forEach((value) {
  //         replyTweetKeyList.add(value);
  //       });
  //     });
  //     commentCount = replyTweetKeyList.length;
  //   } else {
  //     replyTweetKeyList = [];
  //     commentCount = 0;
  //   }
  // }

  factory FeedModel.fromMap(Map<String, dynamic> map) {
    return FeedModel(
      key: map['key'] as String,
      parentkey: map['parentkey'] as String,
      childRetwetkey: map['childRetwetkey'] as String,
      description: map['description'] as String,
      userId: map['userId'] as String,
      likeCount: map["likeList"] != null
          ? List<String>.from((map['likeList'] as List<String>)).length
          : 0,
      likeList: map["likeList"] != null
          ? List<String>.from((map['likeList'] as List<String>))
          : null,
      commentCount: map['replyTweetKeyList'] != null
          ? List<String>.from((map['replyTweetKeyList'] as List<String>)).length
          : 0,
      retweetCount: map["retweetCount"] ?? 0,
      createdAt: map['createdAt'] as String,
      imagePath: map['imagePath'] as String,
      tags: map['tags'] != null
          ? List<String>.from((map['tags'] as List<String>))
          : null,
      replyTweetKeyList: map['replyTweetKeyList'] != null
          ? List<String>.from((map['replyTweetKeyList'] as List<String>))
          : [],
      user: UserModel.fromMap(map['user']),
    );
  }

  bool get isValidTweet {
    bool isValid = false;
    if (description != null &&
        description!.isNotEmpty &&
        this.user != null &&
        this.user!.userName != null &&
        this.user!.userName!.isNotEmpty) {
      isValid = true;
    } else {
      print("Invalid Tweet found. Id:- $key");
    }
    return isValid;
  }
}
