import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fehviewer/store/db/entity/gallery_task.dart';
import 'package:fehviewer/store/db/entity/tag_translate_info.dart';
import 'package:fehviewer/store/db/entity/view_history.dart';
import 'package:fehviewer/store/db/isar.dart';
import 'package:fehviewer/store/db/isar_isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../fehviewer.dart';
import 'entity/gallery_image_task.dart';
import 'entity/tag_translat.dart';

class IsarHelper {
  late final Isar isar;

  Future<void> initIsar() async {
    isar = await openIsar();
  }

  Future<List<GalleryProvider>> getAllHistory() async {
    final viewHistories =
        await isar.viewHistories.where().sortByLastViewTimeDesc().findAll();
    final _histories = viewHistories
        .map((e) => GalleryProvider.fromJson(
            jsonDecode(e.galleryProviderText) as Map<String, dynamic>))
        .toList();
    return _histories;
  }

  Future<GalleryProvider?> getHistory(String gid) async {
    final _gid = int.tryParse(gid) ?? 0;
    final viewHistory = await isar.viewHistories.get(_gid);
    if (viewHistory == null) {
      return null;
    }
    return GalleryProvider.fromJson(
        jsonDecode(viewHistory.galleryProviderText) as Map<String, dynamic>);
  }

  Future<void> addHistoryAsync(GalleryProvider galleryProvider) async {
    // return;
    final gid = int.tryParse(galleryProvider.gid ?? '0') ?? 0;
    final lastViewTime = galleryProvider.lastViewTime ?? 0;

    await isar.writeTxn(() async {
      await isar.viewHistories.put(ViewHistory(
          gid: gid,
          lastViewTime: lastViewTime,
          galleryProviderText: jsonEncode(galleryProvider)));
    });
  }

  Future<void> addHistoryIsolate(GalleryProvider galleryProvider) async {
    compute(addHistory, galleryProvider.toJson());
  }

  Future<void> removeHistory(String gid) async {
    final _gid = int.tryParse(gid) ?? 0;
    await isar.writeTxn(() async {
      await isar.viewHistories.delete(_gid);
    });
  }

  Future<void> cleanHistory() async {
    await isar.writeTxn(() async {
      await isar.viewHistories.where().deleteAll();
    });
  }

  Future<void> addHistoriesAsync(List<GalleryProvider> allHistory) async {
    final viewHistories = allHistory
        .map((e) => ViewHistory(
            gid: int.tryParse(e.gid ?? '0') ?? 0,
            lastViewTime: e.lastViewTime ?? 0,
            galleryProviderText: jsonEncode(e)))
        .toList();

    await isar.writeTxn(() async {
      await isar.viewHistories.putAll(viewHistories);
    });
  }

  Future<void> putAllTagTranslate(
    List<TagTranslat> tagTranslates,
  ) async {
    final tagTranslate = isar.tagTranslats;
    await isar.writeTxn(() async {
      await tagTranslate.putAll(tagTranslates);
    });
  }

  Future<List<String?>> findAllTagNamespace() async {
    final result = await isar.tagTranslats
        .where()
        .distinctByNamespace()
        .namespaceProperty()
        .findAll();
    return result;
  }

  // 查询 tag
  Future<TagTranslat?> findTagTranslate(String key, {String? namespace}) async {
    if (namespace != null && namespace.isNotEmpty) {
      final result = await isar.tagTranslats
          .where()
          .keyEqualTo(key)
          .filter()
          .namespaceEqualTo(namespace)
          .findAll();
      return result.lastOrNull;
    } else {
      final result = await isar.tagTranslats
          .where()
          .namespaceNotEqualTo('rows')
          .filter()
          .keyEqualTo(key)
          .findAll();
      return result.lastOrNull;
    }
  }

  // 模糊查询 通过tag或者tag翻译的部分内容
  Future<List<TagTranslat>> findTagTranslateContains(
      String text, int limit) async {
    final result = await isar.tagTranslats
        .where(sort: Sort.desc)
        .anyLastUseTime()
        .filter()
        .not()
        .namespaceEqualTo('rows')
        .and()
        .keyContains(text)
        .or()
        .nameContains(text)
        .limit(limit)
        .findAll();

    logger.d('result.len ${result.length}');

    return result;
  }

  Future<void> tapTagTranslate(TagTranslat tagTranslate) async {
    final newTagTranslate = tagTranslate.copyWith(
      lastUseTime: DateTime.now().millisecondsSinceEpoch,
    );
    await isar.writeTxn(() async {
      await isar.tagTranslats.putByKeyNamespace(newTagTranslate);
    });
  }

  Future<void> removeAllTagTranslate() async {
    await isar.writeTxn(() async {
      final count = await isar.tagTranslats.where().deleteAll();
      logger.d('delete count $count');
    });
  }

  /// GalleryTasks
  Future<List<GalleryTask>> findAllGalleryTasks() async {
    final taks = await isar.galleryTasks.where().sortByAddTimeDesc().findAll();
    return taks;
  }

  Future<GalleryTask?> findGalleryTaskByGid(int gid) async {
    return await isar.galleryTasks.get(gid);
  }

  Future<void> putGalleryTask(GalleryTask galleryTask,
      {bool replaceOnConflict = true}) async {
    final existGids = isar.galleryTasks.where().gidProperty().findAllSync();
    final taskExist = existGids.contains(galleryTask.gid);

    if (replaceOnConflict) {
      await isar.writeTxn(() async {
        await isar.galleryTasks.put(galleryTask);
      });
    } else {
      if (!taskExist) {
        await isar.writeTxn(() async {
          await isar.galleryTasks.put(galleryTask);
        });
      }
    }
  }

  Future<void> putAllGalleryTasks(
    List<GalleryTask> galleryTasks, {
    bool replaceOnConflict = true,
  }) async {
    await isar.writeTxn(() async {
      await isar.galleryTasks.putAll(galleryTasks);
    });
  }

  Future<void> removeGalleryTask(int gid) async {
    await isar.writeTxn(() async {
      await isar.galleryTasks.delete(gid);
    });
  }

  /// ImageTasks
  Future<List<GalleryImageTask>> findImageTaskAllByGid(int gid) async {
    return await isar.galleryImageTasks
        .where()
        .gidEqualTo(gid)
        .sortBySer()
        .findAll();
  }

  List<GalleryImageTask> findImageTaskAllByGidSync(int gid) {
    return isar.galleryImageTasks
        .where()
        .gidEqualTo(gid)
        .sortBySer()
        .findAllSync();
  }

  GalleryImageTask? findImageTaskAllByGidSerSync(int gid, int ser) {
    return isar.galleryImageTasks.getByGidSerSync(gid, ser);
  }

  Future<GalleryImageTask?> findImageTaskAllByGidSer(int gid, int ser) {
    return isar.galleryImageTasks.getByGidSer(gid, ser);
  }

  Future<void> putImageTask(GalleryImageTask imageTask) async {
    await isar.writeTxn(() async {
      await isar.galleryImageTasks.putByGidSer(imageTask);
    });
  }

  Future<void> putAllImageTask(List<GalleryImageTask> imageTasks) async {
    await isar.writeTxn(() async {
      await isar.galleryImageTasks.putAllByGidSer(imageTasks);
    });
  }

  Future<void> removeImageTask(int gid) async {
    await isar.writeTxn(() async {
      await isar.galleryImageTasks.where().gidEqualTo(gid).deleteAll();
    });
  }

  Future<void> updateImageTaskStatus(int gid, int ser, int status) async {
    final tasks = await isar.galleryImageTasks.getByGidSer(gid, ser);
    await isar.writeTxn(() async {
      if (tasks != null) {
        await isar.galleryImageTasks
            .putByGidSer(tasks.copyWith(status: status));
      }
    });
  }

  Future<List<GalleryImageTask>> finaAllImageTaskByGidAndStatus(
      int gid, int status) async {
    return await isar.galleryImageTasks
        .where()
        .gidEqualTo(gid)
        .filter()
        .statusEqualTo(status)
        .findAll();
  }

  Future<void> putTagTranslateVersion(String version) async {
    final tagTranslateInfo = isar.tagTranslateInfos.getSync(0) ??
        TagTranslateInfo(localVersion: version);
    await isar.writeTxn(() async {
      await isar.tagTranslateInfos
          .put(tagTranslateInfo.copyWith(localVersion: version));
    });
  }

  String getTranslateVersion() {
    final tagTranslateInfo = isar.tagTranslateInfos.getSync(0);
    return tagTranslateInfo?.localVersion ?? '';
  }
}
