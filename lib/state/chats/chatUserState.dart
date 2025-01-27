import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_twitter_clone/model/chatModel.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/appState.dart';

class ChatUserState extends AppState {
  bool? setIsChatScreenOpen;
  // final FirebaseDatabase _database = FirebaseDatabase.instance;

  List<ChatMessage>? _chatUserList;
  UserModel? _chatUser;
  String serverToken = "<FCM SERVER KEY>";
  StreamSubscription<QuerySnapshot>? _userListSubscription;

  static final CollectionReference _userCollection =
      kfirestore.collection(USERS_COLLECTION);

  /// Get FCM server key from firebase project settings
  UserModel? get chatUser => _chatUser;
  set setChatUser(UserModel model) {
    _chatUser = model;
  }

  String? _channelName;
  // Query messageQuery;

  List<ChatMessage>? get chatUserList {
    if (_chatUserList == null) {
      return null;
    } else {
      return List.from(_chatUserList!);
    }
  }

  void databaseInit(String userId, String myId) async {
    if (_channelName == null) {
      getChannelName(userId, myId);
    }
    // getChannelName(userId, myId);

    _userListSubscription = _userCollection
        .doc(userId)
        .collection(CHAT_USER_LIST_COLLECTION)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (snapshot.docChanges.isEmpty) {
        return;
      }
      if (snapshot.docChanges.first.type == DocumentChangeType.added) {
        _onChatUserAdded(snapshot.docChanges.first.doc);
      }
      // else if (snapshot.docChanges.first.type ==
      //     DocumentChangeType.removed) {
      //   // _onNotificationRemoved(snapshot.docChanges.first.doc);
      else if (snapshot.docChanges.first.type == DocumentChangeType.modified) {
        _onChatUserUpdated(snapshot.docChanges.first.doc);
      }
    });
  }

  /// Fecth FCM server key from firebase Remote config
  /// FCM server key is stored in firebase remote config
  /// you have to add server key in firebase remote config
  /// To fetch this key go to project setting in firebase
  /// Click on `cloud messaging` tab
  /// Copy server key from `Project credentials`
  /// Now goto `Remote Congig` section in fireabse
  /// Add [FcmServerKey]  as paramerter key and below json in Default vslue
  ///  ``` json
  ///  {
  ///    "key": "FCM server key here"
  ///  } ```
  /// For more detail visit:- https://github.com/TheAlphamerc/flutter_twitter_clone/issues/28#issue-611695533
  /// For package detail check:-  https://pub.dev/packages/firebase_remote_config#-readme-tab-
  void getFCMServerKey() async {
    // final RemoteConfig remoteConfig = await RemoteConfig.instance;
    // await remoteConfig.fetch(expiration: const Duration(hours: 5));
    // await remoteConfig.activateFetched();
    // var data = remoteConfig.getString('FcmServerKey');
    // if (data != null && data.isNotEmpty) {
    //   serverToken = jsonDecode(data)["key"];
    // } else {
    //   cprint("Please configure Remote config in firebase",
    //       errorIn: "getFCMServerKey");
    // }
  }

  /// Fetch users list to who have ever engaged in chat message with logged-in user
  void getUserchatList(String userId) async {
    try {
      // _userListCollection.doc(userId).get()
      _chatUserList = <ChatMessage>[];

      await _userCollection
          .doc(userId)
          .collection(CHAT_USER_LIST_COLLECTION)
          .get()
          .then((QuerySnapshot querySnapshot) {
        if (querySnapshot != null && querySnapshot.docs.isNotEmpty) {
          for (var i = 0; i < querySnapshot.docs.length; i++) {
            final ds = querySnapshot.docs[i].data() as Map ?? {};
            final model = ChatMessage.fromJson(ds["lastMessage"]);
            model.key = querySnapshot.docs[i].id;
            _chatUserList!.add(model);
          }
          // _userlist.addAll(_userFilterlist);
          // _userFilterlist.sort((x, y) => y.followers.compareTo(x.followers));
        } else {
          _chatUserList = null;
        }
      });

      // kDatabase
      //     .child('chatUsers')
      //     .child(userId)
      //     .once()
      //     .then((DataSnapshot snapshot) {
      //   _chatUserList = List<ChatMessage>();
      //   if (snapshot.value != null) {
      //     var map = snapshot.value;
      //     if (map != null) {
      //       map.forEach((key, value) {
      //         var model = ChatMessage.fromJson(value);
      //         model.key = key;
      //         _chatUserList.add(model);
      //       });
      //     }
      //   } else {
      //     _chatUserList = null;
      // //   }
      // });
      notifyListeners();
    } catch (error) {
      cprint(error);
    }
  }

  void onMessageSubmitted(ChatMessage message,
      {required UserModel myUser, required UserModel secondUser}) {
    // print(chatUser!.userId);
    try {
      // if (_messageList == null || _messageList.length < 1) {
      // kfirestore.doc(message.senderId).set({"receiver":message.receiverId, "lastMessage":message.toJson()});
      // _userListCollection.doc(message.senderId).set({
      //   "users": FieldValue.arrayUnion([message.receiverId]),
      //   "lastMessage": message.toJson()
      // });
      // _userListCollection.doc(chatUser.userId).set({
      //   "users": FieldValue.arrayUnion([message.senderId]),
      //   "lastMessage": message.toJson()
      // });
      _userCollection
          .doc(message.senderId)
          .collection(CHAT_USER_LIST_COLLECTION)
          .doc(message.receiverId)
          .set({"lastMessage": message.toJson()});
      _userCollection
          .doc(message.receiverId)
          .collection(CHAT_USER_LIST_COLLECTION)
          .doc(message.senderId)
          .set({"lastMessage": message.toJson()});
      // kDatabase
      //     .child('chatUsers')
      //     .child(message.senderId)
      //     .child(message.receiverId)
      //     .set(message.toJson());

      // kDatabase
      //     .child('chatUsers')
      //     .child(chatUser.userId)
      //     .child(message.senderId)
      //     .set(message.toJson());
      kfirestore
          .collection(MESSAGES_COLLECTION)
          .doc(_channelName)
          .collection(MESSAGES_COLLECTION)
          .doc()
          .set(message.toJson());
      // kDatabase.child('chats').child(_channelName).push().set(message.toJson());
      // sendAndRetrieveMessage(message);
      logEvent('send_message');
    } catch (error) {
      cprint(error);
    }
  }

  String? getChannelName(String user1, String user2) {
    user1 = user1.substring(0, 5);
    user2 = user2.substring(0, 5);
    List<String> list = [user1, user2];
    list.sort();
    _channelName = '${list[0]}-${list[1]}';
    // cprint(_channelName); //2RhfE-5kyFB
    return _channelName;
  }

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  void sendAndRetrieveMessage(ChatMessage model) async {
    /// on noti
    // await firebaseMessaging.requestNotificationPermissions(
    //   const IosNotificationSettings(
    //       sound: true, badge: true, alert: true, provisional: false),
    // );
    // if (chatUser.fcmToken == null) {
    //   return;
    // }

    var body = jsonEncode(<String, dynamic>{
      'notification': <String, dynamic>{
        'body': model.message,
        'title': "Message from ${model.senderName}"
      },
      'priority': 'high',
      'data': <String, dynamic>{
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'id': '1',
        'status': 'done',
        "type": NotificationType.Message.toString(),
        "senderId": model.senderId,
        "receiverId": model.receiverId,
        "title": "title",
        "body": model.message,
        "tweetId": ""
      },
      'to': chatUser!.fcmToken
    });
    var response = await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverToken',
        },
        body: body);
    print(response.body.toString());
  }

  void _onChatUserUpdated(DocumentSnapshot snapshot) {
    if (_chatUserList == null) {
      _chatUserList = <ChatMessage>[];
    }
    if (snapshot.data != null) {
      var map = (snapshot.data()?? {}) as Map;
      var model = ChatMessage.fromJson(map["lastMessage"]);
      model.key = snapshot.id;
      if (_chatUserList!.length > 0 &&
          _chatUserList!.any((x) => x.key == model.key)) {
        final index = _chatUserList!.indexWhere((x) => x.key == model.key);
        _chatUserList![index] = model;
        cprint("chat user updated1" + model.message);
        notifyListeners();
      }
    }
  }

  void _onChatUserAdded(DocumentSnapshot snapshot) {
    if (_chatUserList == null) {
      _chatUserList = <ChatMessage>[];
    }
    if (snapshot.exists) {
      var map = (snapshot.data()?? {}) as Map;
      var model = ChatMessage.fromJson(map);
      model.key = snapshot.id;
      if (_chatUserList!.length > 0 &&
          _chatUserList!.any((x) => x.key == model.key)) {
        return;
      }
      _chatUserList!.add(model);
      cprint("New chat user added");
    } else {
      _chatUserList = null;
    }
    notifyListeners();
  }
}
