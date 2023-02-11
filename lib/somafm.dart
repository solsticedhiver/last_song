import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'helpers.dart';
import 'bandcamp.dart';
import 'discogs.dart';

class SomaFm extends Channel {
  static Future<List<dynamic>> loadSubChannels() async {
    // list of channels available at https://api.somafm.com/channels.json (or somafm.com)
    // TODO: use the online version instead of the hardcoded downloaded one ?
    final cj = await rootBundle.loadString('assets/somafm_channels.json');
    return json.decode(cj)['channels'];
  }

  SomaFm(String subchannel, String name, String imageUrl, String bigImageUrl,
      String description, String dj)
      : super(radio: 'Soma FM') {
    this.subchannel.title = name;
    this.subchannel.imageUrl = imageUrl;
    this.subchannel.bigImageUrl = bigImageUrl;
    this.subchannel.codename = subchannel;
    show.author = dj;
    show.airingTime = '';
    show.imageUrl = this.subchannel.bigImageUrl;
    show.name = this.subchannel.title;
    show.description = description;
  }

  @override
  String toString() {
    return 'SomaFm(subchannel: ${subchannel.toString()}';
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;
    Track track;

    recentTracks = await getRecentTracks();
    if (recentTracks.isNotEmpty) {
      track = recentTracks.elementAt(0);
    } else {
      track = Track();
    }

    if (track.title != currentTrack.title &&
        track.artist != currentTrack.artist) {
      currentTrack.updateFrom(track);
      // search for an image cover
      ResponseBandcamp resp = await searchBandcamp(
          '${track.title} ${track.album} ${track.artist}', 't');
      if (resp.imageUrl.isNotEmpty) {
        currentTrack.imageUrl = resp.imageUrl;
        if (resp.duration.isNotEmpty) {
          currentTrack.duration = resp.duration;
        }
      } else {
        resp = await searchBandcamp('${track.title} ${track.artist}', 't');
        if (resp.imageUrl.isNotEmpty) {
          currentTrack.imageUrl = resp.imageUrl;
        } else {
          resp = await searchBandcamp('${track.album} ${track.artist}', 'a');
          if (resp.imageUrl.isNotEmpty) {
            currentTrack.imageUrl = resp.imageUrl;
          } else {
            // try with discogs
            ResponseDiscogs resp = await searchDiscogs({
              'artist': track.artist,
              'q': track.album,
            });
            if (resp.imageUrl.isNotEmpty) {
              currentTrack.imageUrl = resp.imageUrl;
            }
          }
        }
      }
      notifyListeners();
      ret += 1;
    }
    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    // get timezone and current date of San Francisco
    tz.initializeTimeZones();
    tz.Location sanFrancisco = tz.getLocation('America/Los_Angeles');
    tz.TZDateTime now = tz.TZDateTime.now(sanFrancisco);
    String timeZone = convertSecondsToHours(
        sanFrancisco.timeZone(now.millisecondsSinceEpoch).offset ~/ 1000);
    String currentDate = now.toString().substring(0, 10);

    List<Track> ret = <Track>[];
    String page = 'https://somafm.com/recent/${subchannel.codename}.html';

    final http.Response resp;
    try {
      resp = await http.get(Uri.parse(page), headers: {
        'User-Agent': AppConfig.userAgent,
      });
    } catch (e) {
      debugPrint('debug: $e');
      return ret;
    }

    if (resp.statusCode != 200) {
      return ret;
    }
    final document = parser.parse(resp.body);
    final rows = document.querySelectorAll('#playinc table tr');
    rows.removeAt(0); // remove header of table
    for (var element in rows) {
      final tds = element.querySelectorAll('td');
      if (tds.length != 5) continue;
      final time = tds[0].text.replaceFirst(' (Now) ', '').trim();
      String artist = 'Artist';
      if (tds[1].firstChild != null && tds[1].firstChild?.text != null) {
        artist = (tds[1].firstChild?.text)!;
      }
      String album = 'Album';
      if (tds[3].firstChild != null && tds[3].firstChild?.text != null) {
        album = (tds[3].firstChild?.text)!;
      }
      // convert SF local time to our local time
      // add current SF date in front of parsed hour
      // this gives error at midnight
      DateTime diffusionDate = DateTime.parse('${currentDate}T$time $timeZone');
      Track track = Track(
          diffusionDate:
              diffusionDate.toLocal().toString().replaceFirst(' ', 'T'),
          artist: artist,
          title: tds[2].text,
          album: album);
      //debugPrint('$track');
      ret.add(track);
    }
    return ret;
  }
}

String convertSecondsToHours(int offset) {
  int minutes = offset ~/ 60;
  int hours = minutes ~/ 60;
  String sh = hours.abs().toString().padLeft(2, '0');
  String sign = '';
  if (hours / hours.abs() < 0) sign = '-';
  String sm = (minutes % 60).toString().padLeft(2, '0');
  return '$sign$sh$sm';
}
