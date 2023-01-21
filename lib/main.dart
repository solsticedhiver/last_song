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
  final List<int> _favorites = <int>[];
  final List<List<int>> _channelsByType = <List<int>>[];

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
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => _buildFavoriteRoute(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Track history',
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
        tooltip: 'Update current track',
        child: const Icon(Icons.sync),
      ),
      bottomSheet: _buildBottomSheet(),
    );
    return scaffold;
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              children: [
                Image.asset(
                  'assets/black-record-vinyl-excl-point-64x64.png',
                  height: 64,
                  width: 64,
                ),
                const SizedBox(
                  width: 15,
                  height: 15,
                ),
                const Text('Last Song',
                    style: TextStyle(color: Colors.white, fontSize: 25)),
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.all(10),
              child: const Text('Radio channels')),
          Expanded(
            //child: _buildRadioListView(),
            child: _buildRadioListWithExpansionTile(),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioListWithExpansionTile() {
    final cm = Provider.of<ChannelManager>(context, listen: false);
    // initialize _channelsByType
    if (_channelsByType.isEmpty) {
      final Map<String, dynamic> networks = {};
      int index;
      for (var c in cm.channels) {
        index = cm.channels.indexOf(c);
        String type = c.runtimeType.toString();
        if (networks.keys.contains(type)) {
          networks[type].add(index);
        } else {
          networks[type] = [index];
        }
      }
      for (var c in networks.values) {
        _channelsByType.add(c);
      }
    }

    List<Widget> children = [];
    for (var t in _channelsByType) {
      final l = ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: t.length,
        prototypeItem:
            _buildRadioListItemInExpansionTile(cm.channels[t[0]], 0, cm, t),
        itemBuilder: (context, index) {
          Channel c = cm.channels[t[index]];
          return _buildRadioListItemInExpansionTile(c, index, cm, t);
        },
      );

      children.add(
          ExpansionTile(title: Text(cm.channels[t[0]].radio), children: [l]));
    }
    return ListView(
      primary: true,
      children: children,
    );
  }

  Widget _buildRadioListItemInExpansionTile(
      Channel c, int index, ChannelManager cm, List<int> t) {
    return ListTile(
      key: Key('$index'),
      title: Text(c.subchannels[c.subchannel]['name']),
      subtitle: Text(c.radio),
      leading: SizedBox(
          width: 48,
          height: 48,
          child: Image(image: CachedNetworkImageProvider(c.imageUrl))),
      trailing: IconButton(
        icon: Icon(Icons.favorite,
            color: _favorites.contains(t[index])
                ? Colors.red
                : ListTileTheme.of(context).iconColor),
        onPressed: () {
          setState(() {
            if (_favorites.contains(t[index])) {
              _favorites.remove(t[index]);
            } else {
              _favorites.add(t[index]);
            }
          });
        },
      ),
      onTap: () {
        cm.changeChannel(t[index]);
        _fetchCurrentTrack(cancel: true);
        Navigator.pop(context);
      },
    );
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
                  color: _favorites.contains(index)
                      ? Colors.red
                      : ListTileTheme.of(context).iconColor),
              onPressed: () {
                setState(() {
                  if (_favorites.contains(index)) {
                    _favorites.remove(index);
                  } else {
                    _favorites.add(index);
                  }
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
        return _buildCurrentTrackWidgetLargeScreen(bSS, constraints);
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

  Widget _buildCurrentTrackWidgetLargeScreen(
      double bottomSheetSize, BoxConstraints constraints) {
    double imgSize = 400;
    if (constraints.maxHeight > 900 && constraints.maxWidth > 1500) {
      imgSize = 700;
    }
    return Container(
      padding: EdgeInsets.only(bottom: bottomSheetSize),
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Consumer<ChannelManager>(builder: (context, cm, child) {
            if (cm.currentChannel.currentTrack.imageUrl.isEmpty) {
              return Image.asset(
                defaultImage,
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
                        color: Theme.of(context).primaryColor),
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
                    color: Theme.of(context).primaryColor));
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
            alignment: recentTracks.isNotEmpty
                ? Alignment.topCenter
                : Alignment.center,
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
      final int empties = recentTracks.where((e) => e.album == 'Album').length;
      // remove last column (Album) if none is defined
      if (empties == recentTracks.length) {
        isSmallScreen = true;
      }
      List<DataColumn> columns = <DataColumn>[
        DataColumn(
          label: Expanded(
            child: Text(
              'Time',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Artist',
              style: TextStyle(
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
        ),
        const DataColumn(
          label: Expanded(
            child: Text(
              'Title',
              style: TextStyle(
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.normal,
                  fontSize: 20),
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
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.normal,
                    fontSize: 20),
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
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor))),
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
            return Theme.of(context).secondaryHeaderColor;
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
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).primaryColor),
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

  Widget _buildFavoriteList() {
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    return ReorderableListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        if (_favorites.isEmpty) {
          return const SizedBox(
            height: 0,
            width: 0,
          );
        }
        final f = cm.channels[_favorites[index]];
        return ListTile(
            key: Key('$index'),
            leading: Image(image: CachedNetworkImageProvider(f.imageUrl)),
            title: Text(f.subchannels[f.subchannel]['name']),
            subtitle: Text(f.radio),
            onTap: () {
              final cm = Provider.of<ChannelManager>(context, listen: false);
              cm.changeChannel(_favorites[index]);
              _fetchCurrentTrack(cancel: true);
              Navigator.pop(context);
            });
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          int val = _favorites.removeAt(oldIndex);
          _favorites.insert(newIndex, val);
        });
      },
    );
  }

  Widget _buildFavoriteRoute() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > 1000) {
            return _buildFavoriteList();
            //return _buildFavoriteGrid();
          } else {
            return _buildFavoriteList();
          }
        },
      ),
    );
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
