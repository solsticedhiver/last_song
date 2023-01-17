# Last Song

## An exercice to learn a bit Flutter

Get last track played on a selected choice of radio channels. Currently Radio Nova, and Soma FM.

This is a *flutter* project able to run on Windows, Linux, on mobile (Android). Bug prevent it to run in a browser for now.

You can add any radio by creating a subclass to Channel and implement fetchCurrentTrack (and optionnaly getRecentTracks).
If no image is provided by the radio website, you can search bandcamp with the searchBandcamp function.

Add it to ChannelManager.initialize to populate the list of radios.

You can, then, send us a Pull Request? so that radio will be included?
