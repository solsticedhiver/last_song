import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'helpers.dart';
import 'favorites.dart';
import 'myextensions.dart';
import 'lastsong.dart';
import 'mydrawer.dart';
import 'current_track.dart';

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
      ChangeNotifierProvider<Favorites>(create: (context) {
        Favorites favorites = Favorites();
        return favorites;
      }),
      ChangeNotifierProvider<ChannelManager>(
        create: (context) {
          ChannelManager cm = ChannelManager();
          return cm;
        },
      ),
    ],
    builder: (context, child) {
      final favorites = context.watch<Favorites>();
      final cm = context.watch<ChannelManager>();
      // initialization is done here, be sure to do it only once
      if (cm.channels.isEmpty) {
        Future.delayed(Duration.zero, () async {
          await cm.initialize();
          final f = await Favorites.loadFavorites(cm.channels);
          favorites.set(f);
          if (favorites.isNotEmpty) {
            cm.changeChannel(favorites.first);
          } else {
            cm.changeChannel(cm.channels.first);
          }
          cm.fetchCurrentTrack();
          cm.launchTimer();
        });
      }
      return const MyApp();
    },
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  void showSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        backgroundColor: Colors.black87,
        content: Text('No update available'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cm = Provider.of<ChannelManager>(context, listen: true);
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
      drawer:
          MyDrawer(child: MyRadioExpansionPanelList(children: channelsByType)),
      appBar: AppBar(
        title: Text((MediaQuery.of(context).size.width < 700)
            ? title.replaceFirst(' played ', ' ').replaceFirst(' on ', ' - ')
            : title),
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
                      child: CurrentTrackWidget(constraints: constraints),
                    )))),
            onRefresh: () async {
              int ret = await cm.fetchCurrentTrack(cancel: true, manual: true);
              if (ret < 1) {
                showSnackBar(context);
              }
            });
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          int ret = await cm.fetchCurrentTrack(cancel: true, manual: true);
          if (ret < 1) {
            showSnackBar(context);
          }
        },
        tooltip: 'Update current track',
        child: const Icon(Icons.sync),
      ),
      bottomSheet: const MyBottomSheet(),
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
          _copyToClipboard(context, txt.toString());
        },
      ),
      IconButton(
        icon: const Icon(Icons.favorite),
        tooltip: 'Favorites',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FavoritesRoute(),
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
              builder: (context) => const LastSongListRoute(),
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

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard'),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class CurrentShowText extends StatelessWidget {
  const CurrentShowText({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      Channel currentChannel = cm.currentChannel;
      return RichText(
          softWrap: false,
          overflow: TextOverflow.clip,
          text: TextSpan(
              text:
                  '', // empty just to define the default style of the whole RichText
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                  text: currentChannel.show.name != 'Show'
                      ? currentChannel.show.name
                      : currentChannel.subchannel.title,
                  style: const TextStyle(
                      fontWeight: FontWeight
                          .w700, // bold is too heavy and cause blur/smudge
                      color: Colors.white),
                ),
                TextSpan(
                  text: currentChannel.show.author.isNotEmpty &&
                          currentChannel.show.author != 'Author'
                      ? ' - ${currentChannel.show.author}'
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300, // same idea as above
                  ),
                ),
                TextSpan(
                  text: currentChannel.show.airingTime.isNotEmpty &&
                          currentChannel.show.airingTime != '00:00 - 00:00'
                      ? '\n${currentChannel.show.airingTime}'
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ]));
    });
  }
}

class MyBottomSheetWidget extends StatelessWidget {
  final double bottomSheetSize;

  const MyBottomSheetWidget({super.key, required this.bottomSheetSize});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChannelManager>(builder: (context, cm, child) {
      String image = cm.currentChannel.show.imageUrl;
      if (image == '') {
        image = cm.currentChannel.subchannel.imageUrl;
      }

      return BottomSheet(
        enableDrag: false,
        builder: (context) {
          Widget wi;
          if (image.isEmpty) {
            wi = SizedBox(
              width: bottomSheetSize,
              height: bottomSheetSize,
            );
          } else if (image.startsWith('assets')) {
            wi = Image.asset(image,
                height: bottomSheetSize, width: bottomSheetSize);
          } else {
            wi = CachedNetworkImage(
              imageUrl: image,
              memCacheHeight: bottomSheetSize.toInt(),
              memCacheWidth: bottomSheetSize.toInt(),
            );
          }
          return InkWell(
              onTap: () async {
                return _buildCurrentShowDialog(context, cm);
              },
              child: Container(
                  height: bottomSheetSize,
                  color: Colors.black87,
                  child: Row(
                    children: [
                      wi,
                      const SizedBox(
                        width: 15,
                      ),
                      const CurrentShowText(),
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
                ? Image.asset(imageUrl, cacheHeight: 400, cacheWidth: 400)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    memCacheHeight: 400,
                    memCacheWidth: 400),
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
}

class MyBottomSheet extends StatelessWidget {
  const MyBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxHeight > 700) {
        return const MyBottomSheetWidget(
            bottomSheetSize: AppConfig.bottomSheetSizeLargeScreen);
      } else {
        return const MyBottomSheetWidget(
            bottomSheetSize: AppConfig.bottomSheetSizeSmallScreen);
      }
    });
  }
}
