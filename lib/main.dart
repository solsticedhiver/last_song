import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:args/args.dart';

import 'track.dart';
import 'somafm.dart';
import 'nova.dart';

const String defaultImage = 'assets/black-record-vinyl.png';

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main(List<String> args) {
  var parser = ArgParser();
  parser.addOption('radio');
  var results = parser.parse(args);
  //print(results['radio']);

  runApp(ChangeNotifierProvider(
    create: (context) {
      Track track;
      if (results['radio'] != null) {
        track = SomaFmTrack();
        track.radio = 'Soma FM';
        track.currentShow.title = results['radio'];
        track.currentShow.imageUrl = '';
        String? siu = SomaFmTrack.channels[results['radio']]?['image'];
        if (siu != null) {
          track.currentShow.imageUrl = 'https://somafm.com/img/$siu';
        }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.only(bottom: 75),
                child: Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Consumer<Track>(builder: (context, ct, child) {
                      if (ct.imageUrl.isEmpty) {
                        return Image.asset(defaultImage,
                            height: 400, width: 400);
                      } else {
                        return CachedNetworkImage(
                            imageUrl: ct.imageUrl, height: 400, width: 400);
                      }
                    }),
                    Container(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Consumer<Track>(builder: (context, ct, child) {
                              String dd = ct.diffusionDate
                                  .split('T')[1]
                                  .substring(0, 8);
                              return RichText(
                                  text: TextSpan(
                                      text: dd.substring(0, 5),
                                      style: const TextStyle(
                                          fontSize: 35,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.deepOrange),
                                      children: <TextSpan>[
                                    TextSpan(
                                        text: dd.substring(5, 8),
                                        style: const TextStyle(fontSize: 20))
                                  ]));
                            }),
                            Consumer<Track>(builder: (context, ct, child) {
                              String artist;
                              artist = ct.artist
                                  .split('/')
                                  .map((e) => toTitleCase(e))
                                  .join(' /\n');
                              return Flexible(
                                  child: Container(
                                      child: Text(artist,
                                          overflow: TextOverflow.fade,
                                          softWrap: true,
                                          style: const TextStyle(
                                              fontSize: 55,
                                              fontWeight: FontWeight.bold))));
                            }),
                            Consumer<Track>(builder: (context, ct, child) {
                              return Text(toTitleCase(ct.title),
                                  style: const TextStyle(
                                      fontSize: 35,
                                      fontWeight: FontWeight.normal));
                            }),
                            Consumer<Track>(builder: (context, ct, child) {
                              if (ct.album.isNotEmpty &&
                                  ct.album != 'Unknown') {
                                return Text(ct.album,
                                    style: const TextStyle(
                                        fontSize: 35,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.italic));
                              } else {
                                return Container();
                              }
                            }),
                            Consumer<Track>(builder: (context, ct, child) {
                              return Text(
                                  '${ct.duration.replaceFirst(RegExp(r'^0'), '').replaceFirst(':', 'm')}s',
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.deepOrange));
                            }),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchCurrentTrack(true);
        },
        tooltip: 'sync',
        child: const Icon(Icons.sync),
      ),
      bottomSheet: BottomSheet(
        enableDrag: false,
        builder: (context) {
          return Container(
              height: 75,
              color: Colors.grey[800],
              child: Row(
                children: [
                  Consumer<Track>(
                    builder: (context, ct, child) {
                      return Image(
                        image:
                            CachedNetworkImageProvider(ct.currentShow.imageUrl),
                        height: 75,
                        width: 75,
                      );
                    },
                  ),
                  Container(
                    width: 15,
                  ),
                  Consumer<Track>(builder: (context, ct, child) {
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
                  }),
                ],
              ));
        },
        onClosing: () {},
      ),
    );
    return scaffold;
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
