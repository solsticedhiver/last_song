import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:args/args.dart';

import 'track.dart';
import 'somafm.dart';
import 'nova.dart';

const String defaultImage = 'assets/black-record-vinyl-640x640.png';
const double bottomSheetSizeLargeScreen = 75;
const double bottomSheetSizeSmallScreen = 55;

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main(List<String> args) {
  var parser = ArgParser();
  parser.addFlag('help',
      abbr: 'h', help: "display this help", negatable: false);
  parser.addOption('somafm', help: "Soma FM channel to follow");
  String? channel;
  try {
    var results = parser.parse(args);
    if (results['help']) {
      print('Usage:\n${parser.usage}');
      exit(1);
    }
    channel = results['somafm'];
    if (channel != null && !SomaFmTrack.channels.containsKey(channel)) {
      print(
          'Error: unknown channel code. Here is the list of known channel code:');
      SomaFmTrack.channels.forEach((key, value) {
        print('${value["name"]}: $key');
      });
      exit(1);
    }
  } on FormatException {
    print('Error: unknown option');
    exit(1);
  }

  runApp(ChangeNotifierProvider(
    create: (context) {
      Track track;
      if (channel != null) {
        track = SomaFmTrack();
        track.radio = 'Soma FM';
        track.currentShow.imageUrl = '';
        String? scn = SomaFmTrack.channels[channel]?['name'];
        if (scn != null) {
          track.currentShow.title = scn;
        }
        String? sci = SomaFmTrack.channels[channel]?['image'];
        if (sci != null) {
          track.currentShow.imageUrl = 'https://somafm.com/img/$sci';
        }
        track.currentShow.channel = channel;
        track.currentShow.author = 'Rusty Hodge';
        track.currentShow.airingTime = '';
      } else {
        track = NovaTrack();
        track.radio = 'Radio Nova';
        track.currentShow.imageUrl = defaultShowImageUrl;
      }
      return track;
    },
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
      home: Consumer<Track>(builder: (context, ct, child) {
        return MyHomePage(title: "Last played song on ${ct.radio}");
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
  void _fetchCurrentTrack([bool manual = false]) async {
    int ret = await Provider.of<Track>(context, listen: false)
        .fetchCurrentTrack(manual);

    if (manual && ret < 1) {
      String msg = 'No update available';
      // https://stackoverflow.com/a/68847551/283067
      BuildContext? skcc = scaffoldKey.currentContext;
      ScaffoldState? skcs = scaffoldKey.currentState;
      if (skcs != null && skcc != null) {
        ScaffoldMessenger.of(skcc).hideCurrentSnackBar();
        ScaffoldMessenger.of(skcc).showSnackBar(SnackBar(
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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _buildCurrentTrackWidget(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchCurrentTrack(true);
        },
        tooltip: 'sync',
        child: const Icon(Icons.sync),
      ),
      bottomSheet: _buildBottomSheet(),
    );
    return scaffold;
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
                Consumer<Track>(
                  builder: (context, ct, child) {
                    return Image(
                      image:
                          CachedNetworkImageProvider(ct.currentShow.imageUrl),
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
      if (constraints.maxWidth > 1000) {
        return _buildCurrentTrackWidgetLargeScreen();
      } else {
        return _buildCurrentTrackWidgetSmallScreen();
      }
    });
  }

  Widget _buildCurrentTrackWidgetSmallScreen() {
    return Container(
      padding: const EdgeInsets.only(bottom: bottomSheetSizeSmallScreen),
      child: Column(
        children: <Widget>[
          Consumer<Track>(builder: (context, ct, child) {
            double imgSize = 400;
            if (ct.imageUrl.isEmpty) {
              return Image.asset(defaultImage, height: imgSize, width: imgSize);
            } else {
              return CachedNetworkImage(
                  imageUrl: ct.imageUrl, height: imgSize, width: imgSize);
            }
          }),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: _buildCurrentTrackText(isSmallScreen: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTrackWidgetLargeScreen() {
    return Container(
      padding: const EdgeInsets.only(bottom: bottomSheetSizeLargeScreen),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Consumer<Track>(builder: (context, ct, child) {
            double imgSize = 400;
            if (ct.imageUrl.isEmpty) {
              return Image.asset(defaultImage, height: imgSize, width: imgSize);
            } else {
              return CachedNetworkImage(
                  imageUrl: ct.imageUrl, height: imgSize, width: imgSize);
            }
          }),
          const SizedBox(width: 15),
          _buildCurrentTrackText(),
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
          const SizedBox(
            height: 15,
            width: 15,
          ),
          Consumer<Track>(builder: (context, ct, child) {
            String dd = ct.diffusionDate.split('T')[1].substring(0, 8);
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
                      style: const TextStyle(fontSize: 20))
                ]));
          }),
          Consumer<Track>(builder: (context, ct, child) {
            String artist;
            artist =
                ct.artist.split('/').map((e) => toTitleCase(e)).join(' /\n');
            return Flexible(
                child: Text(artist,
                    overflow: TextOverflow.fade,
                    softWrap: true,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 35 : 55,
                        fontWeight: FontWeight.bold)));
          }),
          Consumer<Track>(builder: (context, ct, child) {
            return Text(toTitleCase(ct.title),
                overflow: TextOverflow.fade,
                style: TextStyle(
                    fontSize: isSmallScreen ? 25 : 35,
                    fontWeight: FontWeight.normal));
          }),
          Consumer<Track>(builder: (context, ct, child) {
            if (ct.album.isNotEmpty && ct.album != 'Album') {
              return Text(ct.album,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                      fontSize: isSmallScreen ? 25 : 35,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic));
            } else {
              return Container();
            }
          }),
          Consumer<Track>(builder: (context, ct, child) {
            return Text(
                '${ct.duration.replaceFirst(RegExp(r'^0'), '').replaceFirst(':', 'min ')}s',
                style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 20,
                    color: Colors.deepOrange));
          }),
        ]);
  }

  Widget _buildCurrentShowText() {
    return Consumer<Track>(builder: (context, ct, child) {
      return RichText(
          text: TextSpan(
              text:
                  '', // empty just to define the default style of the whole RichText
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
            TextSpan(
              text: ct.currentShow.title,
              style: const TextStyle(
                  fontWeight: FontWeight
                      .w700, // bold is too heavy and cause blur/smudge
                  color: Colors.white),
            ),
            TextSpan(
              text: ct.currentShow.author.isNotEmpty
                  ? ' - ${ct.currentShow.author}'
                  : '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300, // same idea as above
              ),
            ),
            TextSpan(
              text: ct.currentShow.airingTime.isNotEmpty
                  ? '\n${ct.currentShow.airingTime}'
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
    Timer.periodic(
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
