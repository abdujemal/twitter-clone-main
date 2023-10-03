// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_twitter_clone/helper/theme.dart';

class FlatButton extends StatelessWidget {
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final BorderRadiusGeometry? borderRadius;
  final double? width;
  final VoidCallback onTap;
  final Color? color;
  final Widget child;
  final Color? splashColor;
  const FlatButton({
    Key? key,
    this.margin,
    this.width,
    required this.onTap,
    this.padding,
    this.borderRadius,
    this.color,
    required this.child,
    this.splashColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: margin,
        width: MediaQuery.of(context).size.width,
        child: InkWell(
          onTap: onTap,
          // borderRadius: BorderRadius.circular(borderRadius),
          splashColor: splashColor,
          child: Ink(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: color,
              ),
              padding: padding,
              child: child),
        ));
  }
}
