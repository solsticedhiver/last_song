import 'helpers.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
