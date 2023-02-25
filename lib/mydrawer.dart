import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'favorites.dart';
import 'helpers.dart';

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

    int pos = 0;
    for (var subList in widget.children) {
      final listView = ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _drawerExpansionPanelListState[pos] ? subList.length : 0,
        prototypeItem: subList.first,
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
      pos++;
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
      key: ObjectKey(widget.channel),
      title: Text(widget.channel.subchannel.title),
      subtitle: Text(widget.channel.radio),
      leading: SizedBox(
          width: 48,
          height: 48,
          child: widget.channel.subchannel.imageUrl.startsWith('assets')
              // use 64x64px for memache image because the image is used in bottomsheet too
              ? Image.asset(
                  widget.channel.subchannel.imageUrl,
                  cacheHeight: 64,
                  cacheWidth: 64,
                )
              : CachedNetworkImage(
                  imageUrl: widget.channel.subchannel.imageUrl,
                  httpHeaders: {
                    'User-Agent': AppConfig.userAgent,
                  },
                  errorWidget: (context, url, error) =>
                      const SizedBox(height: 64, width: 64),
                  memCacheHeight: 64,
                  memCacheWidth: 64,
                )),
      trailing: IconButton(
        icon: Icon(Icons.favorite,
            color:
                isFavorite ? Colors.red : ListTileTheme.of(context).iconColor),
        onPressed: () {
          Favorites favorites = Provider.of<Favorites>(context, listen: false);
          setState(() {
            isFavorite = !isFavorite;
          });
          if (isFavorite) {
            favorites.add(widget.channel);
          } else {
            favorites.remove(widget.channel);
          }
          favorites.saveFavorites();
        },
      ),
      onTap: () {
        final cm = Provider.of<ChannelManager>(context, listen: false);
        cm.changeChannel(widget.channel);
        cm.fetchCurrentTrack(cancel: true);
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
