extension ChangeCaseString on String {
  // https://gist.github.com/filiph/d4e0c0a9efb0f869f984317372f5bee8?permalink_comment_id=3486118#gistcomment-3486118
  String toTitleCase() {
    final stringBuffer = StringBuffer();

    var capitalizeNext = true;
    for (final letter in toLowerCase().codeUnits) {
      // UTF-16: A-Z => 65-90, a-z => 97-122.
      if (capitalizeNext && letter >= 97 && letter <= 122) {
        stringBuffer.writeCharCode(letter - 32);
        capitalizeNext = false;
      } else {
        // UTF-16: 32 == space, 46 == period
        if (letter == 32 || letter == 46) capitalizeNext = true;
        stringBuffer.writeCharCode(letter);
      }
    }

    return stringBuffer.toString();
  }
}
