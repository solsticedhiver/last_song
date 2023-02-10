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
    return Container(
      padding: EdgeInsets.only(bottom: bottomSheetSize, left: 10, right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.only(
                  top: 10, right: 15, left: 15, bottom: 5),
              child: Consumer<ChannelManager>(builder: (context, cm, child) {
                double imgSize = 400;
                if (cm.currentChannel.currentTrack.imageUrl.isEmpty) {
                  return Image.asset(AppConfig.defaultImage,
                      height: imgSize, width: imgSize);
                } else {
                  return CachedNetworkImage(
                      imageUrl: cm.currentChannel.currentTrack.imageUrl,
                      height: imgSize,
                      width: imgSize);
                }
              }),
            ),
          ),
          Flexible(
            flex: 1,
            //fit: FlexFit.tight,
            child: Container(
              padding:
                  const EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
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
      padding: EdgeInsets.only(bottom: bottomSheetSize, left: left, right: 20),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Consumer<ChannelManager>(builder: (context, cm, child) {
            if (cm.currentChannel.currentTrack.imageUrl.isEmpty) {
              return Image.asset(
                AppConfig.defaultImage,
                height: imgSize,
                width: imgSize,
                fit: BoxFit.fill,
              );
            } else {
              return CachedNetworkImage(
                imageUrl: cm.currentChannel.currentTrack.imageUrl,
                height: imgSize,
                width: imgSize,
                fit: BoxFit.fill,
              );
            }
          }),
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

class CurrentTrackText extends StatelessWidget {
  final bool isSmallScreen;
  const CurrentTrackText({super.key, this.isSmallScreen = false});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment:
            isSmallScreen ? MainAxisAlignment.start : MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Consumer<ChannelManager>(builder: (context, cm, child) {
            String dd = cm.currentChannel.currentTrack.diffusionDate
                .split('T')[1]
                .substring(0, 8);
            return RichText(
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
            );
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            String artist;
            artist = cm.currentChannel.currentTrack.artist
                .split('/')
                .map((e) => e.toTitleCase())
                .join(' /\n');
            return Flexible(
                child: Text(artist,
                    overflow: TextOverflow.clip,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 30 : 55,
                        fontWeight: FontWeight.bold)));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            return Text(cm.currentChannel.currentTrack.title.toTitleCase(),
                overflow: TextOverflow.clip,
                softWrap: true,
                style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 35,
                    fontWeight: FontWeight.normal));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            if (cm.currentChannel.currentTrack.album.isNotEmpty &&
                cm.currentChannel.currentTrack.album != 'Album') {
              return Text(cm.currentChannel.currentTrack.album,
                  overflow: TextOverflow.clip,
                  softWrap: true,
                  style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 35,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic));
            } else {
              return const SizedBox(
                height: 0,
                width: 0,
              );
            }
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            return Text(
                '${cm.currentChannel.currentTrack.duration.replaceFirst(RegExp(r'^0'), '').replaceFirst(':', 'min ')}s',
                style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 20,
                    color: Theme.of(context).primaryColor));
          }),
        ]);
  }
}
