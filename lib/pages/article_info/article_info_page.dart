// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:violet/component/eh/eh_headers.dart';
import 'package:violet/component/eh/eh_parser.dart';
import 'package:violet/component/hentai.dart';
import 'package:violet/component/hitomi/tag_translate.dart';
import 'package:violet/database/query.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/database/user/record.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/model/article_info.dart';
import 'package:violet/network/wrapper.dart' as http;
import 'package:violet/other/dialogs.dart';
import 'package:violet/pages/article_info/simple_info.dart';
import 'package:violet/pages/artist_info/artist_info_page.dart';
import 'package:violet/pages/download/download_page.dart';
import 'package:violet/pages/main/info/lab/search_comment_author.dart';
import 'package:violet/pages/viewer/viewer_page.dart';
import 'package:violet/pages/viewer/viewer_page_provider.dart';
import 'package:violet/server/violet.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';
import 'package:violet/widgets/article_item/image_provider_manager.dart';
import 'package:violet/widgets/toast.dart';

class ArticleInfoPage extends StatelessWidget {
  final Key key;

  ArticleInfoPage({
    this.key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final data = Provider.of<ArticleInfo>(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      color: Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade200,
      padding: EdgeInsets.only(top: 0, bottom: Variables.bottomBarHeight),
      child: Card(
        elevation: 5,
        color: Settings.themeWhat ? Color(0xFF353535) : Colors.grey.shade200,
        child: SizedBox(
          width: width - 16,
          height:
              height - 36 - (mediaQuery.padding + mediaQuery.viewInsets).bottom,
          child: Container(
            // width: width,
            // height: height,
            color: Settings.themeWhat
                ? Colors.black.withOpacity(0.9)
                : Colors.white.withOpacity(0.97),
            child: ListView(
              controller: data.controller,
              children: [
                Container(
                  width: width,
                  height: 4 * 50.0 + 16,
                  color: Settings.themeWhat
                      ? Colors.grey.shade900.withOpacity(0.6)
                      : Colors.white.withOpacity(0.2),
                  child: SimpleInfoWidget(),
                ),
                // _functionButtons(width, context, data),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      child: Container(
                        width: (width - 32 - 64 - 32) / 2,
                        child: Text(
                          Translations.of(context).trans('download'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Settings.majorColor.withAlpha(230),
                      ),
                      onPressed: () async =>
                          await _downloadButtonEvent(context, data),
                    ),
                    const SizedBox(width: 4.0),
                    ElevatedButton(
                      child: Container(
                        width: (width - 32 - 64 - 32) / 2,
                        child: Text(
                          Translations.of(context).trans('read'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Settings.majorColor,
                      ),
                      onPressed: data.lockRead
                          ? null
                          : () async => await _readButtonEvent(context, data),
                    ),
                  ],
                ),
                TagInfoAreaWidget(queryResult: data.queryResult),
                DividerWidget(),
                _CommentArea(
                  headers: data.headers,
                  queryResult: data.queryResult,
                ),
                DividerWidget(),
                ExpandableNotifier(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ScrollOnExpand(
                      scrollOnExpand: true,
                      scrollOnCollapse: false,
                      child: ExpandablePanel(
                        theme: ExpandableThemeData(
                            iconColor:
                                Settings.themeWhat ? Colors.white : Colors.grey,
                            animationDuration:
                                const Duration(milliseconds: 500)),
                        header: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 0, 0),
                          child:
                              Text(Translations.of(context).trans('preview')),
                        ),
                        expanded:
                            PreviewAreaWidget(queryResult: data.queryResult),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /*_functionButtons(width, context, data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          child: Container(
            width: (width - 32 - 64 - 32) / 2,
            child: Text(
              Translations.of(context).trans('download'),
              textAlign: TextAlign.center,
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Settings.majorColor.withAlpha(230),
          ),
          onPressed: () async => await _downloadButtonEvent(context, data),
        ),
        const SizedBox(width: 4.0),
        ElevatedButton(
          child: Container(
            width: (width - 32 - 64 - 32) / 2,
            child: Text(
              Translations.of(context).trans('read'),
              textAlign: TextAlign.center,
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Settings.majorColor,
          ),
          onPressed: data.lockRead
              ? null
              : () async => await _readButtonEvent(context, data),
        ),
      ],
    );
  }*/

  _downloadButtonEvent(context, data) async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.isGranted) {
        if (await Permission.storage.request() == PermissionStatus.denied) {
          await showOkDialog(context,
              'If you do not allow file permissions, you cannot continue :(');
          return;
        }
      }
      if (!DownloadPageManager.downloadPageLoaded) {
        FlutterToast(context).showToast(
          child: ToastWrapper(
            isCheck: false,
            isWarning: true,
            msg: 'You need to open the download tab!',
          ),
          gravity: ToastGravity.BOTTOM,
          toastDuration: Duration(seconds: 4),
        );
        return;
      }
      FlutterToast(context).showToast(
        child: ToastWrapper(
          isCheck: true,
          isWarning: false,
          icon: Icons.download,
          msg: data.queryResult.id().toString() +
              Translations.of(context).trans('addtodownloadqueue'),
        ),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: 4),
      );
      await DownloadPageManager.appendTask(data.queryResult.id().toString());
      Navigator.pop(context);
    }
  }

  _readButtonEvent(context, data) async {
    if (Settings.useVioletServer) {
      await VioletServer.view(data.queryResult.id());
    }
    await (await User.getInstance()).insertUserLog(data.queryResult.id(), 0);

    if (!Settings.disableFullScreen)
      SystemChrome.setEnabledSystemUIOverlays([]);

    await ProviderManager.get(data.queryResult.id()).init();

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return Provider<ViewerPageProvider>.value(
              value: ViewerPageProvider(
                // uris: ThumbnailManager.get(queryResult.id())
                //     .item1,
                // useWeb: true,

                uris: List<String>.filled(
                    ProviderManager.get(data.queryResult.id()).length(), null),
                useProvider: true,
                provider: ProviderManager.get(data.queryResult.id()),
                headers: data.headers,
                id: data.queryResult.id(),
                title: data.queryResult.title(),
                usableTabList: data.usableTabList,
              ),
              child: ViewerPage());
        },
      ),
    ).then((value) async {
      // await (await User.getInstance())
      //     .updateUserLog(data.queryResult.id(), value[0] as int);
      // if (Settings.useVioletServer) {
      //   await VioletServer.viewClose(data.queryResult.id(), value[1] as int);
      // }
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    });
  }
}

class DividerWidget extends StatelessWidget {
  const DividerWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      width: double.infinity,
      height: 1.0,
      color: Settings.themeWhat ? Colors.grey.shade600 : Colors.grey.shade400,
    );
  }
}

class TagInfoAreaWidget extends StatelessWidget {
  final QueryResult queryResult;

  const TagInfoAreaWidget({this.queryResult});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        MultiChipWidget(
            queryResult.tags(),
            Translations.of(context).trans('tags'),
            queryResult.tags() != null
                ? (queryResult.tags() as String)
                    .split('|')
                    .where((element) => element != '')
                    .map((e) => Tuple2<String, String>(
                        e.contains(':') ? e.split(':')[0] : 'tags',
                        e.contains(':') ? e.split(':')[1] : e))
                    .toList()
                : []),
        SingleChipWidget(
            queryResult.language(),
            Translations.of(context).trans('language').split(' ')[0].trim(),
            'language'),
        MultiChipWidget(
            queryResult.artists(),
            Translations.of(context).trans('artists'),
            queryResult.artists() != null
                ? (queryResult.artists() as String)
                    .split('|')
                    .where((element) => element != '')
                    .map((e) => Tuple2<String, String>('artists', e))
                    .toList()
                : []),
        MultiChipWidget(
            queryResult.groups(),
            Translations.of(context).trans('groups'),
            queryResult.groups() != null
                ? (queryResult.groups() as String)
                    .split('|')
                    .where((element) => element != '')
                    .map((e) => Tuple2<String, String>('groups', e))
                    .toList()
                : []),
        MultiChipWidget(
            queryResult.series(),
            Translations.of(context).trans('series'),
            queryResult.series() != null
                ? (queryResult.series() as String)
                    .split('|')
                    .where((element) => element != '')
                    .map((e) => Tuple2<String, String>('series', e))
                    .toList()
                : []),
        MultiChipWidget(
            queryResult.characters(),
            Translations.of(context).trans('character'),
            queryResult.characters() != null
                ? (queryResult.characters() as String)
                    .split('|')
                    .where((element) => element != '')
                    .map((e) => Tuple2<String, String>('character', e))
                    .toList()
                : []),
        SingleChipWidget(
            queryResult.type(), Translations.of(context).trans('type'), 'type'),
        SingleChipWidget(queryResult.uploader(),
            Translations.of(context).trans('uploader'), 'uploader'),
        SingleChipWidget(queryResult.id().toString(),
            Translations.of(context).trans('id'), 'id'),
        SingleChipWidget(queryResult.classname(),
            Translations.of(context).trans('class'), 'class'),
        Container(height: 10),
      ],
    );
  }

  Widget multipleChip(dynamic target, String name, List<Widget> wrap) {
    if (target == null) return Container();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            '    $name: ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 1.0,
            runSpacing: -12.0,
            children: wrap,
          ),
        ),
      ],
    );
  }
}

class SingleChipWidget extends StatelessWidget {
  final String target;
  final String name;
  final String raw;

  SingleChipWidget(this.target, this.name, this.raw);

  @override
  Widget build(BuildContext context) {
    if (target == null) return Container();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Text(
          '    $name: ',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      Wrap(
        children: <Widget>[_Chip(group: raw.toLowerCase(), name: target)],
      ),
    ]);
  }
}

class MultiChipWidget extends StatelessWidget {
  final List<Tuple2<String, String>> groupName;
  final String name;
  final String target;

  const MultiChipWidget(this.target, this.name, this.groupName);

  @override
  Widget build(BuildContext context) {
    if (target == null) return Container();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text(
            '    $name: ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 1.0,
            runSpacing: -12.0,
            children: groupName
                .map((x) => _Chip(group: x.item1, name: x.item2))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class PreviewAreaWidget extends StatelessWidget {
  final QueryResult queryResult;

  PreviewAreaWidget({this.queryResult});

  @override
  Widget build(BuildContext context) {
    if (ProviderManager.isExists(queryResult.id())) {
      return FutureBuilder(
        future: ProviderManager.get(queryResult.id()).getSmallImagesUrl(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(child: CircularProgressIndicator());
          return GridView.count(
            controller: null,
            physics: ScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: (snapshot.data as List<String>)
                .take(30)
                .map((e) => CachedNetworkImage(
                      imageUrl: e,
                    ))
                .toList(),
          );
        },
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          // alignment: Alignment.center,
          child: Align(
            // alignment: Alignment.center,
            child: Text(
              '??? Unknown Error!',
              textAlign: TextAlign.center,
            ),
          ),
          width: 100,
          height: 100,
        )
      ],
    );
  }
}

const String urlPattern = r'http';
const String emailPattern = r'\S+@\S+';
const String phonePattern = r'[\d-]{9,}';
final RegExp linkRegExp = RegExp(
    '($urlPattern)|($emailPattern)|($phonePattern)',
    caseSensitive: false);

class _CommentArea extends StatefulWidget {
  final QueryResult queryResult;
  final Map<String, String> headers;

  _CommentArea({this.queryResult, this.headers});

  @override
  __CommentAreaState createState() => __CommentAreaState();
}

class __CommentAreaState extends State<_CommentArea> {
  List<Tuple3<DateTime, String, String>> comments = [];

  @override
  void initState() {
    super.initState();
    if (widget.queryResult.ehash() != null) {
      Future.delayed(Duration(milliseconds: 100)).then((value) async {
        var cookie =
            (await SharedPreferences.getInstance()).getString('eh_cookies');
        if (cookie != null) {
          try {
            var html = await EHSession.requestString(
                'https://exhentai.org/g/${widget.queryResult.id()}/${widget.queryResult.ehash()}/');
            var article = EHParser.parseArticleData(html);
            setState(() {
              comments = article.comment;
            });
            return;
          } catch (e) {}
        }
        var html = (await http.get(
                'https://e-hentai.org/g/${widget.queryResult.id()}/${widget.queryResult.ehash()}/'))
            .body;
        if (html.contains('This gallery has been removed or is unavailable.'))
          return;
        var article = EHParser.parseArticleData(html);
        setState(() {
          comments = article.comment;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoAreaWidget(
      queryResult: widget.queryResult,
      headers: widget.headers,
      comments: comments,
    );
  }
}

class _InfoAreaWidget extends StatefulWidget {
  final QueryResult queryResult;
  final Map<String, String> headers;
  final List<Tuple3<DateTime, String, String>> comments;

  _InfoAreaWidget({@required this.queryResult, this.headers, this.comments});

  @override
  __InfoAreaWidgetState createState() => __InfoAreaWidgetState();
}

class __InfoAreaWidgetState extends State<_InfoAreaWidget> {
  @override
  Widget build(BuildContext context) {
    return ExpandableNotifier(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: ScrollOnExpand(
          child: ExpandablePanel(
            theme: ExpandableThemeData(
                iconColor: Settings.themeWhat ? Colors.white : Colors.grey,
                animationDuration: const Duration(milliseconds: 500)),
            header: Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 0, 0),
              child: Text(
                  '${Translations.of(context).trans('comment')} (${widget.comments.length})'),
            ),
            expanded: commentArea(context),
          ),
        ),
      ),
    );
  }

  Widget commentArea(BuildContext context) {
    if (widget.comments.length == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                // alignment: Alignment.center,
                child: Align(
                  // alignment: Alignment.center,
                  child: Text(
                    'No Comments',
                    textAlign: TextAlign.center,
                  ),
                ),
                width: 100,
                height: 100,
              )
            ],
          ),
          comment(context),
        ],
      );
    } else {
      var children = List<Widget>.from(widget.comments.map((e) {
        return InkWell(
          onTap: () async {
            // showOkDialog(context, e.item3, 'Comments');
            AlertDialog alert = AlertDialog(
              content: SelectableText(e.item3),
              // actions: [
              //   okButton,
              // ],
            );
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return alert;
              },
            );
          },
          onLongPress: () async {
            _navigate(LabSearchCommentsAuthor(e.item2));
          },
          splashColor: Colors.white,
          child: ListTile(
            // dense: true,
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(e.item2),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${DateFormat('yyyy-MM-dd HH:mm').format(e.item1)}',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ]),
            subtitle: buildTextWithLinks(e.item3),
          ),
        );
      }));

      return Padding(
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            // children: AnimationConfiguration.toStaggeredList(
            //     duration: const Duration(milliseconds: 900),
            //     childAnimationBuilder: (widget) => SlideAnimation(
            //           horizontalOffset: 50.0,
            //           child: FadeInAnimation(
            //             child: widget,
            //           ),
            //         ),
            children: children + [comment(context)]),
        // ),
      );
    }
  }

  Widget comment(context) {
    return InkWell(
      onTap: () async {
        // check loginable

        if (widget.queryResult.ehash() == null) {
          await showOkDialog(context, 'Cannot write comment!');
          return;
        }

        var cookie =
            (await SharedPreferences.getInstance()).getString('eh_cookies');
        if (cookie == null || !cookie.contains('ipb_pass_hash')) {
          await showOkDialog(context, 'Please, Login First!');
          return;
        }

        TextEditingController text = TextEditingController();
        Widget okButton = TextButton(
          style: TextButton.styleFrom(primary: Settings.majorColor),
          child: Text(Translations.of(context).trans('ok')),
          onPressed: () async {
            if ((await EHSession.postComment(
                        'https://exhentai.org/g/${widget.queryResult.id()}/${widget.queryResult.ehash()}',
                        text.text))
                    .trim() !=
                '') {
              await showOkDialog(
                  context, 'Too short, or Not a valid session! Try Again!');
              return;
            }
            Navigator.pop(context, true);
          },
        );
        Widget cancelButton = TextButton(
          style: TextButton.styleFrom(primary: Settings.majorColor),
          child: Text(Translations.of(context).trans('cancel')),
          onPressed: () {
            Navigator.pop(context, false);
          },
        );
        await showDialog(
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) => AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(12, 0, 12, 0),
            title: Text('Write Comment'),
            content: TextField(
              controller: text,
              autofocus: true,
            ),
            actions: [okButton, cancelButton],
          ),
        );
      },
      splashColor: Colors.white,
      child: ListTile(
        // dense: true,
        // contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
        title: Row(
          children: [Text('Write Comment')],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
      ),
    );
  }

  _navigate(Widget page) {
    if (!Platform.isIOS) {
      Navigator.of(context).push(PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        pageBuilder: (_, __, ___) => page,
      ));
    } else {
      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => page));
    }
  }

  TextSpan buildLinkComponent(String text, String linkToOpen) => TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.blueAccent,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            openUrl(linkToOpen);
          },
      );

  Future<void> openUrl(String url) async {
    final ehPattern =
        RegExp(r'^(https?://)?e(-|x)hentai.org/g/(?<id>\d+)/(?<hash>\w+)/?$');
    if (ehPattern.stringMatch(url) == url) {
      var match = ehPattern.allMatches(url);
      var id = match.first.namedGroup('id').trim();
      _showArticleInfo(int.parse(id));
    } else if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _showArticleInfo(int id) async {
    final height = MediaQuery.of(context).size.height;

    final search = await HentaiManager.idSearch(id.toString());
    if (search.item1.length != 1) return;

    final qr = search.item1[0];

    HentaiManager.getImageProvider(qr).then((value) async {
      var thumbnail = await value.getThumbnailUrl();
      var headers = await value.getHeader(0);
      ProviderManager.insert(qr.id(), value);

      var isBookmarked =
          await (await Bookmark.getInstance()).isBookmark(qr.id());

      var cache;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 400 / height,
            minChildSize: 400 / height,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, controller) {
              if (cache == null) {
                cache = Provider<ArticleInfo>.value(
                  child: ArticleInfoPage(
                    key: ObjectKey('asdfasdf'),
                  ),
                  value: ArticleInfo.fromArticleInfo(
                    queryResult: qr,
                    thumbnail: thumbnail,
                    headers: headers,
                    heroKey: 'zxcvzxcvzxcv',
                    isBookmarked: isBookmarked,
                    controller: controller,
                  ),
                );
              }
              return cache;
            },
          );
        },
      );
    });
  }

  List<InlineSpan> linkify(String text) {
    final List<InlineSpan> list = <InlineSpan>[];
    final RegExpMatch match =
        RegExp(r'(https?://.*?)([\<"\n\r ]|$)').firstMatch(text);
    if (match == null) {
      list.add(TextSpan(text: text));
      return list;
    }

    if (match.start > 0) {
      list.add(TextSpan(text: text.substring(0, match.start)));
    }

    final String linkText = match.group(1);
    if (linkText.contains(RegExp(urlPattern, caseSensitive: false))) {
      list.add(buildLinkComponent(linkText, linkText));
    } else if (linkText.contains(RegExp(emailPattern, caseSensitive: false))) {
      list.add(buildLinkComponent(linkText, 'mailto:$linkText'));
    } else if (linkText.contains(RegExp(phonePattern, caseSensitive: false))) {
      list.add(buildLinkComponent(linkText, 'tel:$linkText'));
    } else {
      throw 'Unexpected match: $linkText';
    }

    list.addAll(linkify(text.substring(match.start + linkText.length)));

    return list;
  }

  Text buildTextWithLinks(String textToLink) =>
      Text.rich(TextSpan(children: linkify(textToLink)));

  Widget previewArea() {
    if (ProviderManager.isExists(widget.queryResult.id())) {
      return FutureBuilder(
        future:
            ProviderManager.get(widget.queryResult.id()).getSmallImagesUrl(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Container(child: CircularProgressIndicator());
          return GridView.count(
            controller: null,
            physics: ScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: (snapshot.data as List<String>)
                .map((e) => CachedNetworkImage(
                      imageUrl: e,
                    ))
                .toList(),
          );
        },
      );
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            // alignment: Alignment.center,
            child: Align(
              // alignment: Alignment.center,
              child: Text(
                '??? Unknown Error!',
                textAlign: TextAlign.center,
              ),
            ),
            width: 100,
            height: 100,
          )
        ]);
  }
}

// Create tag-chip
// group, name
class _Chip extends StatelessWidget {
  final String name;
  final String group;

  const _Chip({this.name, this.group});

  String normalize(String tag) {
    if (tag == "groups") return "group";
    if (tag == 'artists') return 'artist';
    return tag;
  }

  @override
  Widget build(BuildContext context) {
    var tagDisplayed = name;
    var color = Colors.grey;

    if (Settings.translateTags)
      tagDisplayed =
          TagTranslate.ofAny(tagDisplayed).split(':').last.split('|').first;

    if (group == 'female')
      color = Colors.pink;
    else if (group == 'male')
      color = Colors.blue;
    else if (group == 'prefix')
      color = Colors.orange;
    else if (group == 'id') color = Colors.orange;

    Widget avatar = Text(group[0].toUpperCase());

    if (group == 'female')
      avatar = Icon(MdiIcons.genderFemale, size: 18.0);
    else if (group == 'male')
      avatar = Icon(MdiIcons.genderMale, size: 18.0);
    else if (group == 'language')
      avatar = Icon(Icons.language, size: 18.0);
    else if (group == 'artists')
      avatar = Icon(MdiIcons.account, size: 18.0);
    else if (group == 'groups')
      avatar = Icon(MdiIcons.accountGroup, size: 15.0);

    var fc = Transform.scale(
      scale: 0.95,
      child: GestureDetector(
        child: RawChip(
          labelPadding: EdgeInsets.all(0.0),
          avatar: CircleAvatar(
            backgroundColor: Colors.grey.shade600,
            child: avatar,
          ),
          label: Text(
            ' ' + tagDisplayed,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          elevation: 6.0,
          // shadowColor: Colors.grey[60],
          padding: EdgeInsets.all(6.0),
        ),
        onLongPress: () async {
          if (!Settings.excludeTags
              .contains('${normalize(group)}:${name.replaceAll(' ', '_')}')) {
            var yn = await showYesNoDialog(context, '이 태그를 제외태그에 추가할까요?');
            if (yn != null && yn) {
              Settings.excludeTags
                  .add('${normalize(group)}:${name.replaceAll(' ', '_')}');
              await Settings.setExcludeTags(Settings.excludeTags.join(' '));
              await showOkDialog(context, '제외태그에 성공적으로 추가했습니다!');
            }
          } else {
            await showOkDialog(context, '이미 제외태그에 추가된 항목입니다!');
          }
        },
        onTap: () async {
          if ((group == 'groups' ||
                  group == 'artists' ||
                  group == 'uploader' ||
                  group == 'series' ||
                  group == 'character') &&
              name.toLowerCase() != 'n/a') {
            if (!Platform.isIOS) {
              Navigator.of(context).push(PageRouteBuilder(
                // opaque: false,
                transitionDuration: Duration(milliseconds: 500),
                // transitionsBuilder: (BuildContext context,
                //     Animation<double> animation,
                //     Animation<double> secondaryAnimation,
                //     Widget wi) {
                //   // return wi;
                //   return FadeTransition(opacity: animation, child: wi);
                // },
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  var begin = Offset(0.0, 1.0);
                  var end = Offset.zero;
                  var curve = Curves.ease;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                pageBuilder: (_, __, ___) => ArtistInfoPage(
                  isGroup: group == 'groups',
                  isUploader: group == 'uploader',
                  isCharacter: group == 'character',
                  isSeries: group == 'series',
                  artist: name,
                ),
              ));
            } else {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => ArtistInfoPage(
                  isGroup: group == 'groups',
                  isUploader: group == 'uploader',
                  isCharacter: group == 'character',
                  isSeries: group == 'series',
                  artist: name,
                ),
              ));
            }
          }
        },
      ),
    );
    return fc;
  }
}
