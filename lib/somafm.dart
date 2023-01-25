import 'package:web_scraper/web_scraper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'helpers.dart';
import 'bandcamp.dart';
import 'discogs.dart';

class SomaFm extends Channel {
  static const _subchannels = {
    "groovesalad": {
      "name": "Groove Salad",
      "image": "/img/groovesalad120.png",
      "big": "/img3/groovesalad-400.png",
      "descr": "A nicely chilled plate of ambient/downtempo beats and grooves.",
    },
    "gsclassic": {
      "name": "Groove Salad Classic",
      "image": "/img3/gsclassic120.jpg",
      "big": "/img3/gsclassic400.jpg",
      "descr":
          "The classic (early 2000s) version of a nicely chilled plate of ambient/downtempo beats and grooves.",
    },
    "synphaera": {
      "name": "Synphaera Radio",
      "image": "/img3/synphaera120.jpg",
      "big": "/img3/synphaera400.jpg",
      "descr":
          "Featuring the music from an independent record label focused on modern electronic ambient and space music.",
    },
    "dronezone": {
      "name": "Drone Zone",
      "image": "/img/dronezone120.jpg",
      "big": "/img3/dronezone-400.png",
      "descr":
          "Served best chilled, safe with most medications. Atmospheric textures with minimal beats.",
    },
    "darkzone": {
      "name": "The Dark Zone",
      "image": "/img/darkzone-120.jpg",
      "big": "/img/darkzone-400.jpg",
      "descr":
          "The darker side of deep ambient. Music for staring into the Abyss.",
    },
    "metal": {
      "name": "Metal Detector",
      "image": "/img3/metal120.png",
      "big": "/img3/metal-400.png",
      "descr":
          "From black to doom, prog to sludge, thrash to post, stoner to crossover, punk to industrial.",
    },
    "illstreet": {
      "name": "Illinois Street Lounge",
      "image": "/img/illstreet.jpg",
      "big": "/img3/illstreet-400.jpg",
      "descr":
          "Classic bachelor pad, playful exotica and vintage music of tomorrow.",
    },
    "suburbsofgoa": {
      "name": "Suburbs of Goa",
      "image": "/img/sog120.jpg",
      "big": "/img3/suburbsofgoa-400.png",
      "descr": "Desi-influenced Asian world beats and beyond.",
    },
    "bootliquor": {
      "name": "Boot Liquor",
      "image": "/img/bootliquor120.jpg",
      "big": "/img3/bootliquor-400.png",
      "descr": "Americana Roots music for Cowhands, Cowpokes and Cowtippers",
    },
    "7soul": {
      "name": "Seven Inch Soul",
      "image": "/img/7soul120.png",
      "big": "/img3/7soul-400.jpg",
      "descr": "Vintage soul tracks from the original 45 RPM vinyl.",
    },
    "seventies": {
      "name": "Left Coast 70s",
      "image": "/img/seventies120.jpg",
      "big": "/img3/seventies400.jpg",
      "descr": "Mellow album rock from the Seventies. Yacht not required.",
    },
    "u80s": {
      "name": "Underground 80s",
      "image": "/img/u80s-120.png",
      "big": "/img3/u80s-400.png",
      "descr": "Early 80s UK Synthpop and a bit of New Wave.",
    },
    "defcon": {
      "name": "DEF CON Radio",
      "image": "/img/defcon120.png",
      "big": "/img3/defcon400.png",
      "descr": "Music for Hacking. The DEF CON Year-Round Channel.",
    },
    "fluid": {
      "name": "Fluid",
      "image": "/img/fluid120.jpg",
      "big": "/img3/fluid-400.jpg",
      "descr":
          "Drown in the electronic sound of instrumental hiphop, future soul and liquid trap.",
    },
    "lush": {
      "name": "Lush",
      "image": "/img/lush120.jpg",
      "big": "/img3/lush-400.jpg",
      "descr":
          "Sensuous and mellow female vocals, many with an electronic influence.",
    },
    "poptron": {
      "name": "PopTron",
      "image": "/img/poptron120.png",
      "big": "/img3/poptron-400.png",
      "descr": "Electropop and indie dance rock with sparkle and pop.",
    },
    "covers": {
      "name": "Covers",
      "image": "/img/covers120.jpg",
      "big": "/img3/covers-400.png",
      "descr":
          "Just covers. Songs you know by artists you don't. We've got you covered.",
    },
    "cliqhop": {
      "name": "cliqhop idm",
      "image": "/img/cliqhop120.png",
      "big": "/img3/cliqhop-400.png",
      "descr": "Blips'n'beeps backed mostly w/beats. Intelligent Dance Music.",
    },
    "dubstep": {
      "name": "Dub Step Beyond",
      "image": "/img/dubstep120.png",
      "big": "/img3/dubstep-400.png",
      "descr":
          "Dubstep, Dub and Deep Bass. May damage speakers at high volume.",
    },
    "beatblender": {
      "name": "Beat Blender",
      "image": "/img/blender120.png",
      "big": "/img3/beatblender-400.png",
      "descr": "A late night blend of deep-house and downtempo chill.",
    },
    "deepspaceone": {
      "name": "Deep Space One",
      "image": "/img/deepspaceone120.gif",
      "big": "/img3/deepspaceone-400.png",
      "descr":
          "Deep ambient electronic, experimental and space music. For inner and outer space exploration.",
    },
    "spacestation": {
      "name": "Space Station Soma",
      "image": "/img/sss.jpg",
      "big": "/img3/spacestation-400.png",
      "descr":
          "Tune in, turn on, space out. Spaced-out ambient and mid-tempo electronica.",
    },
    "n5md": {
      "name": "n5MD Radio",
      "image": "/img/n5md120.png",
      "big": "/img3/n5md-400.png",
      "descr":
          "Emotional Experiments in Music: Ambient, modern composition, post-rock, & experimental electronic music",
    },
    "vaporwaves": {
      "name": "Vaporwaves",
      "image": "/img/vaporwaves120.jpg",
      "big": "/img3/vaporwaves400.png",
      "descr": "All Vaporwave. All the time.",
    },
    "secretagent": {
      "name": "Secret Agent",
      "image": "/img/secretagent120.jpg",
      "big": "/img3/secretagent-400.png",
      "descr":
          "The soundtrack for your stylish, mysterious, dangerous life. For Spies and PIs too!",
    },
    "reggae": {
      "name": "Heavyweight Reggae",
      "image": "/img3/reggae120.png",
      "big": "/img3/reggae400.png",
      "descr": "Reggae, Ska, Rocksteady classic and deep tracks.",
    },
    "thetrip": {
      "name": "The Trip",
      "image": "/img/thetrip120.jpg",
      "big": "/img3/thetrip-400.jpg",
      "descr": "Progressive house / trance. Tip top tunes.",
    },
    "sonicuniverse": {
      "name": "Sonic Universe",
      "image": "/img/sonicuniverse120.jpg",
      "big": "/img3/sonicuniverse-400.png",
      "descr":
          "Transcending the world of jazz with eclectic, avant-garde takes on tradition.",
    },
    "missioncontrol": {
      "name": "Mission Control",
      "image": "/img/missioncontrol120.jpg",
      "big": "/img3/missioncontrol-400.png",
      "descr": "Celebrating NASA and Space Explorers everywhere.",
    },
    "indiepop": {
      "name": "Indie Pop Rocks!",
      "image": "/img/indychick.jpg",
      "big": "/img3/indiepop-400.png",
      "descr": "New and classic favorite indie pop tracks.",
    },
    "digitalis": {
      "name": "Digitalis",
      "image": "/img/digitalis120.png",
      "big": "/img3/digitalis-400.png",
      "descr": "Digitally affected analog rock to calm the agitated heart.",
    },
    "folkfwd": {
      "name": "Folk Forward",
      "image": "/img/folkfwd120.jpg",
      "big": "/img3/folkfwd-400.jpg",
      "descr": "Indie Folk, Alt-folk and the occasional folk classics.",
    },
    "thistle": {
      "name": "ThistleRadio",
      "image": "/img/thistle120.png",
      "big": "/img3/thistle-400.jpg",
      "descr": "Exploring music from Celtic roots and branches",
    },
    "brfm": {
      "name": "Black Rock FM",
      "image": "/img/1023brc.jpg",
      "big": "/img3/brfm-400.png",
      "descr":
          "From the Playa to the world, for the annual Burning Man festival.",
    },
    "sf1033": {
      "name": "SF 10-33",
      "image": "/img/sf1033120.png",
      "big": "/img3/sf1033-400.png",
      "descr":
          "Ambient music mixed with the sounds of San Francisco public safety radio traffic.",
    },
    "scanner": {
      "name": "SF Police Scanner",
      "image": "/img/sf1033120.png",
      "big": "/img3/scanner-400.jpg",
      "descr": "San Francisco Public Safety Scanner Feed",
    },
    "live": {
      "name": "SomaFM Live",
      "image": "/img/SomaFMDJSquare120.jpg",
      "big": "/img3/live-400.jpg",
      "descr": "Special Live Events and rebroadcasts of past live events",
    },
    "specials": {
      "name": "SomaFM Specials",
      "image": "/img/SomaFMDJSquare120.jpg",
      "big": "/img3/specials-400.jpg",
      "descr": "Now featuring Tiki Time, Bossa Beyond, Surf Report & More!",
    },
    "xmasinfrisko": {
      "name": "Xmas in Frisko",
      "image": "/img/xmasinfrisco120.jpg",
      "big": "/img3/xmasinfrisko-400.jpg",
      "descr":
          "SomaFM's wacky and eclectic holiday mix. Not for the easily offended.",
    },
    "christmas": {
      "name": "Christmas Lounge",
      "image": "/img/christmaslounge120.png",
      "big": "/img3/christmas-400.jpg",
      "descr":
          "Chilled holiday grooves and classic winter lounge tracks. (Kid and Parent safe!)",
    },
    "xmasrocks": {
      "name": "Christmas Rocks!",
      "image": "/img/xmasrocks120.png",
      "big": "/img3/xmasrocks-400.png",
      "descr": "Have your self an indie/alternative holiday season!",
    },
    "jollysoul": {
      "name": "Jolly Ol' Soul",
      "image": "/img/jollysoul120.png",
      "big": "/img3/jollysoul-400.png",
      "descr": "Where we cut right to the soul of the season.",
    },
  };

  @override
  Map<String, dynamic> get subchannels => _subchannels;

  static Map<String, dynamic> get getSubchannels => _subchannels;

  SomaFm(String subchannel) : super(radio: 'Soma FM') {
    String? scn = subchannels[subchannel]?['name'];
    if (scn != null) {
      this.subchannel.title = scn;
    }
    String? sci = subchannels[subchannel]?['image'];
    if (sci != null) {
      this.subchannel.imageUrl = 'https://somafm.com$sci';
    }
    String? scb = subchannels[subchannel]?['big'];
    if (scb != null) {
      this.subchannel.bigImageUrl = 'https://somafm.com$scb';
    }
    this.subchannel.codename = subchannel;
    show.author = 'Rusty Hodge';
    show.airingTime = '';
    show.imageUrl = this.subchannel.bigImageUrl;
    show.name = this.subchannel.title;
    show.description = subchannels[subchannel]?['descr'];
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

    WebScraper webScraper = WebScraper('https://somafm.com');

    List<Track> ret = <Track>[];
    String page = '/recent/${subchannel.codename}.html';
    bool isLoaded = false;
    try {
      isLoaded = await webScraper.loadWebPage(page);
    } on WebScraperException catch (e) {
      print(e.errorMessage());
    }
    if (isLoaded) {
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
