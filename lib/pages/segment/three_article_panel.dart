// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/database/query.dart';
import 'package:violet/model/article_list_item.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/article_item/article_list_item_widget.dart';

class ThreeArticlePanel extends StatelessWidget {
  final Widget Function() tappedRoute;
  final String title;
  final String count;
  final List<QueryResult> articles;

  ThreeArticlePanel({this.tappedRoute, this.title, this.count, this.articles});

  @override
  Widget build(BuildContext context) {
    var windowWidth = MediaQuery.of(context).size.width;
    var subItemWidth = (windowWidth - 16 - 4.0 - 1.0) / 3;
    return InkWell(
      onTap: () => _onTap(context),
      child: SizedBox(
        height: 195,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 17)),
                  Text(
                    count,
                    style: TextStyle(
                      color: Settings.themeWhat
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 162,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _SubItem(subItemWidth, articles, 0),
                    _SubItem(subItemWidth, articles, 1),
                    _SubItem(subItemWidth, articles, 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onTap(context) {
    if (!Platform.isIOS) {
      Navigator.of(context).push(PageRouteBuilder(
        // opaque: false,
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
        pageBuilder: (_, __, ___) => tappedRoute(),
      ));
    } else {
      Navigator.of(context)
          .push(CupertinoPageRoute(builder: (_) => tappedRoute()));
    }
  }
}

class _SubItem extends StatelessWidget {
  final List<QueryResult> articles;
  final int index;
  final double width;

  _SubItem(this.width, this.articles, this.index);

  @override
  Widget build(BuildContext context) {
    if (articles.length <= index) {
      return Expanded(
        flex: 1,
        child: Container(),
      );
    }

    return Expanded(
      flex: 1,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Provider<ArticleListItem>.value(
          value: ArticleListItem.fromArticleListItem(
            queryResult: articles[index],
            showDetail: false,
            addBottomPadding: false,
            width: width,
            thumbnailTag: Uuid().v4(),
            disableFilter: true,
            usableTabList: articles,
          ),
          child: ArticleListItemVerySimpleWidget(),
        ),
      ),
    );
  }
}
