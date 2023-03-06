import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';
import 'myextensions.dart';

class CurrentTrackWidget extends StatelessWidget {
  final BoxConstraints constraints;

  const CurrentTrackWidget({super.key, required this.constraints});

  @override
  Widget build(BuildContext context) {
    double bSS;
    if (constraints.maxHeight > 700) {
      bSS = AppConfig.bottomSheetSizeLargeScreen;
    } else {
      bSS = AppConfig.bottomSheetSizeSmallScreen;
    }
    Widget ctw;
    if (constraints.maxWidth > 1000) {
      ctw = CurrentTrackWidgetLargeScreen(
          bottomSheetSize: bSS, constraints: constraints);
    } else {
      ctw = CurrentTrackWidgetSmallScreen(bottomSheetSize: bSS);
    }
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ctw,
          Visibility(
              visible: cm.isFetchingCurrentTrack,
              child: const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  // deepOrange is not seen beside the appBar of the same color
                  color: Colors.black87,
                  backgroundColor: Colors.white,
                  minHeight: 2,
                  value: null,
                ),
              )),
        ],
      );
    });
  }
}

class CurrentTrackWidgetSmallScreen extends StatelessWidget {
  final double bottomSheetSize;

  const CurrentTrackWidgetSmallScreen(
      {super.key, required this.bottomSheetSize});

  @override
  Widget build(BuildContext context) {
    //debugPrint('in CurrentTrackWidgetSmallScreen.build()');
    double imgSize = 400;
    if (MediaQuery.of(context).size.width < 420) {
      imgSize = MediaQuery.of(context).size.width - 20;
    }
    return Container(
      padding: EdgeInsets.only(
          bottom: bottomSheetSize, left: 10, right: 10, top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          CurrentTrackImage(imgSize: imgSize),
          Flexible(
            flex: 2,
            //fit: FlexFit.tight,
            child: Container(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 5, right: 10, left: 10),
              child: const CurrentTrackText(isSmallScreen: true),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrentTrackWidgetLargeScreen extends StatelessWidget {
  final double bottomSheetSize;
  final BoxConstraints constraints;

  const CurrentTrackWidgetLargeScreen(
      {super.key, required this.bottomSheetSize, required this.constraints});

  @override
  Widget build(BuildContext context) {
    double imgSize = 400;
    double gap = 30;
    double left = 30;
    // on very large screen
    if (constraints.maxHeight > 900 && constraints.maxWidth > 1500) {
      // increase image size
      imgSize = 700;
      gap = 45;
      left = 45;
    }
    return Container(
      padding: EdgeInsets.only(
          top: 10, bottom: bottomSheetSize, left: left, right: 20),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CurrentTrackImage(imgSize: imgSize),
          SizedBox(width: gap),
          const Flexible(
            flex: 0,
            child: CurrentTrackText(),
          ),
        ],
      ),
    );
  }
}

class CurrentTrackImage extends StatefulWidget {
  final double imgSize;
  const CurrentTrackImage({super.key, required this.imgSize});

  @override
  State<CurrentTrackImage> createState() => _CurrentTrackImageState();
}

class _CurrentTrackImageState extends State<CurrentTrackImage> {
  bool isButtonVisible = true;
  bool isFoundImageVisible = true;
  String imageUrl = '';

  @override
  void initState() {
    isButtonVisible = true;
    isFoundImageVisible = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint('in _CurrentWidgetImageState.build()');
    Widget image;
    Widget defaultImage = Image.asset(
      AppConfig.defaultImage,
      height: widget.imgSize,
      width: widget.imgSize,
      fit: BoxFit.fill,
    );
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      String newImageUrl = cm.currentChannel.currentTrack.imageUrl;
      if (newImageUrl != imageUrl) {
        //setState!
        isFoundImageVisible = true;
      }
      imageUrl = newImageUrl;
      if (imageUrl.isNotEmpty) {
        image = CachedNetworkImage(
          imageUrl: imageUrl,
          httpHeaders: {
            'User-Agent': AppConfig.userAgent,
          },
          errorWidget: (context, url, error) => SizedBox(
            height: widget.imgSize,
            width: widget.imgSize,
          ),
          height: widget.imgSize,
          width: widget.imgSize,
          fit: BoxFit.fill,
        );
      } else {
        image = SizedBox(
          width: widget.imgSize,
          height: widget.imgSize,
        );
      }
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          defaultImage,
          Visibility(visible: isFoundImageVisible, child: image),
          Visibility(
              visible: isButtonVisible,
              child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.deepOrange,
                  ),
                  child: IconButton(
                    color: Colors.white70,
                    icon: isFoundImageVisible
                        ? const Icon(Icons.hide_image)
                        : const Icon(Icons.image),
                    onPressed: () {
                      setState(
                        () {
                          //isButtonVisible = false;
                          isFoundImageVisible = !isFoundImageVisible;
                        },
                      );
                    },
                  )))
        ],
      );
    });
  }
}

class CurrentTrackText extends StatelessWidget {
  final bool isSmallScreen;
  const CurrentTrackText({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      String dd = cm.currentChannel.currentTrack.diffusionDate
          .split('T')[1]
          .substring(0, 8);
      String artist;
      artist = cm.currentChannel.currentTrack.artist
          .split('/')
          .map((e) => e.toTitleCase())
          .join(' /\n');
      return Column(
          mainAxisAlignment: isSmallScreen
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            RichText(
              text: TextSpan(
                  text: dd.substring(0, 5),
                  style: TextStyle(
                      fontSize: isSmallScreen ? 25 : 40,
                      fontWeight:
                          isSmallScreen ? FontWeight.bold : FontWeight.normal,
                      color: Theme.of(context).primaryColor),
                  children: <TextSpan>[
                    TextSpan(
                        text: dd.substring(5, 8),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.normal))
                  ]),
            ),
            Flexible(
                child: Text(artist,
                    overflow: TextOverflow.clip,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 30 : 55,
                        fontWeight: FontWeight.bold))),
            Text(cm.currentChannel.currentTrack.title.toTitleCase(),
                overflow: TextOverflow.clip,
                softWrap: true,
                style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 35,
                    fontWeight: FontWeight.normal)),
            (cm.currentChannel.currentTrack.album.isNotEmpty &&
                    cm.currentChannel.currentTrack.album != 'Album')
                ? Text(cm.currentChannel.currentTrack.album,
                    overflow: TextOverflow.clip,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 35,
                        fontWeight: FontWeight.normal,
                        fontStyle: FontStyle.italic))
                : const SizedBox(
                    height: 0,
                    width: 0,
                  ),
            Text(
                '${cm.currentChannel.currentTrack.duration.replaceFirst(RegExp(r'^0'), '').replaceFirst(':', 'min ')}s',
                style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 20,
                    color: Theme.of(context).primaryColor)),
          ]);
    });
  }
}
