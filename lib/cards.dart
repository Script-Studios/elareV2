import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app_concept/dataClasses.dart';

var cardAspectRatio = 12.0 / 16.0;
var widgetAspectRatio = cardAspectRatio * 1.2;
//var images = dataimages;

class CardScrollWidget extends StatefulWidget {
  final padding = 20.0;
  final verticalInset = 20.0;
  final List<ImageShow> images;
  final Function removeImage;
  final _CardScrollWidgetState card = new _CardScrollWidgetState();
  CardScrollWidget(
    this.removeImage,
    this.images,
  );

  @override
  _CardScrollWidgetState createState() => card;
}

class _CardScrollWidgetState extends State<CardScrollWidget>
    with SingleTickerProviderStateMixin {
  AnimationController cnt;
  Animation<Offset> swipe;
  Animation<double> rotate;

  void swipeLeft() async {
    swipe = Tween<Offset>(
      begin: Offset(0.0, 0.0),
      end: Offset(-1.0, 0.0),
    ).animate(cnt);
    rotate = Tween<double>(
      begin: 0.0,
      end: -0.2,
    ).animate(cnt);
    setState(() {});
    await cnt.forward().catchError((e) {
      print(e);
    });
    widget.removeImage(0);
    setState(() {});
  }

  void swipeRight() async {
    swipe = Tween<Offset>(
      begin: Offset(0.0, 0.0),
      end: Offset(1.0, 0.0),
    ).animate(cnt);
    rotate = Tween<double>(
      begin: 0.0,
      end: 0.2,
    ).animate(cnt);
    setState(() {});
    await cnt.forward().catchError((e) {
      print(e);
    });
    widget.removeImage(1);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    cnt = new AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 400,
      ),
    );
    cnt.addStatusListener((st) {
      if (st == AnimationStatus.completed) cnt.reset();
    });
    swipe = Tween<Offset>(
      begin: Offset(0.0, 0.0),
      end: Offset(-1.0, 0.0),
    ).animate(cnt);
    rotate = Tween<double>(
      begin: 0.0,
      end: -0.4,
    ).animate(cnt);
  }

  @override
  Widget build(BuildContext context) {
    return new AspectRatio(
      aspectRatio: widgetAspectRatio,
      child: LayoutBuilder(builder: (context, contraints) {
        var height = contraints.maxHeight;
        var width = contraints.maxWidth;

        var safeHeight = height - 2 * widget.padding;
        var safeWidth = width - 2 * widget.padding;

        var heightOfPrimaryCard = safeHeight;
        var widthOfPrimaryCard = heightOfPrimaryCard * cardAspectRatio;

        var primaryCardTop = safeWidth - widthOfPrimaryCard;
        var horizontalInset = primaryCardTop / 2;

        List<Widget> cardList = new List();
        int frontIndex = widget.images.length;
        for (var i = 0; i < widget.images.length; i++) {
          var delta = i - frontIndex + 1;
          bool isOnBack = delta > 0;
          var top = widget.padding +
              max(
                  primaryCardTop -
                      horizontalInset * -delta * (isOnBack ? 15 : 1),
                  0.0);
          var bottom = widget.padding + primaryCardTop;
          var start = widget.padding + horizontalInset * max(-delta, 0.0);
          var end = widget.padding + horizontalInset * max(-delta, 0.0);
          var cardItem = Positioned.directional(
            start: start,
            end: end,
            top: top,
            bottom: bottom,
            textDirection: TextDirection.ltr,
            child: SlideTransition(
              position: i == frontIndex - 1
                  ? swipe
                  : new Tween<Offset>(
                      begin: Offset(0.0, 0.0),
                      end: Offset(0.0, 0.0),
                    ).animate(cnt),
              child: RotationTransition(
                turns: i == frontIndex - 1
                    ? rotate
                    : new Tween<double>(
                        begin: 0.0,
                        end: 0.0,
                      ).animate(cnt),
                child: Dismissible(
                  direction: DismissDirection.horizontal,
                  key: new Key(
                    widget.images[i].themeId +
                        widget.images[i].imgIndex.toString(),
                  ),
                  onDismissed: (dir) {
                    widget.removeImage(
                        dir == DismissDirection.startToEnd ? 1 : 0);
                    setState(() {});
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12,
                                offset: Offset(3.0, 6.0),
                                blurRadius: 10.0)
                          ]),
                      child: AspectRatio(
                        aspectRatio: cardAspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            CachedNetworkImage(
                              imageUrl: widget.images[i].image.link,
                              placeholder: (context, s) {
                                return Container(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  color: Colors.white,
                                );
                              },
                              fit: BoxFit.cover,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          cardList.add(cardItem);
        }
        return Stack(
          children: cardList,
        );
      }),
    );
  }
}
