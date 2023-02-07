import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'helpers.dart';

const String discogsKey = 'GRcTnfYcKdIFUeOEtUtA';
const String discogsSecret = 'dtmKATJxslqZHzKHFmRhJUDFLXNVBGlb';

class ResponseDiscogs {
  String imageUrl;
  String duration;

  ResponseDiscogs(this.imageUrl, this.duration);
}

Future<ResponseDiscogs> searchDiscogs(Map<String, String> search) async {
  String imageUrl = '';
  String duration = '';

  String queryString = Uri(
      queryParameters:
          search.map((key, value) => MapEntry(key, value.toString()))).query;
  /*
  # Pagination
  - per_page number
  - page number
  # Search parameters
  - query
    string (optional) Example: nirvana
    Your search query
  - type
    string (optional) Example: release
    String. One of release, master, artist, label
  - title
    string (optional) Example: nirvana - nevermind
    Search by combined “Artist Name - Release Title” title field.
  - release_title
    string (optional) Example: nevermind
    Search release titles.
  - credit
    string (optional) Example: kurt
    Search release credits.
  - artist
    string (optional) Example: nirvana
    Search artist names.
  - anv
    string (optional) Example: nirvana
    Search artist ANV.
  - label
    string (optional) Example: dgc
    Search label names.
  - genre
    string (optional) Example: rock
    Search genres.
  - style
    string (optional) Example: grunge
    Search styles.
  - country
    string (optional) Example: canada
    Search release country.
  - year
    string (optional) Example: 1991
    Search release year.
  - format
    string (optional) Example: album
    Search formats.
  - catno
    string (optional) Example: DGCD-24425
    Search catalog number.
  - barcode
    string (optional) Example: 7 2064-24425-2 4
    Search barcodes.
  - track
    string (optional) Example: smells like teen spirit
    Search track titles.
  - submitter
    string (optional) Example: milKt
    Search submitter username.
  - contributor
    string (optional) Example: jerome99
    Search contributor usernames.
  */
  //print(queryString);
  final client = http.Client();
  final url = Uri.parse('https://api.discogs.com/database/search?$queryString');
  final headers = {
    'User-Agent': AppConfig.userAgent,
    'Authorization':
        'Discogs key=$discogsKey, secret=${discogsSecret.split('').reversed.join()}',
  };
  http.Response resp;
  try {
    resp = await client.get(url, headers: headers);
  } catch (e) {
    return ResponseDiscogs(imageUrl, duration);
  }

  if (resp.statusCode == 403) {
    // CloudFlare anti-scrap technique IUAM
    // TODO: find a way to work-around that
  }

  if (resp.statusCode == 200) {
    Map<String, dynamic> reply = jsonDecode(resp.body);
    //print(reply);
    final results = reply['results'];
    for (var res in results) {
      //print(res['title']);
      if (res['title'].toLowerCase().contains(search['q']?.toLowerCase())) {
        imageUrl = res['cover_image'];
        //print(imageUrl);
        break;
      }
    }
  } else {
    //debugPrint('debug: ${resp.statusCode}: ${resp.body}');
    debugPrint('debug: discogs search = ${resp.statusCode}');
  }
  if (imageUrl != '') {
    debugPrint('debug: found on discogs $imageUrl');
  }
  return ResponseDiscogs(imageUrl, duration);
}
