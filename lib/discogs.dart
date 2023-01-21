import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

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
  http.Request req = http.Request(
      'GET', Uri.parse('https://api.discogs.com/database/search?$queryString'));
  req.headers.addAll({
    'Authorization':
        'Discogs key=$discogsKey, secret=${discogsSecret.split('').reversed.join()}',
  });
  http.StreamedResponse streamedResponse = await req.send();
  final resp = await http.Response.fromStream(streamedResponse);

  //print(resp.statusCode);
  Map<String, dynamic> reply = jsonDecode(resp.body);

  if (resp.statusCode == 200) {
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
    //print(reply['message']);
  }
  return ResponseDiscogs(imageUrl, duration);
}