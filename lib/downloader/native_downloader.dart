// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

// You can found another style downloader from this link
// https://github.com/project-violet/violet/tree/70541144c22cd91eee8a00ca99dd80e0d666c43f/lib/pages/download/downloader
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info/device_info.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart' as sync;
import 'package:violet/component/downloadable.dart';

typedef CDownloaderInit = Void Function(Int64);
typedef DownloaderInit = void Function(int queueSize);
typedef CDownloaderDispose = Void Function();
typedef DownloaderDispose = void Function();
typedef CDownloaderStatus = Pointer<Utf8> Function();
typedef DownloaderStatus = Pointer<Utf8> Function();
typedef CDownloaderAppend = Pointer<Utf8> Function(Pointer<Utf8>);
typedef DownloaderAppend = Pointer<Utf8> Function(Pointer<Utf8> downloadInfo);

class NativeDownloadTask {
  final int id;
  final String url;
  final String fullpath;
  final Map<String, dynamic> header;

  NativeDownloadTask({this.id, this.url, this.fullpath, this.header});

  static NativeDownloadTask fromDownloadTask(int taskId, DownloadTask task) {
    var header = Map<String, String>();
    if (task.referer != null) header['referer'] = task.referer;
    if (task.accept != null) header['accept'] = task.accept;
    if (task.userAgent != null) header['user-agent'] = task.userAgent;
    if (task.headers != null) {
      task.headers.entries.forEach((element) {
        header[element.key.toLowerCase()] = element.value;
      });
    }
    return NativeDownloadTask(
      id: taskId,
      url: task.url,
      fullpath: task.downloadPath,
      header: header,
    );
  }

  String toString() {
    return jsonEncode({
      "id": id,
      "url": url,
      "fullpath": fullpath,
      "header": header,
    });
  }
}

class NativeDownloader {
  DynamicLibrary libviolet;
  DownloaderInit downloaderInit;
  DownloaderDispose downloaderDispose;
  DownloaderStatus downloaderStatus;
  DownloaderAppend downloaderAppend;
  List<DownloadTask> downloadTasks = [];

  sync.Lock lock = sync.Lock();

  Future<void> init() async {
    final soPath = await _checkSharedLibrary();
    if (soPath == null) {
      return null;
    }
    libviolet = DynamicLibrary.open(soPath);

    downloaderInit = libviolet
        .lookup<NativeFunction<CDownloaderInit>>("downloader_init")
        .asFunction();
    downloaderDispose = libviolet
        .lookup<NativeFunction<CDownloaderDispose>>("downloader_dispose")
        .asFunction();
    downloaderStatus = libviolet
        .lookup<NativeFunction<CDownloaderStatus>>("downloader_status")
        .asFunction();
    downloaderAppend = libviolet
        .lookup<NativeFunction<CDownloaderAppend>>("downloader_append")
        .asFunction();

    downloaderInit(32);
  }

  static NativeDownloader _instance;
  static Future<NativeDownloader> getInstance() async {
    if (_instance == null) {
      _instance = NativeDownloader();
      await _instance.init();
    }

    return _instance;
  }

  NativeDownloader() {
    Future.delayed(Duration(seconds: 1)).then((value) async {
      // int prev = 0;
      while (true) {
        var x = downloaderStatus().toDartString();
        // var y = int.parse(x.split('|')[2]);
        // print(x + '       ' + ((y - prev) / 1024.0).toString() + ' KB/S');
        // prev = y;
        var ll = x.split('|');
        if (ll.length == 5) {
          var complete = ll.last.split(',');
          complete.forEach((element) {
            int v = int.tryParse(element);
            if (v != null) {
              downloadTasks[v].completeCallback();
            }
          });
        }
        await Future.delayed(Duration(milliseconds: 100));
      }
    });
  }

  Future<void> addTask(DownloadTask task) async {
    await lock.synchronized(() {
      downloadTasks.add(task);
      downloaderAppend(
          NativeDownloadTask.fromDownloadTask(downloadTasks.length, task)
              .toString()
              .toNativeUtf8());
    });
  }

  Future<void> addTasks(List<DownloadTask> tasks) async {
    await lock.synchronized(() {
      tasks.forEach((task) {
        downloadTasks.add(task);
        downloaderAppend(
            NativeDownloadTask.fromDownloadTask(downloadTasks.length - 1, task)
                .toString()
                .toNativeUtf8());
      });
    });
  }

  Future<String> _checkSharedLibrary() async {
    final dir = await getTemporaryDirectory();
    if (dir == null) {
      return null;
    }
    final libFile = File(dir.path + "/libviolet.so");
    if (await libFile.exists()) return libFile.path;
    if (Platform.isAndroid) {
      final devicePlugin = DeviceInfoPlugin();
      final deviceInfo = await devicePlugin.androidInfo;
      if (deviceInfo == null) {
        return null;
      }
      String soResource = "assets/libviolet/armeabi-v7a/libviolet.so";
      if (kDebugMode) soResource = "assets/libviolet/x86/libviolet.so";
      final support64 = deviceInfo.supported64BitAbis;
      if (support64 != null && support64.length > 0) {
        if (kDebugMode)
          soResource = "assets/libviolet/arm64-v8a/libviolet.so";
        else
          soResource = "assets/libviolet/arm64-v8a/libviolet.so";
      }
      final data = await rootBundle.load(soResource);
      if (data == null) {
        return null;
      }
      final createFile = await libFile.create();
      if (createFile == null) {
        return null;
      }
      final writeFile = await createFile.open(mode: FileMode.write);
      if (writeFile == null) {
        return null;
      }
      await writeFile.writeFrom(Uint8List.view(data.buffer));
      return libFile.path;
    }
    return null;
  }
}
