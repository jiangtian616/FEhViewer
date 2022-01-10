import 'package:fehviewer/common/controller/base_controller.dart';
import 'package:fehviewer/common/global.dart';
import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/const/const.dart';
import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/models/index.dart';
import 'package:fehviewer/network/gallery_request.dart';
import 'package:fehviewer/pages/tab/controller/favorite_sublist_controller.dart';
import 'package:fehviewer/pages/tab/controller/favorite_tabbar_controller.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class UserController extends ProfileController {
  bool get isLogin => user.value.memberId?.isNotEmpty ?? false;
  Rx<User> user = defUser().obs;

  final EhConfigService _ehConfigService = Get.find();

  void _logOut() {
    user(defUser());
    final WebviewCookieManager cookieManager = WebviewCookieManager();
    cookieManager.clearCookies();
  }

  @override
  void onInit() {
    super.onInit();
    everProfile<User>(
      user,
      (User value) {
        logger.d('everProfile User  => ${value.toJson()}');
        Global.profile.user = value;
        if (Get.isRegistered<FavoriteTabberController>()) {
          Get.find<FavoriteTabberController>().onInit();
          Get.find<FavoriteTabberController>().update();
        }
      },
    );

    user(Global.profile.user);
  }

  Future<void> showLogOutDialog(BuildContext context) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Logout'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(L10n.of(context).cancel),
              onPressed: () {
                Get.back();
              },
            ),
            CupertinoDialogAction(
              child: Text(L10n.of(context).ok),
              onPressed: () async {
                (await Api.cookieJar).deleteAll();
                // userController.user(User());
                _logOut();
                _ehConfigService.isSiteEx.value = false;
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
