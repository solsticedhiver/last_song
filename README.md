# Last Song

## An exercice to learn a bit Flutter

Get the *last track* played on a limited choice of radio channels. Currently **Radio Nova**, **Soma FM**, **BBC Radio One**.

**This does not play the radio** sound but just provide the information about the track/song played.

This is a *flutter* project able to run on Windows, Linux, on mobile (Android), MacOS. Use the `flutter-web.sh` script to run it in a browser.

![Last Song on Linux](last_song.png)

When the website's radio does not provide cover image, the app makes a search on *bandcamp.com* for an image and track length, and if no result, then  a search on *discogs.com*

## Build and run

You need the *flutter* **SDK** installed with the dependancies of your platform; and then either use `flutter build <platform>` and `flutter run`.

This has been currently tested on Windows 10, Linux, MacOS, and Android. But this might break at any time, because the tests are not made automatically, on each platform available.

## Extend

You can add any radio by creating a subclass to Channel and implement *fetchCurrentTrack* (and optionnaly *getRecentTracks*, and *getCurrentShow*).
If no image is provided by the radio website, you can search bandcamp with the searchBandcamp function.

Add it to ChannelManager.initialize to populate the list of radios.

You can, then, send us a Pull Request? so that radio will be included?
