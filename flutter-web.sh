#!/bin/bash
# work-around to disable CORS causing error
# TODO: hide the tab strip because there will be only one tab there
flutter run -d chrome --web-browser-flag "--disable-web-security"
