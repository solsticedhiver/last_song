import 'package:web_scraper/web_scraper.dart';
import 'dart:convert';

// fetch main page and scrap data to create const subchannels data
void main() async {
  WebScraper webScraper = WebScraper('https://somafm.com');

  bool isLoaded = false;

  try {
    isLoaded = await webScraper.loadWebPage('/index.html');
  } on WebScraperException catch (e) {
    print(e.errorMessage());
  }
  Map<String, dynamic> res = {};
  List<String> first = [];
    List<Map<String, dynamic>> elements;
  if (isLoaded) {
    print('Step #1');
    elements =
        webScraper.getElement('#featured_channels li.cbshort > a', ['href']);
    //print(elements);
    for (var e in elements) {
     String code = e['attributes']['href'].replaceAll('/', '');
        first.add(code);

    }
    print('done');
    print('Step #2');
    elements =
        webScraper.getElement('#featured_channels li.cbshort > h3', ['']);
    //print(elements);
    int indx = 0;
    for (var e in elements) {
      res[first[indx]] = {'name': e['title']};
      indx++;
    }
    print('done');
    print('Step #3');
    elements =
        webScraper.getElement('#featured_channels li.cbshort > p', ['']);
    indx = 0;
    for (var e in elements) {
      res[first[indx]]['descr'] = e['title'];
      indx++;
    }
    print('done');
    print('Step #4');
    elements =
        webScraper.getElement('#featured_channels li.cbshort > a > img', ['src']);
    indx = 0;
    for (var e in elements) {
      res[first[indx]]['img'] = e['attributes']['src'];
      indx++;
    }
    print('done');
  }
  print('Step #5');
  for (var k in res.keys) {
    try {
      isLoaded = await webScraper.loadWebPage('/$k/');
    } on WebScraperException catch (e) {
      print(e.errorMessage());
    }
    if (isLoaded) {
      elements =
          webScraper.getElement('#channellogo > img', ['src']);
      res[k]['big'] = elements[0]['attributes']['src'];
      
    } else {
      print('error');
    }
  }
  print('done');
  //print(res);
  //for (var k in res.keys) {
  //  print('"$k": {\n  "name": "${res[k]['name']}",\n  "image": "${res[k]['img']}",\n  "big": "${res[k]['big']}",\n  "descr": "${res[k]['descr']}",\n},');
  //}
  var encoder = new JsonEncoder.withIndent('  ');
  print(encoder.convert(res));
}

