import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;

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
    WebScraper webScraper = WebScraper();
    try {
      webScraper.loadFromString(resp.body);
    } on WebScraperException catch (e) {
      debugPrint('debug: ${e.errorMessage()}');
    }
    List<Map<String, dynamic>> elements =
        webScraper.getElement('#playinc table tr td', ['colspan']);
    //print(elements);
    List<String> columns = [];
    for (var e in elements) {
      //print(e);
      if (e['attributes']['colspan'] != null) {
        columns.clear();
        continue;
      }
      columns.add(e['title'].replaceFirst(' (Now) ', '').trim());
      if (columns.length == 5) {
        if (!columns[0].startsWith('Played At')) {
          // convert SF local time to our local time
          // add current SF date in front of parsed hour
          DateTime diffusionDate =
              DateTime.parse('${currentDate}T${columns[0]} $timeZone');
          Track track = Track(
            diffusionDate:
                diffusionDate.toLocal().toString().replaceFirst(' ', 'T'),
            artist: columns[1],
            title: columns[2],
            album: columns[3],
          );
          ret.add(track);
        }
        columns.clear();
      }
      //print(count);
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
