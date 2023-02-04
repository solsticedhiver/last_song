import 'package:flutter/cupertino.dart';

import 'nova.dart';
import 'somafm.dart';
import 'bbcone.dart';

class ChannelManager extends ChangeNotifier {
  final channels = <Channel>[];
  int _currentChannel = -1;

  Channel get currentChannel => channels[_currentChannel];

  void changeChannel(int index) {
    _currentChannel = index;
    notifyListeners();
  }

  void addChannel(Channel channel) {
    channels.add(channel);
    if (channels.length == 1) {
      _currentChannel = 0;
    }
  }

  void initialize() {
    for (var s in Nova.getSubchannels.keys) {
      addChannel(Nova(s));
    }
    for (var s in SomaFm.getSubchannels.keys) {
      addChannel(SomaFm(s));
    }
    for (var s in RadioOne.getSubchannels.keys) {
      addChannel(RadioOne(s));
    }
  }

  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = await currentChannel.fetchCurrentTrack(manual);
    notifyListeners();
    return ret;
  }
}

class SubChannel {
  late String codename;
  late String title;
  late String imageUrl;
  late String bigImageUrl;
  SubChannel(
      {this.codename = 'subchannel',
      this.title = 'Subchannel',
      this.imageUrl = '',
      this.bigImageUrl = ''});
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
}

class Channel extends ChangeNotifier {
  late String radio;
  late Show show;
  late SubChannel subchannel;
  late Track currentTrack;
  //bool isFavorite = false;
  List<Track> recentTracks = <Track>[];

  Map<String, dynamic> get subchannels => throw UnimplementedError();

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
