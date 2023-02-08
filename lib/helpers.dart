import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nova.dart';
import 'somafm.dart';
import 'bbcone.dart';

class ChannelManager extends ChangeNotifier {
  final List<Channel> channels = [];
  int _currentChannel = -1;
  List<Channel> _favorites = [];
  late Timer? _timer;
  bool isFetchingCurrentTrack = false;

  Channel get currentChannel => channels[_currentChannel];

  List<Channel> get favorites {
    if (_favorites.isEmpty) {
      _favorites = channels.where((element) => element.isFavorite).toList();
    }
    return _favorites;
  }

  void changeChannel(Channel channel) {
    _currentChannel = channels.indexOf(channel);
    notifyListeners();
  }

  void addChannel(Channel channel) {
    channels.add(channel);
    if (channels.length == 1) {
      _currentChannel = 0;
    }
  }

  Future<void> initialize() async {
    for (var s in Nova.subchannels) {
      addChannel(Nova(s['code'], s['name'], s['image'], s['id']));
    }
    final subchannels = await SomaFm.loadSubChannels();
    for (var s in subchannels) {
      addChannel(SomaFm(s['id'], s['title'], s['image'], s['xlimage'],
          s['description'], s['dj']));
    }
    for (var s in RadioOne.subchannels) {
      addChannel(RadioOne(s['code'], s['name']));
    }
    await loadFavorites();
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'favorites', favorites.map((e) => e.subchannel.codename).toList());
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final fs = prefs.getStringList('favorites');

    if (fs != null) {
      for (var f in fs) {
        bool found = false;
        int indx = 0;
        while (indx < channels.length && !found) {
          if (channels[indx].subchannel.codename == f) {
            channels[indx].isFavorite = true;
            _favorites.add(channels[indx]);
            found = true;
          } else {
            indx++;
          }
        }
      }
    }
    if (favorites.isNotEmpty) {
      changeChannel(favorites.first);
      fetchCurrentTrack();
    }
  }

  Future<int> fetchCurrentTrack(
      {bool cancel = false, bool manual = false}) async {
    debugPrint(
        '${DateTime.now().toIso8601String().substring(11, 19)}: in fetchCurrentTrack(cancel: $cancel, manual: $manual)');
    if (cancel) {
      // reschedule a new timer if requested and cancel the previous one
      if (_timer != null) {
        _timer?.cancel();
        launchTimer();
      }
    }
    isFetchingCurrentTrack = true;
    notifyListeners();
    int ret = await currentChannel.fetchCurrentTrack(manual);
    isFetchingCurrentTrack = false;
    notifyListeners();
    return ret;
  }

  void launchTimer() {
    // schedule a check of current track for an update, every 30s
    _timer = Timer.periodic(
        const Duration(seconds: 30), (timer) => fetchCurrentTrack());
  }
}

class SubChannel {
  late String codename;
  late String title;
  late String imageUrl;
  late String bigImageUrl;
  late String id;
  SubChannel(
      {this.codename = 'subchannel',
      this.title = 'Subchannel',
      this.imageUrl = '',
      this.bigImageUrl = '',
      this.id = '-1'});

  @override
  String toString() {
    return 'Subchannel(code: $codename, title: $title, imageUrl: $imageUrl, bigImageUrl: $bigImageUrl, id: $id)';
  }
}

class Show {
  late String author;
  late String name;
  late String description;
  late String airingTime;
  late String imageUrl;
  DateTime? start;
  DateTime? end;
  Show(
      {this.author = 'Author',
      this.name = 'Show',
      this.description = '',
      this.airingTime = '00:00 - 00:00',
      this.imageUrl = ''});

  @override
  String toString() {
    return 'Show(author: $author, name: $name, description: $description, airingTime: $airingTime, imageUrl: $imageUrl)';
  }
}

class Channel extends ChangeNotifier {
  late String radio;
  late Show show;
  late SubChannel subchannel;
  late Track currentTrack;
  bool isFavorite = false;
  List<Track> recentTracks = <Track>[];

  Channel({
    this.radio = 'Radio',
    //this.isFavorite = false,
  }) {
    currentTrack = Track();
    show = Show();
    subchannel = SubChannel();
  }

  Future<int> fetchCurrentTrack([bool manual = false]) async {
    return 0;
  }

  Future<List<Track>> getRecentTracks() async {
    return <Track>[];
  }
}

class Track {
  int id;
  String artist;
  String title;
  String album;
  String imageUrl;
  String duration;
  String diffusionDate;

  Track({
    this.id = -1,
    this.artist = 'Artist',
    this.title = 'Title',
    this.album = 'Album',
    this.imageUrl = '',
    this.duration = '00:00',
    this.diffusionDate = "2000-01-01T00:00:00",
  });

  @override
  String toString() {
    return 'Track(diffusionDate:$diffusionDate, artist:$artist, title:$title, album:$album)';
  }

  void updateFrom(Track track) {
    id = track.id;
    artist = track.artist;
    title = track.title;
    album = track.album;
    imageUrl = track.imageUrl;
    duration = track.duration;
    diffusionDate = track.diffusionDate;
  }
}

class AppConfig {
  static const String name = 'Last Song';
  static const String version = '0.0.2';
  static const String url = 'https://github.com/solsticedhiver/last_song';
  static String userAgent = '${name.replaceAll(' ', '')}/$version +$url';
}
