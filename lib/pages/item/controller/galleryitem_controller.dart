import 'package:fehviewer/common/service/ehconfig_service.dart';
import 'package:fehviewer/generated/l10n.dart';
import 'package:fehviewer/models/index.dart';
import 'package:fehviewer/pages/controller/fav_controller.dart';
import 'package:fehviewer/route/navigator_util.dart';
import 'package:fehviewer/utils/logger.dart';
import 'package:fehviewer/utils/toast.dart';
import 'package:fehviewer/utils/vibrate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tuple/tuple.dart';

class GalleryItemController extends GetxController {
  GalleryItemController(this.galleryItem);

  final EhConfigService _ehConfigService = Get.find();
  final FavController _favController = Get.find();

  /// 点击item
  void onTap(String? tabTag) {
    logger.d('${galleryItem.englishTitle} ');
    NavigatorUtil.goGalleryPage(galleryItem: galleryItem, tabTag: tabTag);
  }

  void onTapDown(_) => _updatePressedColor();
  void onTapUp(_) {
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      _updateNormalColor();
    });
  }

  void onTapCancel() => _updateNormalColor();

  @override
  void onInit() {
    super.onInit();
    if (galleryItem.favTitle != null && galleryItem.favTitle!.isNotEmpty) {
      isFav = true;
    }
  }

  final RxBool _isFav = false.obs;
  bool get isFav => _isFav.value;
  set isFav(bool val) => _isFav.value = val;

  void setFavTitle({String favTitle = '', String? favcat}) {
    // galleryItem.favTitle = favTitle;
    galleryItem.copyWith(favTitle: favTitle);
    isFav = favTitle.isNotEmpty;
    if (favcat != null) {
      // galleryItem.favcat = favcat;
      galleryItem.copyWith(favcat: favcat);
      // logger.d('item show fav');
    } else {
      // galleryItem.favcat = '';
      // galleryItem.favTitle = '';
      galleryItem.copyWith(favcat: '', favTitle: '');
    }
  }

  String get title {
    if ((_ehConfigService.isJpnTitle.value) &&
        (galleryItem.japaneseTitle?.isNotEmpty ?? false)) {
      return galleryItem.japaneseTitle ?? '';
    } else {
      return galleryItem.englishTitle ?? '';
    }
  }

  late List<GalleryPreview> firstPagePreview;
  GalleryItem galleryItem;

  Rx<Color?> colorTap = const Color.fromARGB(0, 0, 0, 0).obs;

  void _updateNormalColor() {
    colorTap.value = Colors.transparent;
  }

  void _updatePressedColor() {
    colorTap.value = CupertinoDynamicColor.resolve(
        CupertinoColors.systemGrey4, Get.context!);
  }

  set localFav(bool value) {
    // galleryItem.localFav = value;
    galleryItem = galleryItem.copyWith(localFav: localFav);
    update();
  }

  bool get localFav => galleryItem.localFav ?? false;

  void firstPutPreview(List<GalleryPreview> galleryPreview) {
    if (galleryPreview.isNotEmpty) {
      // galleryItem.galleryPreview = galleryPreview;
      galleryItem.copyWith(galleryPreview: galleryPreview);
    }

    firstPagePreview =
        galleryItem.galleryPreview?.sublist(0, galleryPreview.length) ?? [];
    // logger.d(' _firstPagePreview ${firstPagePreview.length}');
  }

  /// 长按菜单
  Future<void> _showLongPressSheet() async {
    final BuildContext context = Get.context!;

    await showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(title),
            cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Get.back();
                },
                child: Text(S.of(context).cancel)),
            actions: <Widget>[
              if (galleryItem.favcat == null ||
                  (galleryItem.favcat?.isEmpty ?? false))
                CupertinoActionSheetAction(
                  onPressed: () {
                    if (galleryItem.gid == null || galleryItem.token == null) {
                      return;
                    }
                    _favController
                        .addFav(galleryItem.gid!, galleryItem.token!)
                        .then((Tuple2<String, String>? value) {
                      setFavTitle(favTitle: value!.item2, favcat: value.item1);
                      showToast('successfully add');
                    });
                    Get.back();
                  },
                  child: Text(S.of(context).add_to_favorites),
                ),
              if (galleryItem.favcat != null &&
                  (galleryItem.favcat?.isNotEmpty ?? false))
                CupertinoActionSheetAction(
                  onPressed: () {
                    if (galleryItem.gid == null || galleryItem.token == null) {
                      return;
                    }
                    _favController
                        .delFav(galleryItem.favcat!, galleryItem.gid!,
                            galleryItem.token!)
                        .then((_) {
                      setFavTitle(favTitle: '', favcat: '');
                      showToast('successfully deleted');
                    });
                    Get.back();
                  },
                  child: Text(S.of(context).remove_from_favorites),
                ),
            ],
          );
        });
  }

  void onLongPress() {
    vibrateUtil.heavy();
    _showLongPressSheet();
  }
}
