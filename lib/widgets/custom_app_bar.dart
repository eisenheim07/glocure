import 'package:flutter/material.dart';
import 'package:glocure/utils/size_utils.dart';

import '../utils/image_constant.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor = Colors.white,
    this.foregroundColor,
    this.showDefaultLogo = true,
    this.centerTitle = false,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showDefaultLogo;
  final bool centerTitle;
  final double? titleSpacing;
  final double? leadingWidth;
  final double? toolbarHeight;

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;
    double? effectiveLeadingWidth;

    if (leading != null) {
      leadingWidget = leading;
      effectiveLeadingWidth = leadingWidth ?? 56.h;
    } else if (showDefaultLogo) {
      leadingWidget = Container(
        margin: EdgeInsets.only(left: 16.h),
        child: Image(image: AssetImage(ImageConstant.imgGlocureLogo), fit: BoxFit.contain),
      );
      effectiveLeadingWidth = leadingWidth ?? 140.h;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: AppBar(
        leadingWidth: effectiveLeadingWidth,
        toolbarHeight: toolbarHeight ?? 60.h,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor,
        scrolledUnderElevation: 0.0,
        elevation: 0,
        title: title,
        centerTitle: centerTitle,
        titleSpacing: titleSpacing ?? (showDefaultLogo && leading == null ? 0 : null),
        leading: leadingWidget,
        automaticallyImplyLeading: leading == null && !showDefaultLogo,
        actions: actions != null
            ? [
                Padding(
                  padding: EdgeInsets.only(right: 16.h),
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? 60.h);
}
