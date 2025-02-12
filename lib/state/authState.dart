import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_twitter_clone/helper/enum.dart';
import 'package:flutter_twitter_clone/helper/utility.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as Path;
import '../helper/constant.dart';
import 'appState.dart';
import 'package:firebase_database/firebase_database.dart' as dabase;

class AuthState extends AppState {
  AuthStatus authStatus = AuthStatus.NOT_DETERMINED;
  bool isSignInWithGoogle = false;
  User? user;
  String? userId;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  dabase.Query? _profileQuery;
  List<UserModel>? _profileUserModelList;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  UserModel? get profileUserModel {
    if (_profileUserModelList != null && _profileUserModelList!.length > 0) {
      return _profileUserModelList!.last;
    } else {
      return null;
    }
  }

  static final CollectionReference _userCollection =
      kfirestore.collection(USERS_COLLECTION);

  void removeLastUser() {
    _profileUserModelList!.removeLast();
  }

  /// Logout from device
  void logoutCallback() async {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    _userModel = null;
    user = null;
    _profileUserModelList = null;
    if (isSignInWithGoogle) {
      await _googleSignIn.signOut();
      logEvent('google_logout');
    }
    await _firebaseAuth.signOut();
    notifyListeners();
  }

  /// Alter select auth method, login and sign up page
  void openSignUpPage() {
    authStatus = AuthStatus.NOT_LOGGED_IN;
    userId = '';
    notifyListeners();
  }

  Stream<DocumentSnapshot> callStream({String? uid}) =>
      _userCollection.doc(uid).snapshots();

  databaseInit() {
    try {
      if (_profileQuery == null) {
        _userCollection.doc(user!.uid).snapshots().listen(_onProfileChanged);
      }
    } catch (error) {
      cprint(error, errorIn: 'databaseInit');
    }
  }

  /// Verify user's credentials for login
  Future<String?> signIn(String email, String password,
      {GlobalKey<ScaffoldState>? scaffoldKey}) async {
    try {
      loading = true;
      var result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      user = result.user;
      userId = user!.uid;
      return user!.uid;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signIn');
      // kAnalytics.logLogin(loginMethod: 'email_login');
      customSnackBar(scaffoldKey!, error.toString());
      // logoutCallback();
      return null;
    }
  }

  /// Create user from `google login`
  /// If user is new then it create a new user
  /// If user is old then it just `authenticate` user and return firebase user data
  Future<User?> handleGoogleSignIn() async {
    try {
      /// Record log in firebase kAnalytics about Google login
      // kAnalytics.logLogin(loginMethod: 'google_login');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google login cancelled by user');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // final AuthCredential credential = GoogleAuthProvider.getCredential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );\

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      user = (await _firebaseAuth.signInWithCredential(credential)).user;
      authStatus = AuthStatus.LOGGED_IN;
      userId = user!.uid;
      isSignInWithGoogle = true;
      createUserFromGoogleSignIn(user!);
      notifyListeners();
      return user!;
    } on PlatformException catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } on Exception catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    } catch (error) {
      user = null;
      authStatus = AuthStatus.NOT_LOGGED_IN;
      cprint(error, errorIn: 'handleGoogleSignIn');
      return null;
    }
  }

  /// Create user profile from google login
  createUserFromGoogleSignIn(User user) {
    var diff = DateTime.now().difference(user.metadata.creationTime!);
    // Check if user is new or old
    // If user is new then add new user to firebase realtime katabase
    if (diff < Duration(seconds: 15)) {
      UserModel model = UserModel(
        bio: 'Edit profile to update bio',
        dob: DateTime(1950, DateTime.now().month, DateTime.now().day + 3)
            .toString(),
        location: 'Somewhere in universe',
        profilePic: user.photoURL,
        displayName: user.displayName,
        email: user.email,
        key: user.uid,
        userId: user.uid,
        contact: user.phoneNumber,
        isVerified: user.emailVerified,
      );
      createUser(model, newUser: true);
    } else {
      cprint('Last login at: ${user.metadata.lastSignInTime}');
    }
  }

  /// Create new user's profile in db
  Future<String?> signUp(UserModel userModel,
      {required GlobalKey<ScaffoldState> scaffoldKey,
      required String password}) async {
    try {
      loading = true;
      var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: userModel.email ?? "",
        password: password,
      );
      user = result.user;
      authStatus = AuthStatus.LOGGED_IN;
      // kAnalytics.logSignUp(signUpMethod: 'register');
      result.user!.updateProfile(
          displayName: userModel.displayName, photoURL: userModel.profilePic);

      _userModel = userModel;
      _userModel!.key = user!.uid;
      _userModel!.userId = user!.uid;
      createUser(_userModel!, newUser: true);
      return user!.uid;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'signUp');
      customSnackBar(scaffoldKey, error.toString());
      return null;
    }
  }

  /// `Create` and `Update` user
  /// IF `newUser` is true new user is created
  /// Else existing user will update with new values
  createUser(UserModel user, {bool newUser = false}) {
    if (newUser) {
      // Create username by the combination of name and id
      user.userName = getUserName(id: user.userId!, name: user.displayName!);
      // kAnalytics.logEvent(name: 'create_newUser');

      // Time at which user is created
      user.createdAt = DateTime.now().toUtc().toString();
    }
    kfirestore.collection(USERS_COLLECTION).doc(user.userId).set(user.toJson());
    _userModel = user;
    if (_profileUserModelList != null) {
      _profileUserModelList!.last = _userModel!;
    }
    loading = false;
  }

  /// Fetch current user profile
  Future<User?> getCurrentUser() async {
    try {
      loading = true;
      logEvent('get_currentUSer');
      user = _firebaseAuth.currentUser;
      if (user != null) {
        authStatus = AuthStatus.LOGGED_IN;
        userId = user!.uid;
        getProfileUser();
      } else {
        authStatus = AuthStatus.NOT_LOGGED_IN;
      }
      loading = false;
      return user;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getCurrentUser');
      authStatus = AuthStatus.NOT_LOGGED_IN;
      return null;
    }
  }

  /// Reload user to get refresh user data
  reloadUser() async {
    await user!.reload();
    user = _firebaseAuth.currentUser;
    if (user!.emailVerified == true) {
      userModel!.isVerified = true;
      // If user verifed his email
      // Update user in firebase realtime database
      createUser(userModel!);
      cprint('User email verification complete');
      logEvent('email_verification_complete',
          parameter: {userModel!.userName!: user!.email});
    }
  }

  /// Send email verification link to email2
  Future<void> sendEmailVerification(
      GlobalKey<ScaffoldState> scaffoldKey) async {
    User? user = _firebaseAuth.currentUser;
    user!.sendEmailVerification().then((_) {
      logEvent('email_verifcation_sent',
          parameter: {userModel!.displayName!: user.email});
      customSnackBar(
        scaffoldKey,
        'An email verification link is send to your email.',
      );
    }).catchError((error) {
      cprint(error.message, errorIn: 'sendEmailVerification');
      logEvent('email_verifcation_block',
          parameter: {userModel!.displayName!: user.email});
      customSnackBar(
        scaffoldKey,
        error.message,
      );
    });
  }

  /// Check if user's email is verified
  Future<bool> isEmailVerified() async {
    User? user = _firebaseAuth.currentUser;
    return user!.emailVerified == true;
  }

  /// Send password reset link to email
  Future<void> forgetPassword(String email,
      {required GlobalKey<ScaffoldState> scaffoldKey}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email).then((value) {
        customSnackBar(scaffoldKey,
            'A reset password link is sent yo your mail.You can reset your password from there');
        logEvent('forgot+password');
      }).catchError((error) {
        cprint(error.message);
        return;
      });
    } catch (error) {
      customSnackBar(scaffoldKey, error.toString());
      return Future.value(false);
    }
  }

  /// `Update user` profile
  Future<void> updateUserProfile(UserModel userModel, {File? image}) async {
    try {
      if (image == null) {
        createUser(userModel);
      } else {
        var storageReference = FirebaseStorage.instance
            .ref()
            .child('user/profile/${Path.basename(image.path)}');
        await storageReference.putFile(image);

        storageReference.getDownloadURL().then((fileURL) async {
          print(fileURL);
          var name = userModel.displayName ?? user!.displayName;
          _firebaseAuth.currentUser!
              .updateProfile(displayName: name, photoURL: fileURL);
          // if (userModel != null) {
          userModel.profilePic = fileURL;
          createUser(userModel);
          // } else {
          //   _userModel!.profilePic = fileURL;
          //   createUser(_userModel);
          // }
        });
      }
      logEvent('update_user');
    } catch (error) {
      cprint(error, errorIn: 'updateUserProfile');
    }
  }

  /// Fetch user profile `detail` whoose userId is passed
  /// If `userProfileId` is null then logged in user's profile will fetched
  getProfileUser({String? userProfileId}) async {
    try {
      loading = true;
      if (_profileUserModelList == null) {
        _profileUserModelList = [];
      }
      userProfileId = userProfileId == null ? user!.uid : userProfileId;
      DocumentSnapshot documentSnapshot =
          await _userCollection.doc(userProfileId).get();

      if (documentSnapshot.data() != null) {
        _profileUserModelList!.add(UserModel.fromMap(
            (documentSnapshot.data() ?? {}) as Map<String, dynamic>));

        /// Get follower list
        final follower = await getfollowersList(userProfileId);
        _profileUserModelList!.last.followersList = follower;
        _profileUserModelList!.last.followers = follower.length;

        /// Get following list
        final followingUsers = await getfollowingList(userProfileId);
        _profileUserModelList!.last.followingList = followingUsers;
        _profileUserModelList!.last.following = followingUsers.length;
        if (userProfileId == user!.uid) {
          _userModel = _profileUserModelList!.last;
          _userModel!.isVerified = user!.emailVerified;

          if (!user!.emailVerified) {
            // Check if logged in user verified his email address or not
            reloadUser();
          }
          if (_userModel!.fcmToken == null) {
            updateFCMToken();
          }
        }

        logEvent('get_profile');
      }

      loading = false;
    } catch (error) {
      loading = false;
      cprint(error, errorIn: 'getProfileUser');
    }
  }

  /// if firebase token not available in profile
  /// Then get token from firebase and save it to profile
  /// When someone sends you a message FCM token is used
  void updateFCMToken() {
    if (_userModel == null) {
      return;
    }
    getProfileUser();
    _firebaseMessaging.getToken().then((String? token) {
      _userModel!.fcmToken = token;
      createUser(_userModel!);
    });
  }

  Future<List<String>> getfollowersList(String userId) async {
    final List<String> follower = [];
    QuerySnapshot querySnapshot =
        await _userCollection.doc(userId).collection(FOLLOWER_COLLECTION).get();
    if (querySnapshot.docs.isNotEmpty) {
      ((querySnapshot.docs.first.data() ??
          {}) as Map)["data"].forEach((x) {
            follower.add(x);
          });
    }
    return follower;
  }

  Future<List<String>> getfollowingList(String userId) async {
    final List<String> follower = [];
    QuerySnapshot querySnapshot = await _userCollection
        .doc(userId)
        .collection(FOLLOWING_COLLECTION)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      (querySnapshot.docs.first.data()! as Map)["data"].forEach((x) {
        follower.add(x);
      });
    }
    return follower;
  }

  /// Follow / Unfollow user
  ///
  /// If `removeFollower` is true then remove user from follower list
  ///
  /// If `removeFollower` is false then add user to follower list
  followUser({bool removeFollower = false}) {
    /// `userModel` is user who is looged-in app.
    /// `profileUserModel` is user whoose profile is open in app.
    try {
      if (removeFollower) {
        /// If logged-in user `alredy follow `profile user then
        /// 1.Remove logged-in user from profile user's `follower` list
        /// 2.Remove profile user from logged-in user's `following` list
        profileUserModel!.followersList!.remove(userModel!.userId);

        /// Remove profile user from logged-in user's following list
        userModel!.followingList!.remove(profileUserModel!.userId);
        cprint('user removed from following list', event: 'remove_follow');
      } else {
        /// if logged in user is `not following` profile user then
        /// 1.Add logged in user to profile user's `follower` list
        /// 2. Add profile user to logged in user's `following` list
        if (profileUserModel!.followersList == null) {
          profileUserModel!.followersList = [];
        }
        profileUserModel!.followersList!.add(userModel!.userId!);
        // Adding profile user to logged-in user's following list
        if (userModel!.followingList == null) {
          userModel!.followingList = [];
        }
        userModel!.followingList!.add(profileUserModel!.userId!);
      }
      // update profile user's user follower count
      profileUserModel!.followers = profileUserModel!.followersList!.length;
      // update logged-in user's following count
      userModel!.following = userModel!.followingList!.length;

      try {
        final updateWithTimestamp = <String, dynamic>{
          'data': FieldValue.arrayUnion(profileUserModel!.followersList!)
        };
        _userCollection
            .doc(profileUserModel!.userId)
            .collection(FOLLOWER_COLLECTION)
            .doc(FOLLOWER_COLLECTION)
            .set(updateWithTimestamp);

        _userCollection
            .doc(userModel!.userId)
            .collection(FOLLOWING_COLLECTION)
            .doc(FOLLOWING_COLLECTION)
            .set({"data": FieldValue.arrayUnion(userModel!.followingList!)});
      } on PlatformException catch (error) {
        cprint(error.message, errorIn: "Updateing Follow");
      } on MissingPluginException catch (error) {
        cprint(error.message, errorIn: "Missing plugin Follow");
      }
      cprint('user added to following list', event: 'add_follow');
      notifyListeners();
    } catch (error) {
      cprint(error, errorIn: 'followUser');
    }
  }

  /// Trigger when logged-in user's profile change or updated
  /// Firebase event callback for profile update
  void _onProfileChanged(DocumentSnapshot event) {
    if (event.data() != null) {
      final updatedUser = UserModel.fromMap(event.data() as Map<String, dynamic>);
      if (updatedUser.userId == user!.uid) {
        _userModel = updatedUser;
      }
      cprint('User Updated');
      notifyListeners();
    }
  }
}
