
class UserModel {
  String? key;
  String? email;
  String? userId;
  String? displayName;
  String? userName;
  String? webSite;
  String? profilePic;
  String? contact;
  String? bio;
  String? location;
  String? dob;
  String? createdAt;
  bool? isVerified;
  int? followers;
  int? following;
  String? fcmToken;
  List<String>? followersList;
  List<String>? followingList;

  UserModel({
     this.email,
     this.userId,
     this.displayName,
     this.profilePic,
     this.key,
     this.contact,
     this.bio,
     this.dob,
     this.location,
     this.createdAt,
     this.userName,
    this.followers,
    this.following,
     this.webSite,
    this.isVerified,
     this.fcmToken,
    this.followersList,
    this.followingList,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      key: map['key'] as String,
      email: map['email'] as String,
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      userName: map['userName'] as String,
      webSite: map['webSite'] as String,
      profilePic: map['profilePic'] as String,
      contact: map['contact'] as String,
      bio: map['bio'] as String,
      location: map['location'] as String,
      dob: map['dob'] as String,
      createdAt: map['createdAt'] as String,
      isVerified: map['isVerified'] ?? false,
      followers: map['followerList'] != null
          ? List<String>.from((map['followerList'] as List<String>)).length
          : null,
      // following: map['following'] as int,
      fcmToken: map['fcmToken'] as String,
      following: map['followingList'] != null
          ? List<String>.from((map['followingList'] as List<String>)).length
          : null,

      followersList: map['followerList'] != null
          ? List<String>.from((map['followerList'] as List<String>))
          : [],
      followingList: map['followingList'] != null
          ? List<String>.from((map['followingList'] as List<String>))
          : null,
    );
  }
  toJson() {
    return {
      'key': key,
      "userId": userId,
      "email": email,
      'displayName': displayName,
      'profilePic': profilePic,
      'contact': contact,
      'dob': dob,
      'bio': bio,
      'location': location,
      'createdAt': createdAt,
      'followers': followersList != null ? followersList!.length : null,
      'following': followingList != null ? followingList!.length : null,
      'userName': userName,
      'webSite': webSite,
      'isVerified': isVerified ?? false,
      'fcmToken': fcmToken,
      'followerList': followersList,
      'followingList': followingList
    };
  }

  String getFollower() {
    return '${this.followers ?? 0}';
  }

  String getFollowing() {
    return '${this.following ?? 0}';
  }

  UserModel copyWith({
    String? key,
    String? email,
    String? userId,
    String? displayName,
    String? userName,
    String? webSite,
    String? profilePic,
    String? contact,
    String? bio,
    String? location,
    String? dob,
    String? createdAt,
    bool? isVerified,
    int? followers,
    int? following,
    String? fcmToken,
    List<String>? followersList,
    List<String>? followingList,
  }) {
    return UserModel(
      key: key ?? this.key,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      userName: userName ?? this.userName,
      webSite: webSite ?? this.webSite,
      profilePic: profilePic ?? this.profilePic,
      contact: contact ?? this.contact,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      dob: dob ?? this.dob,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      fcmToken: fcmToken ?? this.fcmToken,
      followersList: followersList ?? this.followersList,
      followingList: followingList ?? this.followingList,
    );
  }
}
