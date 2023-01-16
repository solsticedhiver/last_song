import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'helpers.dart';

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
      //debugShowCheckedModeBanner: false,
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
    if (cancel) {
      // reschedule a new timer if requested and cancel the previous one
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepOrange),
              child: Container(
                child: const Text('Last Song',
                    style: TextStyle(color: Colors.white, fontSize: 25)),
              ),
            ),
            Container(
                padding: const EdgeInsets.all(10),
                child: const Text('Radio channels')),
            Expanded(
              child: _buildRadioListView(),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => _buildLastSongListRoute(),
                ),
              );
            },
          ),
        ],
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
        Channel channel = channelManager.channels[index];
        String subchannel = channel.subchannel;
        String? name = channel.subchannels[subchannel]?['name'];
        //if (subchannel.isNotEmpty) {
        //  text = '$text / $name';
        //}
        return ListTile(
            //tileColor: index % 2 == 0 ? Colors.grey[350] : null,
            //dense: true,
            subtitle: name != null ? Text(channel.radio) : null,
            title: name != null ? Text(name) : Text(channel.radio),
            leading: SizedBox(
                width: 48,
                height: 48,
                child:
                    Image(image: CachedNetworkImageProvider(channel.imageUrl))),
            trailing: IconButton(
              icon: Icon(Icons.favorite,
                  color: channel.isFavorite
                      ? Colors.red
                      : ListTileTheme.of(context).iconColor),
              onPressed: () {
                setState(() {
                  channel.isFavorite = !channel.isFavorite;
                });
              },
            ),
            onTap: () {
              channelManager.changeChannel(index);
              _fetchCurrentTrack(cancel: true);
              Navigator.pop(context);
            });
      },
      separatorBuilder: (context, index) => const Divider(
        height: 5, // do we need to do this ?
      ),
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
                softWrap: true,
                style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 35,
                    fontWeight: FontWeight.normal));
          }),
          Consumer<ChannelManager>(builder: (context, cm, child) {
            if (cm.currentChannel.currentTrack.album.isNotEmpty &&
                cm.currentChannel.currentTrack.album != 'Album') {
              return Text(cm.currentChannel.currentTrack.album,
                  overflow: TextOverflow.fade,
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
              text: cm.currentChannel.show,
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

  Widget _buildLastSongListRoute() {
    return Consumer<ChannelManager>(
      builder: (context, cm, child) {
        final recentTracks = cm.currentChannel.recentTracks;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Recently played songs'),
          ),
          body: Container(
            alignment: Alignment.topCenter,
            child: recentTracks.isNotEmpty
                //? _buildListItemSong(recentTracks)
                ? SingleChildScrollView(
                    child: _buildDataTableSong(recentTracks))
                : const Text('Nothing to show here'),
          ),
        );
      },
    );
  }

  Widget _buildDataTableSong(List<Track> recentTracks) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      bool isSmallScreen;
      if (constraints.maxWidth > 1000) {
        isSmallScreen = false;
      } else {
        isSmallScreen = true;
      }
      int sum = 0;
      final rt =
          recentTracks.map((e) => e.album == 'Album' ? 0 : 1).forEach((e) {
        sum += e;
      });
      // remove last column (Album) if none is defined
      if (sum == 0) {
        isSmallScreen = true;
      }
      List<DataColumn> columns = <DataColumn>[
        const DataColumn(
          label: Expanded(
            child: Text(
              'Time',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Artist',
              style: TextStyle(
                  fontStyle: FontStyle.normal, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Title',
              style: TextStyle(
                  fontStyle: FontStyle.normal, fontWeight: FontWeight.normal),
            ),
          ),
        ),
      ];
      if (!isSmallScreen) {
        columns.add(
          const DataColumn(
            label: Expanded(
              child: Text(
                'Album',
                style: TextStyle(
                    fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
              ),
            ),
          ),
        );
      }
      final rows = <DataRow>[];
      for (var track in recentTracks) {
        String dd = track.diffusionDate.split('T')[1].substring(0, 8);
        List<DataCell> cells = [
          DataCell(Text(dd,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.deepOrange))),
          DataCell(Text(toTitleCase(track.artist),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(toTitleCase(track.title))),
        ];
        // add album only is screen is large enough
        if (!isSmallScreen) {
          cells.add(DataCell(Text(
              track.album != 'Album' ? '${track.album}' : '---',
              style: const TextStyle(fontStyle: FontStyle.italic))));
        }
        rows.add(DataRow(cells: cells));
      }
      return DataTable(
          headingRowColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            return Theme.of(context).colorScheme.primary.withOpacity(0.08);
          }),
          columns: columns,
          rows: rows);
    });
  }

  Widget _buildListItemSong(List<Track> recentTracks) {
    // TODO: wrap it in a Card, or not?
    return ListView.separated(
        itemCount: recentTracks.length,
        //prototypeItem: _buildListItemSong(recentTracks.first),
        separatorBuilder: (context, index) {
          return const Divider();
        },
        itemBuilder: (context, index) {
          Track track = recentTracks[index];
          String dd = track.diffusionDate.split('T')[1].substring(0, 8);
          return ListTile(
              leading: RichText(
                  text: TextSpan(
                      text: dd.substring(0, 5),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.deepOrange),
                      children: <TextSpan>[
                    TextSpan(
                        text: dd.substring(5, 8),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.normal))
                  ])),
              isThreeLine: true,
              title: Text(toTitleCase(track.artist),
                  overflow: TextOverflow.fade,
                  softWrap: true,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: RichText(
                text: TextSpan(
                  text: toTitleCase(track.title),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                        text: track.album != 'Album'
                            ? '\n${track.album}'
                            : '\n---',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ));
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
