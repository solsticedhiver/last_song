import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'helpers.dart';
import 'somafm.dart';

const String defaultImage = 'assets/black-record-vinyl-640x640.png';
const double bottomSheetSizeLargeScreen = 75;
const double bottomSheetSizeSmallScreen = 55;

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main(List<String> args) {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ChannelManager>(
        create: (context) {
          ChannelManager cm = ChannelManager();
          cm.initialize();
          return cm;
        },
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        //useMaterial3: true,
        primarySwatch: Colors.deepOrange,
      ),
      home: Consumer<ChannelManager>(builder: (context, channel, child) {
        return MyHomePage(
            title: "Last played song on ${channel.currentChannel.radio}");
      }),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer? timer;

  void _fetchCurrentTrack({bool cancel = false, bool manual = false}) async {
    //print(
    //    '${DateTime.now().toString().substring(11, 19)}: _fetchCurrentTrack(manual:$manual)');
    // reschedule a new timer if a manual update has been made (after canceling the previous one)
    if (cancel) {
      if (timer != null) {
        timer?.cancel();
      }
      setState(() {
        timer = _launchTimer();
      });
    }
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    int ret = await cm.fetchCurrentTrack(manual);

    if (manual && ret < 1) {
      String msg = 'No update available';
      // https://stackoverflow.com/a/68847551/283067
      BuildContext? skcc = scaffoldKey.currentContext;
      ScaffoldState? skcs = scaffoldKey.currentState;
      if (skcs != null && skcc != null) {
        ScaffoldMessengerState sms = ScaffoldMessenger.of(skcc);
        sms.hideCurrentSnackBar();
        sms.showSnackBar(SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Scaffold scaffold = Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: _buildRadioListView(),
      ),
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _buildCurrentTrackWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchCurrentTrack(cancel: true, manual: true);
        },
        tooltip: 'sync',
        child: const Icon(Icons.sync),
      ),
      bottomSheet: _buildBottomSheet(),
    );
    return scaffold;
  }

  Widget _buildRadioListView() {
    final channelManager = Provider.of<ChannelManager>(context, listen: false);
    return ListView.separated(
      itemCount: channelManager.channels.length,
      itemBuilder: (context, index) {
        String text = channelManager.channels[index].radio;
        String subchannel = channelManager.channels[index].subchannel;
        if (subchannel.isNotEmpty) {
          text = '$text / ${SomaFm.subchannels[subchannel]?["name"]}';
        }
        return ListTile(
            title: Text(text),
            onTap: () {
              channelManager.changeChannel(index);
              _fetchCurrentTrack(cancel: true);
              Navigator.pop(context);
            });
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }

  Widget _buildBottomSheet() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxHeight > 700) {
        return _buildBottomSheetWidget(bottomSheetSizeLargeScreen);
      } else {
        return _buildBottomSheetWidget(bottomSheetSizeSmallScreen);
      }
    });
  }

  Widget _buildBottomSheetWidget(double bottomSheetSize) {
    return BottomSheet(
      enableDrag: false,
      builder: (context) {
        return Container(
            height: bottomSheetSize,
            color: Colors.grey[800],
            child: Row(
              children: [
                Consumer<ChannelManager>(
                  builder: (context, cm, child) {
                    return Image(
                      image: CachedNetworkImageProvider(
                          cm.currentChannel.imageUrl),
                      height: bottomSheetSize,
                      width: bottomSheetSize,
                    );
                  },
                ),
                const SizedBox(
                  width: 15,
                ),
                _buildCurrentShowText(),
              ],
            ));
      },
      onClosing: () {},
    );
  }

  Widget _buildCurrentTrackWidget() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double bSS;
      if (constraints.maxHeight > 700) {
        bSS = bottomSheetSizeLargeScreen;
      } else {
        bSS = bottomSheetSizeSmallScreen;
      }
      if (constraints.maxWidth > 1000) {
        return _buildCurrentTrackWidgetLargeScreen(bSS);
      } else {
        return _buildCurrentTrackWidgetSmallScreen(bSS);
      }
    });
  }

  Widget _buildCurrentTrackWidgetSmallScreen(double bottomSheetSize) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomSheetSize),
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
                  return Image.asset(defaultImage,
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
            child: Container(
              padding:
                  const EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
              child: _buildCurrentTrackText(isSmallScreen: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTrackWidgetLargeScreen(double bottomSheetSize) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomSheetSize),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Consumer<ChannelManager>(builder: (context, cm, child) {
            double imgSize = 400;
            if (cm.currentChannel.currentTrack.imageUrl.isEmpty) {
              return Image.asset(defaultImage, height: imgSize, width: imgSize);
            } else {
              return CachedNetworkImage(
                  imageUrl: cm.currentChannel.currentTrack.imageUrl,
                  height: imgSize,
                  width: imgSize);
            }
          }),
          const SizedBox(width: 15),
          Flexible(
            flex: 0,
            child: _buildCurrentTrackText(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTrackText({bool isSmallScreen = false}) {
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
                        color: Colors.deepOrange),
                    children: <TextSpan>[
                  TextSpan(
                      text: dd.substring(5, 8),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.normal))
                ]));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            String artist;
            artist = cm.currentChannel.currentTrack.artist
                .split('/')
                .map((e) => toTitleCase(e))
                .join(' /\n');
            return Flexible(
                child: Text(artist,
                    overflow: TextOverflow.fade,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 30 : 55,
                        fontWeight: FontWeight.bold)));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            return Text(toTitleCase(cm.currentChannel.currentTrack.title),
                overflow: TextOverflow.fade,
                style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 35,
                    fontWeight: FontWeight.normal));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            if (cm.currentChannel.currentTrack.album.isNotEmpty &&
                cm.currentChannel.currentTrack.album != 'Album') {
              return Text(cm.currentChannel.currentTrack.album,
                  overflow: TextOverflow.fade,
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
                    color: Colors.deepOrange));
          }),
        ]);
  }

  Widget _buildCurrentShowText() {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      return RichText(
          text: TextSpan(
              text:
                  '', // empty just to define the default style of the whole RichText
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
            TextSpan(
              text: cm.currentChannel.title,
              style: const TextStyle(
                  fontWeight: FontWeight
                      .w700, // bold is too heavy and cause blur/smudge
                  color: Colors.white),
            ),
            TextSpan(
              text: cm.currentChannel.author.isNotEmpty
                  ? ' - ${cm.currentChannel.author}'
                  : '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300, // same idea as above
              ),
            ),
            TextSpan(
              text: cm.currentChannel.airingTime.isNotEmpty
                  ? '\n${cm.currentChannel.airingTime}'
                  : '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
          ]));
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchCurrentTrack();
    setState(() {
      timer = _launchTimer();
    });
  }

  Timer _launchTimer() {
    // schedule a check of current track for an update, every 30s
    return Timer.periodic(
        const Duration(seconds: 30), (timer) => _fetchCurrentTrack());
  }
}

// https://gist.github.com/filiph/d4e0c0a9efb0f869f984317372f5bee8?permalink_comment_id=3486118#gistcomment-3486118
String toTitleCase(String name) {
  final stringBuffer = StringBuffer();

  var capitalizeNext = true;
  for (final letter in name.toLowerCase().codeUnits) {
    // UTF-16: A-Z => 65-90, a-z => 97-122.
    if (capitalizeNext && letter >= 97 && letter <= 122) {
      stringBuffer.writeCharCode(letter - 32);
      capitalizeNext = false;
    } else {
      // UTF-16: 32 == space, 46 == period
      if (letter == 32 || letter == 46) capitalizeNext = true;
      stringBuffer.writeCharCode(letter);
    }
  }

  return stringBuffer.toString();
}
