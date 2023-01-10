import 'dart:convert';

import 'package:http/http.dart' as http;

Future<String> searchBandcamp(String s, String type) async {
  assert(type == 'a' || type == 't');

  String imageUrl = '';
  String rawData = json.encode({
    'search_text': s,
    'search_filter': type,
    'full_page': false,
    'fan_id': null
  });

  http.Request req = http.Request(
      'POST',
      Uri.parse(
          'https://bandcamp.com/api/bcsearch_public_api/1/autocomplete_elastic'));
  req.body = rawData;
  req.headers.addAll({
    'x-requested-with': 'XMLHttpRequest',
    'accept': 'application/json',
    'content-type': 'application/json; charset=UTF-8',
  });
  http.StreamedResponse streamedResponse = await req.send();
  final resp = await http.Response.fromStream(streamedResponse);

  if (resp.statusCode == 200) {
    Map<String, dynamic> reply = jsonDecode(resp.body);
    final results = reply['auto']['results'];

    for (var res in results) {
      if (res['type'] == type) {
        // reconstruct image url because res['img'] is a 404
        imageUrl =
            'https://f4.bcbits.com/img/a${res["art_id"]}_16.jpg'; // 13 => 400p, 16 => 700p
        break;
      }
    }
  }
  return imageUrl;
}
