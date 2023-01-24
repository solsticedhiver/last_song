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

import 'dart:convert';

import 'bandcamp.dart';
import 'helpers.dart';

import 'package:http/http.dart' as http;

const String bbcRadioOne =
    'https://rms.api.bbc.co.uk/v2/services/bbc_radio_one/tracks/latest/playable?limit=10';
//'https://rms.api.bbc.co.uk/v2/services/bbc_radio_one/segments/latest?experience=domestic&offset=0&limit=10';
const String bbcCurrentShow =
    'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=SERVICE&on_air=now';

class RadioOne extends Channel {
  static const _subchannels = {
    "bbc_radio_one": {"name": "BBC Radio 1"}
  };
  @override
  Map<String, dynamic> get subchannels => _subchannels;

  static Map<String, dynamic> get getSubchannels => _subchannels;

  RadioOne(String subchannel) {
    radio = 'BBC Radio';
    this.subchannel = subchannel;
    String? sn = subchannels[subchannel]?['name'];
    if (sn != null) {
      show = sn;
    }
    imageUrl = 'assets/radioone.png';
    imageUrlBig = imageUrl;
    author = '';
    airingTime = '';
  }

  int updateFromJson(Map<String, dynamic> json) {
    int ret = 0;

    final ct = json['data'];
    if (ct != null) {
      if (currentTrack.title != ct['titles']['secondary']) {
        ret += 1;
        currentTrack.artist = ct['titles']['primary'];
        currentTrack.title = ct['titles']['secondary'];
        currentTrack.imageUrl = ct['image_url'];
        //currentTrack.diffusionDate = ct['offset']['start']; // TODO: do something with it
        //currentTrack.duration = ct['offset']['end'];
      }
    }
    return ret;
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;

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
    getCurrentShow();
    notifyListeners();

    return ret;
  }

  @override
  Future<List<Track>> getRecentTracks() async {
    List<Track> ret = <Track>[];

    final http.Response resp;
    try {
      resp = await http.get(Uri.parse(bbcRadioOne));
      //print(resp.statusCode);
    } catch (e) {
      print(e);
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
        ret.add(track);
      }
    }
    //print(ret);
    return ret;
  }

  void getCurrentShow() async {
    final http.Response resp;
    try {
      resp = await http
          .get(Uri.parse(bbcCurrentShow.replaceFirst('SERVICE', subchannel)));
      //print(resp.statusCode);
    } catch (e) {
      print(e);
      return;
    }

    if (resp.statusCode == 200) {
      Map<String, dynamic> rj = json.decode(utf8.decode(resp.bodyBytes));
      final broadcast = rj['data'][0];
      final programme = broadcast['programme'];
      // which one to pick between titles/primary, titles/secondary, titles/primary_title, titles/entity_title ?
      show = programme['titles']['secondary'];
      author = programme['titles']['primary'];
      final start = DateTime.parse(broadcast['start']).toLocal();
      final end = DateTime.parse(broadcast['end']).toLocal();
      airingTime =
          '${start.toString().substring(11, 16)} - ${end.toString().substring(11, 16)}';
      imageUrlBig =
          programme['images'][0]['url'].replaceFirst('{recipe}', '400x400');
      imageUrl = imageUrlBig;
    }
  }
}
// https://rms.api.bbc.co.uk/docs/swagger.json#/definitions/ErrorResponse

// curl -X 'GET'   'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=bbc_radio_one&on_air=now'   -H 'accept: application/json'   -H 'X-API-Key: 3A5LU4tQWvWW3lpgF5OT4IWUoyLaju9z'|jq .

// curl -X 'GET'   'https://rms.api.bbc.co.uk/v2/broadcasts/latest?service=bbc_radio_one&on_air=previous&previous=120'   -H 'accept: application/json'   -H 'X-API-Key: 3A5LU4tQWvWW3lpgF5OT4IWUoyLaju9z'|jq .