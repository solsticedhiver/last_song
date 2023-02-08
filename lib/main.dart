import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import 'helpers.dart';

const String defaultImage = 'assets/img/black-record-vinyl-640x640.png';
const double bottomSheetSizeLargeScreen = 75;
const double bottomSheetSizeSmallScreen = 55;

GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // check we can reach some let's encrypt certificate based website
    final http.Response _ =
        await http.get(Uri.parse('https://valid-isrgrootx1.letsencrypt.org/'));
  } on HandshakeException {
    // load Let's Encrypt new certificate if this has failed
    ByteData data =
        await PlatformAssetBundle().load('assets/ca/lets-encrypt-r3.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asUint8List());
  } on SocketException {
    // TODO: we need to recheck that later on
    debugPrint('debug: Failed to test for valid-isrgrootx1.letsencrypt.org');
  }

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
      title: AppConfig.name,
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
  bool isFetchingCurrentTrack = false;

  Future<void> _fetchCurrentTrack(
      {bool cancel = false, bool manual = false}) async {
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
    setState(() {
      isFetchingCurrentTrack = true;
    });
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    int ret = await cm.fetchCurrentTrack(manual);
    setState(() {
      isFetchingCurrentTrack = false;
    });

    if (manual && ret < 1) {
      String msg = 'No update available';
      // https://stackoverflow.com/a/68847551/283067
      BuildContext? skcc = scaffoldKey.currentContext;
      ScaffoldState? skcs = scaffoldKey.currentState;
      if (skcs != null && skcc != null) {
        ScaffoldMessengerState sms = ScaffoldMessenger.of(skcc);
        sms.clearSnackBars();
        sms.showSnackBar(SnackBar(
          backgroundColor: Colors.black87,
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cm = Provider.of<ChannelManager>(context, listen: false);
    final List<List<Widget>> channelsByType = <List<Widget>>[];

    if (channelsByType.isEmpty) {
      // initialize _channelsByType
      final Map<String, dynamic> networks = {};

      for (var c in cm.channels) {
        String type = c.runtimeType.toString();
        if (networks.keys.contains(type)) {
          networks[type].add(MyRadioExpansionPanelListTile(channel: c));
        } else {
          networks[type] = [MyRadioExpansionPanelListTile(channel: c)];
        }
      }
      for (var k in networks.keys) {
        channelsByType.add(networks[k]);
      }
    }

    Scaffold scaffold = Scaffold(
      key: scaffoldKey,
      drawer:
          MyDrawer(child: MyRadioExpansionPanelList(children: channelsByType)),
      appBar: AppBar(
        title: Text((MediaQuery.of(context).size.width < 700)
            ? widget.title
                .replaceFirst(' played ', ' ')
                .replaceFirst(' on ', ' - ')
            : widget.title),
        actions: _buildActionButtons(context),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return RefreshIndicator(
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                        child: Center(
                      child: _buildCurrentTrackWidget(constraints),
                    )))),
            onRefresh: () async {
              return _fetchCurrentTrack(cancel: true, manual: true);
            });
      }),
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

  List<Widget> _buildActionButtons(BuildContext context) {
    final actions = <IconButton>[
      IconButton(
        icon: const Icon(Icons.copy_all),
        tooltip: 'Copy all',
        onPressed: () {
          final cm = Provider.of<ChannelManager>(context, listen: false);
          StringBuffer txt = StringBuffer(
              '${cm.currentChannel.currentTrack.artist.toTitleCase()} - ${cm.currentChannel.currentTrack.title.toTitleCase()}');
          if (cm.currentChannel.currentTrack.album.isNotEmpty &&
              cm.currentChannel.currentTrack.album != 'Album') {
            txt.write(' - ${cm.currentChannel.currentTrack.album}');
          }
          _copyToClipboard(txt.toString());
        },
      ),
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
    ];
    if (MediaQuery.of(context).size.width > 500) {
      // return the list of IconButtons if screen is large enough
      return actions;
    } else {
      // build a PopupMenuButton from the IconsButtons
      return <Widget>[
        PopupMenuButton<IconButton>(itemBuilder: (context) {
          return actions.map((e) {
            return PopupMenuItem<IconButton>(
              // Navigator inside PopupMenuItem does not work: https://stackoverflow.com/a/69589313/283067
              onTap: () async {
                await Future.delayed(Duration.zero, () {
                  e.onPressed!();
                });
              },
              child: Text(e.tooltip!),
            );
          }).toList();
        })
      ];
    }
  }

/*
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
            //tileColor: index % 2 == 0 ? Colors.black87 : null,
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
*/

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

  StatelessWidget _buildBottomSheetWidget(double bottomSheetSize) {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      String image = cm.currentChannel.show.imageUrl;
      if (image == '') {
        image = cm.currentChannel.subchannel.imageUrl;
      }

      return BottomSheet(
        enableDrag: false,
        builder: (context) {
          return InkWell(
              onTap: () async {
                return _buildCurrentShowDialog(context, cm);
              },
              child: Container(
                  height: bottomSheetSize,
                  color: Colors.black87,
                  child: Row(
                    children: [
                      image.startsWith('assets')
                          ? Image.asset(image)
                          : Image(
                              image: CachedNetworkImageProvider(image),
                              height: bottomSheetSize,
                              width: bottomSheetSize,
                            ),
                      const SizedBox(
                        width: 15,
                      ),
                      _buildCurrentShowText(),
                    ],
                  )));
        },
        onClosing: () {},
      );
    });
  }

  Future<void> _buildCurrentShowDialog(
      BuildContext context, ChannelManager cm) {
    final imageUrl = cm.currentChannel.show.imageUrl;
    return showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: imageUrl.startsWith('assets')
                ? Image.asset(imageUrl, height: 400, width: 400)
                : CachedNetworkImage(
                    imageUrl: imageUrl, height: 400, width: 400),
            title: Text(cm.currentChannel.show.name),
            content: Text(
              cm.currentChannel.show.description,
              overflow: TextOverflow.clip,
              softWrap: true,
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('Dismiss'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget _buildCurrentTrackWidget(BoxConstraints constraints) {
    double bSS;
    if (constraints.maxHeight > 700) {
      bSS = bottomSheetSizeLargeScreen;
    } else {
      bSS = bottomSheetSizeSmallScreen;
    }
    Widget ctw;
    if (constraints.maxWidth > 1000) {
      ctw = _buildCurrentTrackWidgetLargeScreen(bSS, constraints);
    } else {
      ctw = _buildCurrentTrackWidgetSmallScreen(bSS);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ctw,
        Visibility(
            visible: isFetchingCurrentTrack,
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
  }

  StatelessWidget _buildCurrentTrackWidgetSmallScreen(double bottomSheetSize) {
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
            //fit: FlexFit.tight,
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

  StatelessWidget _buildCurrentTrackWidgetLargeScreen(
      double bottomSheetSize, BoxConstraints constraints) {
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
          SizedBox(width: gap),
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

  StatelessWidget _buildCurrentShowText() {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      return RichText(
          softWrap: false,
          overflow: TextOverflow.clip,
          text: TextSpan(
              text:
                  '', // empty just to define the default style of the whole RichText
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                  text: cm.currentChannel.show.name != 'Show'
                      ? cm.currentChannel.show.name
                      : cm.currentChannel.subchannel.title,
                  style: const TextStyle(
                      fontWeight: FontWeight
                          .w700, // bold is too heavy and cause blur/smudge
                      color: Colors.white),
                ),
                TextSpan(
                  text: cm.currentChannel.show.author.isNotEmpty &&
                          cm.currentChannel.show.author != 'Author'
                      ? ' - ${cm.currentChannel.show.author}'
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300, // same idea as above
                  ),
                ),
                TextSpan(
                  text: cm.currentChannel.show.airingTime.isNotEmpty &&
                          cm.currentChannel.show.airingTime != '00:00 - 00:00'
                      ? '\n${cm.currentChannel.show.airingTime}'
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ]));
    });
  }

  StatelessWidget _buildLastSongListRoute() {
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
                    child: _buildDataTableSong(recentTracks, cm))
                : const Text('Nothing to show here'),
          ),
        );
      },
    );
  }

  Widget _buildDataTableSong(List<Track> recentTracks, ChannelManager cm) {
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
          DataCell(Text(track.artist.toTitleCase(),
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(track.title.toTitleCase())),
        ];
        // add album only is screen is large enough
        if (!isSmallScreen) {
          cells.add(DataCell(Text(track.album != 'Album' ? track.album : '---',
              style: const TextStyle(fontStyle: FontStyle.italic))));
        }
        rows.add(DataRow(cells: cells));
      }
      return Column(
        children: [
          Center(
              child: Container(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                      '${cm.currentChannel.radio} / ${cm.currentChannel.show.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)))),
          DataTable(
              headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                return Theme.of(context).secondaryHeaderColor;
              }),
              columns: columns,
              rows: rows),
        ],
      );
    });
  }

/*
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
*/

  Widget _buildFavoriteList() {
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    final favorites = cm.favorites;

    return ReorderableListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        if (favorites.isEmpty) {
          return const SizedBox(
            height: 0,
            width: 0,
          );
        }
        final f = favorites[index];
        return ListTile(
            key: Key('$index'),
            leading: f.subchannel.imageUrl.startsWith('assets')
                ? Image.asset(f.subchannel.imageUrl)
                : Image(
                    image: CachedNetworkImageProvider(f.subchannel.imageUrl)),
            title: Text(f.subchannel.title),
            subtitle: Text(f.radio),
            onTap: () {
              cm.changeChannel(favorites[index]);
              _fetchCurrentTrack(cancel: true);
              Navigator.pop(context);
            });
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          Channel val = favorites.removeAt(oldIndex);
          favorites.insert(newIndex, val);
        });
        cm.saveFavorites();
      },
    );
  }

  Widget _buildFavoriteRoute() {
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    final favorites = cm.favorites;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (favorites.isEmpty) {
            return const Center(child: Text('Nothing to show here'));
          }
          if (constraints.maxWidth > 700) {
            return const FavoriteGrid();
          } else {
            return _buildFavoriteList();
          }
        },
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard'),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void initState() {
    super.initState();
    timer = _launchTimer();
    _fetchCurrentTrack();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Timer _launchTimer() {
    // schedule a check of current track for an update, every 30s
    return Timer.periodic(
        const Duration(seconds: 30), (timer) => _fetchCurrentTrack());
  }
}

extension ChangeCaseString on String {
  // https://gist.github.com/filiph/d4e0c0a9efb0f869f984317372f5bee8?permalink_comment_id=3486118#gistcomment-3486118
  String toTitleCase() {
    final stringBuffer = StringBuffer();

    var capitalizeNext = true;
    for (final letter in toLowerCase().codeUnits) {
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
}

class MyDrawer extends StatelessWidget {
  final Widget child;

  const MyDrawer({super.key, required this.child});

  @override
  Drawer build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              children: [
                Image.asset(
                  'assets/img/black-record-vinyl-excl-point-64x64.png',
                  height: 64,
                  width: 64,
                ),
                const SizedBox(
                  width: 15,
                  height: 15,
                ),
                const Text('${AppConfig.name} ${AppConfig.version}',
                    style: TextStyle(color: Colors.white, fontSize: 25)),
              ],
            ),
          ),
          const ListTile(
              title: Text('Radio channels',
                  style: TextStyle(fontStyle: FontStyle.italic))),
          Expanded(
            flex: 1,
            child: child,
          ),
        ],
      ),
    );
  }
}

class MyRadioExpansionPanelList extends StatefulWidget {
  const MyRadioExpansionPanelList({
    super.key,
    required this.children,
  });

  final List<List<Widget>> children;

  @override
  State<MyRadioExpansionPanelList> createState() =>
      _MyRadioExpansionPanelListState();
}

class _MyRadioExpansionPanelListState extends State<MyRadioExpansionPanelList> {
  final List<bool> _drawerExpansionPanelListState = <bool>[];

  @override
  Widget build(BuildContext context) {
    List<ExpansionPanel> children = [];

    for (var subList in widget.children) {
      final listView = ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: subList.length,
        itemBuilder: (context, index) {
          return subList[index];
        },
      );

      children.add(ExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return ListTile(
              title: Text(
                  (subList[0] as MyRadioExpansionPanelListTile).channel.radio));
        },
        body: listView,
        isExpanded:
            _drawerExpansionPanelListState[widget.children.indexOf(subList)],
      ));
    } // for

    return SingleChildScrollView(
        child: ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {
          _drawerExpansionPanelListState[panelIndex] = !isExpanded;
        });
      },
      children: children,
    ));
  }

  @override
  void initState() {
    super.initState();
    _drawerExpansionPanelListState
        .addAll(List<bool>.generate(widget.children.length, (index) => false));
  }
}

class MyRadioExpansionPanelListTile extends StatefulWidget {
  const MyRadioExpansionPanelListTile({super.key, required this.channel});

  final Channel channel;

  @override
  State<MyRadioExpansionPanelListTile> createState() =>
      _MyRadioExpansionPanelListTileState();
}

class _MyRadioExpansionPanelListTileState
    extends State<MyRadioExpansionPanelListTile> {
  late bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(widget.channel),
      title: Text(widget.channel.subchannel.title),
      subtitle: Text(widget.channel.radio),
      leading: SizedBox(
          width: 48,
          height: 48,
          child: widget.channel.subchannel.imageUrl.startsWith('assets')
              ? Image.asset(widget.channel.subchannel.imageUrl)
              : Image(
                  image: CachedNetworkImageProvider(
                      widget.channel.subchannel.imageUrl))),
      trailing: IconButton(
        icon: Icon(Icons.favorite,
            color:
                isFavorite ? Colors.red : ListTileTheme.of(context).iconColor),
        onPressed: () {
          setState(() {
            isFavorite = !isFavorite;
            widget.channel.isFavorite = isFavorite;
          });
        },
      ),
      onTap: () {
        final cm = Provider.of<ChannelManager>(context, listen: false);
        cm.changeChannel(widget.channel);
        cm.fetchCurrentTrack();
        Navigator.pop(context);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    isFavorite = widget.channel.isFavorite;
  }
}

class FavoriteGrid extends StatefulWidget {
  const FavoriteGrid({super.key});

  @override
  State<FavoriteGrid> createState() => _FavoriteGridState();
}

class _FavoriteGridState extends State<FavoriteGrid> {
  late final List<Channel> favorites;

  @override
  void initState() {
    super.initState();
    ChannelManager cm = Provider.of<ChannelManager>(context, listen: false);
    favorites = cm.favorites;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
            width:
                1200, // 400px image * 3, could be a little bigger but why care ?
            child: ReorderableGridView.builder(
              // does not work with ReorderableGridView.count(). Why ?
              itemCount: favorites.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 0,
                crossAxisSpacing: 0,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final f = favorites[index];
                return InkWell(
                  key: ValueKey(f),
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                            child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                child: f.subchannel.bigImageUrl
                                        .startsWith('assets')
                                    ? Image.asset(f.subchannel.bigImageUrl,
                                        fit: BoxFit.fitHeight)
                                    : CachedNetworkImage(
                                        imageUrl: f.subchannel.bigImageUrl,
                                        fit: BoxFit.fitHeight))),
                        ListTile(
                          title: Center(child: Text(f.subchannel.title)),
                          subtitle: Center(child: Text(f.radio)),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    ChannelManager cm =
                        Provider.of<ChannelManager>(context, listen: false);
                    cm.changeChannel(favorites[index]);
                    cm.fetchCurrentTrack();
                    Navigator.pop(context);
                  },
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  Channel val = favorites.removeAt(oldIndex);
                  favorites.insert(newIndex, val);
                });
                ChannelManager cm =
                    Provider.of<ChannelManager>(context, listen: false);
                cm.saveFavorites();
              },
            )));
  }
}
