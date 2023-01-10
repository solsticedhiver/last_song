import 'package:flutter/cupertino.dart';

class CurrentShow {
  late String imageUrl;
  late String title;
  late String channel;
  late String author;
  late String airingTime;

  CurrentShow({
    this.imageUrl = '',
    this.title = 'Unknown',
    this.channel = 'Unknown',
    this.author = 'Unknown',
    this.airingTime = 'Unknown',
  });
}

class Track extends ChangeNotifier {
  int id;
  String artist;
  String title;
  String album;
  String imageUrl;
  String duration;
  String diffusionDate;
  String radio;
  late CurrentShow currentShow;

  Track({
    this.id = -1,
    this.artist = 'Unknown',
    this.title = 'Unknown',
    this.album = 'Unknown',
    this.imageUrl = '',
    this.duration = '00:00',
    this.diffusionDate = "2000-01-01T00:00:00",
    this.radio = '',
  }) {
    currentShow = CurrentShow();
  }

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
    radio = track.radio;
  }

  Future<int> fetchCurrentTrack([bool manual = false]) async {
    return 0;
  }
}
