import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/theme.dart';
import 'package:flutter_twitter_clone/widgets/newWidget/customUrlText.dart';

class SettingRowWidget extends StatelessWidget {
  const SettingRowWidget(
    this.title, {
    Key? key,
    this.navigateTo,
    this.subtitle,
    this.textColor = Colors.black,
    this.onPressed,
    this.vPadding = 0,
    this.showDivider = true,
    this.visibleSwitch = false,
    this.showCheckBox = false,
  }) : super(key: key);
  final bool visibleSwitch, showDivider, showCheckBox;
  final String? navigateTo;
  final String? subtitle;
  final String? title;
  final Color textColor;
  final Function? onPressed;
  final double vPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding:
              EdgeInsets.symmetric(vertical: vPadding, horizontal: 18),
          onTap: () {
            if (onPressed != null) {
              onPressed!();
              return;
            }
            if (navigateTo == null) {
              return;
            }
            Navigator.pushNamed(context, '/$navigateTo');
          },
          title: title == null
              ? null
              : UrlText(
                  text: title ?? '',
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
          subtitle: subtitle == null
              ? null
              : UrlText(
                  text: subtitle!,
                  style: TextStyle(
                      color: TwitterColor.paleSky, fontWeight: FontWeight.w400),
                ),
          trailing: showCheckBox
              ? !showCheckBox
                  ? SizedBox()
                  : Checkbox(value: true, onChanged: (val) {})
              : !visibleSwitch
                  ? null
                  : Switch(
                      onChanged: (val) {},
                      value: false,
                    ),
        ),
        !showDivider ? SizedBox() : Divider(height: 0)
      ],
    );
  }
}
