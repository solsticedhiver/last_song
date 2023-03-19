import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bandcamp.dart';
import 'helpers.dart';

import 'package:http/http.dart' as http;

const String bbcLatestSegments =
    'https://rms.api.bbc.co.uk/v2/services/SERVICE/segments/latest?experience=domestic&offset=0&limit=10';
const String bbcCurrentShow =
    'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=SERVICE&on_air=now';

class BBCRadio extends Channel {
  static List<dynamic> subchannels = [
    {"code": "bbc_radio_one", "name": "BBC Radio 1"},
    {"code": "bbc_radio_two", "name": "BBC Radio 2"},
    {"code": "bbc_radio_three", "name": "BBC Radio 3"},
    {"code": "bbc_radio_four", "name": "BBC Radio 4"},
    {"code": "bbc_radio_five_live", "name": "BBC Radio 5"},
    //{"code": "bbc_radio_six", "name": "BBC Radio 6"},
  ];

  BBCRadio(String code, String name) {
    radio = 'BBC Radio';
    subchannel.codename = code;
    subchannel.title = name;
    subchannel.imageUrl = 'assets/img/$code.png';
    subchannel.bigImageUrl = subchannel.imageUrl;
  }

  @override
  String toString() {
    return 'BBCRadio(subchannel: ${subchannel.toString()}';
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;

    int _ = await getCurrentShow();

    recentTracks = await getRecentTracks();
    if (recentTracks.isNotEmpty) {
      currentTrack.updateFrom(recentTracks[0]);
    }
    if (currentTrack.imageUrl == '' &&
        currentTrack.artist != 'Artist' &&
        currentTrack.title != 'Title') {
      ResponseBandcamp sb = await searchBandcamp(
          '${currentTrack.artist} ${currentTrack.title}', 't');
      if (sb.imageUrl != '') {
        currentTrack.imageUrl = sb.imageUrl;
      }
      if (sb.duration != '') {
        currentTrack.duration = sb.duration;
      }
    }
    notifyListeners();

    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    List<Track> ret = <Track>[];

    final http.Response resp;
    final headers = {
      'User-Agent': AppConfig.userAgent,
    };
    try {
      final String bbcRadioUrl =
          bbcLatestSegments.replaceFirst('SERVICE', subchannel.codename);
      resp = await http
          .get(Uri.parse(bbcRadioUrl), headers: headers)
          .timeout(const Duration(seconds: 15));
      //print(resp.statusCode);
    } catch (e) {
      debugPrint('debug: $e');
      return ret;
    }

    if (resp.statusCode == 200) {
      Map<String, dynamic> rj = jsonDecode(resp.body);
      for (var segment in rj['data']) {
        Track track = Track(
            artist: segment['titles']['primary'],
            title: segment['titles']['secondary'],
            imageUrl: segment['image_url']);
        if (segment['titles']['tertiary'] != null) {
          track.album = segment['titles']['tertiary'];
        }
        if (track.imageUrl ==
            'https://ichef.bbci.co.uk/images/ic/{recipe}/p0bqcdzf.jpg') {
          track.imageUrl = '';
        } else {
          track.imageUrl = track.imageUrl.replaceFirst('{recipe}', '400x400');
        }

        if (show.start != null) {
          DateTime dd =
              show.start!.add(Duration(seconds: segment['offset']['start']));
          if (DateTime.now().compareTo(dd) == 1) {
            track.diffusionDate = dd.toIso8601String();
          } else {
            // this means it comes from the previous show
            // TODO: fetch it, and get the start time ?
          }
        }
        int duration = segment['offset']['end'] - segment['offset']['start'];
        track.duration = '${duration ~/ 60}:${duration % 60}';
        ret.add(track);
      }
    }
    //print(ret);
    return ret;
  }

  Future<int> getCurrentShow() async {
    final http.Response resp;
    final headers = {
      'User-Agent': AppConfig.userAgent,
    };
    int ret = 0;
    try {
      resp = await http
          .get(
              Uri.parse(
                  bbcCurrentShow.replaceFirst('SERVICE', subchannel.codename)),
              headers: headers)
          .timeout(const Duration(seconds: 15));
      //print(resp.statusCode);
    } catch (e) {
      debugPrint('debug: $e');
      return ret;
    }
    ret = 1;

    if (resp.statusCode == 200) {
      Map<String, dynamic> rj = json.decode(utf8.decode(resp.bodyBytes));
      final broadcast = rj['data'][0];
      final programme = broadcast['programme'];
      // which one to pick between titles/primary, titles/secondary, titles/primary_title, titles/entity_title ?
      show.name = programme['titles']['secondary'];
      show.author = programme['titles']['primary'];
      show.start = DateTime.parse(broadcast['start']).toLocal();
      show.end = DateTime.parse(broadcast['end']).toLocal();
      show.airingTime =
          '${show.start.toString().substring(11, 16)} - ${show.end.toString().substring(11, 16)}';
      show.imageUrl =
          programme['images'][0]['url'].replaceFirst('{recipe}', '400x400');
      if (programme['synopses']['long'] != null) {
        show.description = programme['synopses']['long'];
      } else if (programme['synopses']['medium'] != null) {
        show.description = programme['synopses']['medium'];
      } else if (programme['synopses']['short'] != null) {
        show.description = programme['synopses']['short'];
      }
    }
    return ret;
  }
}
//const String bbcRadio =
//    'https://rms.api.bbc.co.uk/v2/services/bbc_radio_one/tracks/latest/playable?limit=10';
//    'https://rms.api.bbc.co.uk/v2/services/bbc_radio_one/segments/latest?experience=domestic&offset=0&limit=10';

// https://rms.api.bbc.co.uk/docs/swagger.json#/definitions/ErrorResponse

// curl -X 'GET'   'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=bbc_radio_one&on_air=now'   -H 'accept: application/json'   -H 'X-API-Key: 3A5LU4tQWvWW3lpgF5OT4IWUoyLaju9z'|jq .

// curl -X 'GET'   'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=bbc_radio_one&on_air=previous&previous=120'   -H 'accept: application/json'   -H 'X-API-Key: 3A5LU4tQWvWW3lpgF5OT4IWUoyLaju9z'|jq .

/*
curl 'https://rms.api.bbc.co.uk/v2/services/bbc_radio_one/segments/latest?experience=domestic&offset=0&limit=4' \
  -H 'Accept: application/json' \
  -H 'Accept-Language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'DNT: 1' \
  -H 'Origin: https://www.bbc.co.uk' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://www.bbc.co.uk/' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  -H 'X-API-Key: 3A5LU4tQWvWW3lpgF5OT4IWUoyLaju9z' \
  -H 'sec-ch-ua: "Chromium";v="109", "Not_A Brand";v="99"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Linux"' \
  -H 'sec-gpc: 1' \
  --compressed
  */
