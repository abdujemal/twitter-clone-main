import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/constant.dart';
import 'package:flutter_twitter_clone/helper/theme.dart';
import 'package:flutter_twitter_clone/model/user.dart';
import 'package:flutter_twitter_clone/state/authState.dart';
import 'package:flutter_twitter_clone/widgets/customWidgets.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/rippleButton.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/title_text.dart';
import 'package:provider/provider.dart';

class UserListWidget extends StatelessWidget {
  final List<UserModel>? userslist;
  final String? emptyScreenText;
  final String? emptyScreenSubTileText;
  UserListWidget({
    Key? key,
    this.userslist,
    this.emptyScreenText,
    this.emptyScreenSubTileText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AuthState>(context, listen: false);
    var myFollowingList = state.userModel.followingList;
    String myId = state.userModel.key!;
    return ListView.separated(
      itemBuilder: (context, index) {
        return UserTile(
            user: userslist![index],
            myId: myId,
            isFollow:
                myFollowingList!.any((id) => id == userslist![index].userId));
      },
      separatorBuilder: (context, index) {
        return Divider(
          height: 0,
        );
      },
      itemCount: userslist!.length,
    );
  }
}

/// if value of `isFollow` is true then display [Following] button
/// if value of `isFollow` is false then display [Follow] button
/// if myId is equal to [user.userId] then hide [Follow]/[Following] button
class UserTile extends StatelessWidget {
  const UserTile({Key? key, this.user, this.myId, this.isFollow})
      : super(key: key);
  final UserModel? user;
  final String? myId;
  final bool? isFollow;

  /// Return empty string for default bio
  /// Max length of bio is 100
  String? getBio(String? bio) {
    if (bio != null && bio.isNotEmpty && bio != "Edit profile to update bio") {
      if (bio.length > 100) {
        bio = bio.substring(0, 100) + '...';
        return bio;
      } else {
        return bio;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      color: TwitterColor.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            onTap: () {
              Navigator.of(context).pushNamed("/ProfilePage/${ user!.userId??null}");
            },
            leading: RippleButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/ProfilePage/${ user!.userId??null}");
              },
              borderRadius: BorderRadius.all(Radius.circular(60)),
              child: customImage(context, user!.profilePic, height: 55),
            ),
            title: Row(
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(
                      minWidth: 0, maxWidth: fullWidth(context) * .4),
                  child: TitleText(user!.displayName ?? "",
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      overflow: TextOverflow.ellipsis),
                ),
                SizedBox(width: 3),
                user!.isVerified == true
                    ? customIcon(
                        context,
                        icon: AppIcon.blueTick,
                        istwitterIcon: true,
                        iconColor: AppColor.primary,
                        size: 13,
                        paddingIcon: 3,
                      )
                    : SizedBox(width: 0),
              ],
            ),
            subtitle: Text(user!.userName ?? "Unknown"),
            trailing: myId == user!.userId
                ? SizedBox.shrink()
                : RippleButton(
                    onPressed: () {},
                    splashColor: TwitterColor.dodgetBlue_50.withAlpha(100),
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isFollow == true ? 15 : 20,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isFollow == true
                            ? TwitterColor.dodgetBlue
                            : TwitterColor.white,
                        border: Border.all(
                          color: TwitterColor.dodgetBlue,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        isFollow ==true ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: isFollow == true ? TwitterColor.white : Colors.blue,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          getBio(user!.bio) == null
              ? SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.only(left: 90),
                  child: Text(
                    getBio(user!.bio) ?? "No Bio",
                  ),
                )
        ],
      ),
    );
  }
}
