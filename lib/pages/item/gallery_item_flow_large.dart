import 'dart:ui';

import 'package:blur/blur.dart';
import 'package:fehviewer/common/service/theme_service.dart';
import 'package:fehviewer/const/theme_colors.dart';
import 'package:fehviewer/models/base/eh_models.dart';
import 'package:fehviewer/pages/item/controller/galleryitem_controller.dart';
import 'package:fehviewer/widget/rating_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'gallery_clipper.dart';
import 'gallery_item.dart';
import 'item_base.dart';

const int kTitleMaxLines = 3;
const double kRadius = 12.0;
const double kCategoryWidth = 32.0;
const double kCategoryHeight = 20.0;

class GalleryItemFlowLarge extends StatelessWidget {
  const GalleryItemFlowLarge(
      {Key? key, required this.tabTag, required this.galleryItem})
      : super(key: key);

  final dynamic tabTag;
  final GalleryItem galleryItem;

  GalleryItemController get galleryItemController =>
      Get.find(tag: galleryItem.gid);

  Widget _buildFavcatIcon() {
    return Obx(() {
      // logger.d('${_galleryItemController.isFav}');
      return Container(
        child: galleryItemController.isFav
            ? Icon(
                FontAwesomeIcons.solidHeart,
                size: 12,
                color: ThemeColors
                    .favColor[galleryItemController.galleryItem.favcat],
              )
            : Container(),
      );
    });
  }

  Widget _buildRating() {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
          child: StaticRatingBar(
            size: 14.0,
            rate: galleryItemController.galleryItem.ratingFallBack ?? 0,
            radiusRatio: 1.5,
            colorLight: ThemeColors.colorRatingMap[
                galleryItemController.galleryItem.colorRating?.trim() ?? 'ir'],
            colorDark: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey3, Get.context!),
          ),
        ),
      ],
    );
  }

  Widget _buildCount() {
    return Container(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        galleryItemController.galleryItem.filecount ?? '',
        style: const TextStyle(
          fontSize: 12,
          color: Color.fromARGB(255, 240, 240, 240),
          height: 1.12,
          // fontStyle: FontStyle.italic,
        ),
      ).frosted(
        blur: 10,
        frostColor: CupertinoColors.systemGrey.color,
        frostOpacity: 0.0,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      ),
    );
  }

  /// 构建标题
  Widget _buildTitle() {
    return Obx(() => Text(
          galleryItemController.title,
          maxLines: kTitleMaxLines,
          textAlign: TextAlign.left, // 对齐方式
          overflow: TextOverflow.ellipsis, // 超出部分
          style: const TextStyle(
            fontSize: 14,
            // height: 1.3,
            // fontWeight: FontWeight.w500,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final Widget item = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final GalleryItem galleryItem = galleryItemController.galleryItem;

      final Color _colorCategory = CupertinoDynamicColor.resolve(
          ThemeColors.catColor[galleryItem.category ?? 'default'] ??
              CupertinoColors.systemBackground,
          context);

      // 获取图片高度
      double? _getHeigth() {
        if ((galleryItem.imgWidth ?? 0) >= constraints.maxWidth) {
          return (galleryItem.imgHeight ?? 0) *
              constraints.maxWidth /
              (galleryItem.imgWidth ?? 0);
        } else {
          return galleryItem.imgHeight;
        }
      }

      final Widget container = Container(
        decoration: BoxDecoration(
          color: ehTheme.itemBackgroundColor,
          borderRadius: BorderRadius.circular(kRadius), //圆角
          boxShadow: ehTheme.isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: CupertinoDynamicColor.resolve(
                        CupertinoColors.systemGrey3, Get.context!),
                    blurRadius: 10,
                  )
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 画廊封面
            Hero(
              tag: '${galleryItem.gid}_cover_$tabTag',
              child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                    color: CupertinoDynamicColor.resolve(
                            CupertinoColors.systemGrey5, Get.context!)
                        .withOpacity(1.0),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kRadius),
                    topRight: Radius.circular(kRadius),
                  ),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        height:
                            galleryItem.imgWidth != null ? _getHeigth() : null,
                        child: CoverImg(imgUrl: galleryItem.imgUrl!),
                      ),
                      ClipPath(
                        clipper: CategoryClipper(
                            width: kCategoryWidth, height: kCategoryHeight),
                        child: Container(
                          width: kCategoryWidth,
                          height: kCategoryHeight,
                          color: _colorCategory.withOpacity(0.8),
                        ),
                      ),
                      // Positioned(
                      //     bottom: 4, right: 4, child: _buildFavcatIcon()),
                      // Positioned(bottom: 4, left: 4, child: _buildRating()),
                      Positioned(bottom: 4, right: 4, child: _buildCount()),
                      Container(
                        height: (kCategoryHeight + kRadius * 0.8) / 2,
                        width: (kCategoryWidth + kRadius * 0.8) / 2,
                        alignment: Alignment.center,
                        child: Text(
                          galleryItem.translated ?? '',
                          style: const TextStyle(
                              fontSize: 8,
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              height: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// 画廊信息等
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildRating(),
                    const Spacer(),
                    _buildFavcatIcon(),
                  ],
                ),
                const SizedBox(height: 6),
                _buildTitle(),
                const SizedBox(height: 6),
                // _buildSimpleTagsView(),
                TagWaterfallFlowViewBox(
                  simpleTags: galleryItemController.galleryItem.simpleTags,
                ),
              ],
            ).paddingAll(8.0),
          ],
        ),
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: container,
        onTap: () => galleryItemController.onTap(tabTag),
        onLongPress: galleryItemController.onLongPress,
      ).autoCompressKeyboard(context);
    });

    return item;
  }
}
