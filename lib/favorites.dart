import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

import 'helpers.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

const String defaultImage = 'assets/img/black-record-vinyl-640x640.png';

class Favorites extends ChangeNotifier {
  final List<Channel> _favorites = <Channel>[];

  Favorites({favorites}) {
    if (favorites != null) {
      _favorites.addAll(favorites);
    }
  }

  Favorites.fromChannelList(List<Channel> channels) {
    _favorites.clear();
    for (var c in channels) {
      if (c.isFavorite) {
        _favorites.add(c);
      }
    }
  }

  @override
  String toString() {
    return 'Favorites(${_favorites.toString()})';
  }

  Channel operator [](int index) {
    return _favorites[index];
  }

  List<Channel> toList() {
    return _favorites;
  }

  void set(Favorites favorites) {
    _favorites.clear();
    for (var f in favorites.toList()) {
      _favorites.add(f);
      f.isFavorite = true;
    }
    notifyListeners();
  }

  void add(Channel c) {
    _favorites.add(c);
    c.isFavorite = true;
    notifyListeners();
  }

  void remove(Channel c) {
    _favorites.remove(c);
    c.isFavorite = false;
    notifyListeners();
  }

  Channel removeAt(int index) {
    Channel f = _favorites.removeAt(index);
    f.isFavorite = false;
    notifyListeners();
    return f;
  }

  void insert(int index, Channel c) {
    _favorites.insert(index, c);
    c.isFavorite = true;
    notifyListeners();
  }

  void addAll(List<Channel> channels) {
    _favorites.addAll(channels);
    for (var c in channels) {
      c.isFavorite = true;
    }
    notifyListeners();
  }

  void clear() {
    for (var f in _favorites) {
      f.isFavorite = false;
    }
    _favorites.clear();
    notifyListeners();
  }

  int indexOf(Channel f) {
    return _favorites.indexOf(f);
  }

  int get length {
    return _favorites.length;
  }

  bool get isEmpty {
    return _favorites.isEmpty;
  }

  bool get isNotEmpty {
    return _favorites.isNotEmpty;
  }

  Iterable<T> map<T>(T Function(Channel) toElement) {
    return _favorites.map((e) => toElement(e));
  }

  Channel get first {
    return _favorites[0];
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'favorites', _favorites.map((e) => e.subchannel.codename).toList());
  }

  bool contains(Channel c) {
    return _favorites.contains(c);
  }

  static Future<Favorites> loadFavorites(List<Channel> channels) async {
    final prefs = await SharedPreferences.getInstance();
    final fs = prefs.getStringList('favorites');
    List<Channel> favorites = <Channel>[];

    if (fs != null) {
      for (var f in fs) {
        bool found = false;
        int indx = 0;
        while (indx < channels.length && !found) {
          if (channels[indx].subchannel.codename == f) {
            channels[indx].isFavorite = true;
            favorites.add(channels[indx]);
            found = true;
          } else {
            indx++;
          }
        }
      }
    }
    return Favorites(favorites: favorites);
  }
}

class FavoritesRoute extends StatelessWidget {
  const FavoritesRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        title: const Text('Favorites'),
      ),
      body: Consumer<Favorites>(
        builder: (context, favorites, child) {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (favorites.isEmpty) {
                return const Center(child: Text('Nothing to show here'));
              }
              if (constraints.maxWidth > 700) {
                return const FavoritesGrid();
              } else {
                return const FavoritesList();
              }
            },
          );
        },
      ),
    );
  }
}

class FavoritesGrid extends StatefulWidget {
  const FavoritesGrid({super.key});

  @override
  State<FavoritesGrid> createState() => _FavoritesGridState();
}

class _FavoritesGridState extends State<FavoritesGrid> {
  @override
  void initState() {
    super.initState();
  }

  void _onPressed(Channel f) {
    final favorites = Provider.of<Favorites>(context, listen: false);

    int index = favorites.indexOf(f);
    favorites.remove(f);
    favorites.saveFavorites();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          backgroundColor: Colors.black87,
          content: const Text('The favorite has been deleted'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: "Undelete",
              onPressed: () {
                favorites.insert(index, f);
                favorites.saveFavorites();
              })));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Favorites>(builder: (context, favorites, child) {
      return Center(
          child: SizedBox(
              width:
                  1200, // 400px image * 3, could be a little bigger but why care ?
              child: ReorderableGridView.count(
                crossAxisCount: 3,
                children: favorites.map((f) {
                  return InkWell(
                    key: ObjectKey(f),
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                              child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                  // for a grid of 3 columns this gives an image of 313x313. Use 350px for memcache
                                  child: f.subchannel.bigImageUrl
                                          .startsWith('assets')
                                      ? Image.asset(f.subchannel.bigImageUrl,
                                          cacheHeight: 350,
                                          cacheWidth: 350,
                                          fit: BoxFit.fitHeight)
                                      : CachedNetworkImage(
                                          imageUrl: f.subchannel.bigImageUrl,
                                          fit: BoxFit.fitHeight,
                                          memCacheHeight: 350,
                                          memCacheWidth: 350,
                                          httpHeaders: {
                                            'User-Agent': AppConfig.userAgent,
                                          },
                                          errorWidget: (context, url, error) =>
                                              const SizedBox(
                                            height: 350,
                                            width: 350,
                                          ),
                                        ))),
                          ListTile(
                            title: Center(child: Text(f.subchannel.title)),
                            subtitle: Center(child: Text(f.radio)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _onPressed(f);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      ChannelManager cm =
                          Provider.of<ChannelManager>(context, listen: false);
                      cm.changeChannel(f);
                      cm.fetchCurrentTrack(cancel: true);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
                onReorder: (oldIndex, newIndex) {
                  Channel val = favorites.removeAt(oldIndex);
                  favorites.insert(newIndex, val);
                  favorites.saveFavorites();
                },
              )));
    });
  }
}

class FavoritesList extends StatefulWidget {
  const FavoritesList({super.key});

  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList> {
  @override
  void initState() {
    super.initState();
  }

  void _onDismissed(int index) {
    final favorites = Provider.of<Favorites>(context, listen: false);
    Channel oldFavorite = favorites[index];
    favorites.removeAt(index);
    favorites.saveFavorites();

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          backgroundColor: Colors.black87,
          content: const Text('The favorite has been deleted'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: "Undelete",
              onPressed: () {
                favorites.insert(index, oldFavorite);
                favorites.saveFavorites();
              })));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Favorites>(builder: (context, favorites, child) {
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
          return Dismissible(
              key: ObjectKey(f),
              background: Container(color: Colors.deepOrange),
              onDismissed: (direction) {
                _onDismissed(index);
              },
              child: ListTile(
                  key: ObjectKey(f),
                  leading: f.subchannel.imageUrl.startsWith('assets')
                      ? Image.asset(
                          f.subchannel.imageUrl,
                          cacheHeight: 64,
                          cacheWidth: 64,
                        )
                      : (f.subchannel.imageUrl.isEmpty
                          ? Image.asset(
                              defaultImage,
                              cacheHeight: 64,
                              cacheWidth: 64,
                            )
                          : Image(
                              image: ResizeImage(
                                  CachedNetworkImageProvider(headers: {
                                    'User-Agent': AppConfig.userAgent,
                                  }, f.subchannel.imageUrl),
                                  height: 64,
                                  width: 64))),
                  title: Text(f.subchannel.title),
                  subtitle: Text(f.radio),
                  onTap: () {
                    ChannelManager cm =
                        Provider.of<ChannelManager>(context, listen: false);
                    cm.changeChannel(favorites[index]);
                    cm.fetchCurrentTrack(cancel: true);
                    Navigator.pop(context);
                  }));
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          Channel val = favorites.removeAt(oldIndex);
          favorites.insert(newIndex, val);
          favorites.saveFavorites();
        },
      );
    });
  }
}
