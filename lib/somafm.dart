import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'helpers.dart';
import 'bandcamp.dart';

class SomaFm extends Channel {
  static const subchannels = {
    "groovesalad": {"name": "Groove Salad", "image": "/img/groovesalad120.png"},
    "gsclassic": {
      "name": "Groove Salad Classic",
      "image": "/img3/gsclassic120.jpg"
    },
    "synphaera": {"name": "Synphaera Radio", "image": "/img3/synphaera120.jpg"},
    "dronezone": {"name": "Drone Zone", "image": "/img/dronezone120.jpg"},
    "darkzone": {"name": "The Dark Zone", "image": "/img/darkzone-120.jpg"},
    "metal": {"name": "Metal Detector", "image": "/img3/metal120.png"},
    "illstreet": {
      "name": "Illinois Street Lounge",
      "image": "/img/illstreet.jpg"
    },
    "suburbsofgoa": {"name": "Suburbs of Goa", "image": "/img/sog120.jpg"},
    "bootliquor": {"name": "Boot Liquor", "image": "/img/bootliquor120.jpg"},
    "7soul": {"name": "Seven Inch Soul", "image": "/img/7soul120.png"},
    "seventies": {"name": "Left Coast 70s", "image": "/img/seventies120.jpg"},
    "u80s": {"name": "Underground 80s", "image": "/img/u80s-120.png"},
    "defcon": {"name": "DEF CON Radio", "image": "/img/defcon120.png"},
    "fluid": {"name": "Fluid", "image": "/img/fluid120.jpg"},
    "lush": {"name": "Lush", "image": "/img/lush120.jpg"},
    "poptron": {"name": "PopTron", "image": "/img/poptron120.png"},
    "covers": {"name": "Covers", "image": "/img/covers120.jpg"},
    "cliqhop": {"name": "cliqhop idm", "image": "/img/cliqhop120.png"},
    "dubstep": {"name": "Dub Step Beyond", "image": "/img/dubstep120.png"},
    "beatblender": {"name": "Beat Blender", "image": "/img/blender120.png"},
    "deepspaceone": {
      "name": "Deep Space One",
      "image": "/img/deepspaceone120.gif"
    },
    "spacestation": {"name": "Space Station Soma", "image": "/img/sss.jpg"},
    "n5md": {"name": "n5MD Radio", "image": "/img/n5md120.png"},
    "vaporwaves": {"name": "Vaporwaves", "image": "/img/vaporwaves120.jpg"},
    "secretagent": {"name": "Secret Agent", "image": "/img/secretagent120.jpg"},
    "reggae": {"name": "Heavyweight Reggae", "image": "/img3/reggae120.png"},
    "thetrip": {"name": "The Trip", "image": "/img/thetrip120.jpg"},
    "sonicuniverse": {
      "name": "Sonic Universe",
      "image": "/img/sonicuniverse120.jpg"
    },
    "missioncontrol": {
      "name": "Mission Control",
      "image": "/img/missioncontrol120.jpg"
    },
    "indiepop": {"name": "Indie Pop Rocks!", "image": "/img/indychick.jpg"},
    "digitalis": {"name": "Digitalis", "image": "/img/digitalis120.png"},
    "folkfwd": {"name": "Folk Forward", "image": "/img/folkfwd120.jpg"},
    "thistle": {"name": "ThistleRadio", "image": "/img/thistle120.png"},
    "brfm": {"name": "Black Rock FM", "image": "/img/1023brc.jpg"},
    "sf1033": {"name": "SF 10-33", "image": "/img/sf1033120.png"},
    "scanner": {"name": "SF Police Scanner", "image": "/img/sf1033120.png"},
    "live": {"name": "SomaFM Live", "image": "/img/SomaFMDJSquare120.jpg"},
    "xmasinfrisko": {
      "name": "Xmas in Frisko",
      "image": "/img/xmasinfrisco120.jpg"
    },
    "christmas": {
      "name": "Christmas Lounge",
      "image": "/img/christmaslounge120.png"
    },
    "xmasrocks": {"name": "Christmas Rocks!", "image": "/img/xmasrocks120.png"},
    "jollysoul": {"name": "Jolly Ol' Soul", "image": "/img/jollysoul120.png"},
    "specials": {
      "name": "Department Store Christmas",
      "image": "/img3/deptstorexmas120.jpg"
    },
  };

  SomaFm(String subchannel) {
    radio = 'Soma FM';
    String? scn = SomaFm.subchannels[subchannel]?['name'];
    if (scn != null) {
      title = scn;
    }
    String? sci = SomaFm.subchannels[subchannel]?['image'];
    if (sci != null) {
      imageUrl = 'https://somafm.com$sci';
    }
    this.subchannel = subchannel;
    author = 'Rusty Hodge';
    airingTime = '';
  }

  @override
  Future<int> fetchCurrentTrack([bool manual = false]) async {
    int ret = 0;
    Track track;

    recentTracks = await SomaFm.getRecentTracks(subchannel);
    if (recentTracks.isNotEmpty) {
      track = recentTracks.elementAt(0);
    } else {
      track = Track();
    }

    if (track.title != currentTrack.title &&
        track.artist != currentTrack.artist) {
      currentTrack.updateFrom(track);
      // search for an image cover
      ResponseBandcamp resp =
          await searchBandcamp('${track.title} ${track.artist}', 't');
      if (resp.imageUrl.isNotEmpty) {
        currentTrack.imageUrl = resp.imageUrl;
        if (resp.duration.isNotEmpty) {
          currentTrack.duration = resp.duration;
        }
      } else {
        resp = await searchBandcamp('${track.album} ${track.artist}', 'a');
        if (resp.imageUrl.isNotEmpty) {
          currentTrack.imageUrl = resp.imageUrl;
        }
      }
      notifyListeners();
      ret += 1;
    }
    return ret;
  }

  static Future<List<Track>> getRecentTracks(String subchannel) async {
    // get timezone and current date of San Francisco
    tz.initializeTimeZones();
    tz.Location sanFrancisco = tz.getLocation('America/Los_Angeles');
    tz.TZDateTime now = tz.TZDateTime.now(sanFrancisco);
    String timeZone = convertSecondsToHours(
        sanFrancisco.timeZone(now.millisecondsSinceEpoch).offset ~/ 1000);
    String currentDate = now.toString().substring(0, 10);

    WebScraper webScraper = WebScraper('https://somafm.com');

    List<Track> ret = <Track>[];
    String page = '/recent/$subchannel.html';
    if (await webScraper.loadWebPage(page)) {
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
