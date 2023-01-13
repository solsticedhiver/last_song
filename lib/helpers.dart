import 'package:flutter/cupertino.dart';

import 'nova.dart';
import 'somafm.dart';

class ChannelManager extends ChangeNotifier {
  final channels = <Channel>[];
  Channel _currentChannel = Channel();

  Channel get currentChannel => _currentChannel;

  void changeChannel(int index) {
    _currentChannel = channels[index];
    notifyListeners();
  }

  void addChannel(Channel channel) {
    channels.add(channel);
    if (channels.length == 1) {
      _currentChannel = channels[0];
    }
  }

  void initialize() {
    addChannel(Nova());
    for (var s in SomaFm.subchannels.keys) {
      addChannel(SomaFm(s));
    }
  }

  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = await _currentChannel.fetchCurrentTrack(manual);
    notifyListeners();
    return ret;
  }
}

class Channel extends ChangeNotifier {
  late String radio;
  late String imageUrl;
  late String title;
  late String subchannel;
  late String author;
  late String airingTime;
  late Track currentTrack;
  List<Track> recentTracks = <Track>[];

  Channel({
    this.radio = 'Radio',
    this.imageUrl = '',
    this.title = 'Show',
    this.subchannel = 'Subchannel',
    this.author = 'Author',
    this.airingTime = '00:00 - 00:00',
  }) {
    currentTrack = Track();
  }

  @override
  String toString() {
    return 'Channel(radio: $radio, title:$title, subchannel:$subchannel, author:$author, airingTime:$airingTime)';
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