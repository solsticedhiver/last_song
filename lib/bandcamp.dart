import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

import 'helpers.dart';

class ResponseBandcamp {
  String imageUrl = '';
  String duration = '';

  ResponseBandcamp(this.imageUrl, this.duration);
}

Future<ResponseBandcamp> searchBandcamp(String s, String type) async {
  assert(type == 'a' || type == 't' || type == 'b');
  // a = album, t = track, b = band

  String imageUrl = '';
  String duration = '';
  final rawData = json.encode({
    'search_text': s,
    'search_filter': type,
    'full_page': false,
    'fan_id': null
  });
  final headers = {
    'x-requested-with': 'XMLHttpRequest',
    'accept': 'application/json',
    'content-type': 'application/json; charset=UTF-8',
    'user-agent': AppConfig.userAgent,
  };
  // the official API is not free, so using the result of elastic search
  Uri uri = Uri.parse(
      'https://bandcamp.com/api/bcsearch_public_api/1/autocomplete_elastic');
  final http.Response resp;
  try {
    resp = await http.post(uri, body: rawData, headers: headers);
  } catch (e) {
    debugPrint('debug: bandcamp search = $e');
    return ResponseBandcamp(imageUrl, duration);
  }

  if (resp.statusCode == 200) {
    Map<String, dynamic> reply = jsonDecode(resp.body);
    final results = reply['auto']['results'];

    for (var res in results) {
      if (res['type'] == type) {
        // reconstruct image url because res['img'] is a 404
        imageUrl =
            'https://f4.bcbits.com/img/a${res["art_id"]}_13.jpg'; // 13 => 400p, 16 => 700p
        if (type == 't') {
          duration = await lookForTrackDuration(res['item_url_path']);
        }
        break;
      }
    }
  } else {
    debugPrint('debug: bandcamp search = ${resp.statusCode}');
    return ResponseBandcamp(imageUrl, duration);
  }

  if (imageUrl != '') {
    debugPrint('debug: found on bandcamp $imageUrl');
  }
  return ResponseBandcamp(imageUrl, duration);
}

Future<String> lookForTrackDuration(String url) async {
  String duration = '';

  final resp = await http.get(Uri.parse(url), headers: {
    'User-Agent': AppConfig.userAgent,
  });
  if (resp.statusCode != 200) {
    return duration;
  }
  final document = parser.parse(resp.body);
  final script = document.querySelector('script[type="application/ld+json"]');
  if (script != null) {
    final jd =
        json.decode(script.text)['duration']; // coded like P00H10M11S for 10:11
    if (jd != null) {
      duration = '${jd.substring(4, 6)}:${jd.substring(7, 9)}';
    }
  }

  return duration;
}
