class StringUtils {
  /// Sanitizes a string to ensure it contains only well-formed UTF-16 code units.
  /// Unpaired surrogates are replaced with the Unicode replacement character (0xFFFD).
  static String safeUtf16(String? input) {
    if (input == null) return '';
    try {
      return String.fromCharCodes(input.runes);
    } catch (_) {
      final cleanCodes = <int>[];
      for (var i = 0; i < input.length; i++) {
        final code = input.codeUnitAt(i);
        if (code >= 0xD800 && code <= 0xDFFF) {
          if (i + 1 < input.length) {
            final nextCode = input.codeUnitAt(i + 1);
            if (code <= 0xDBFF && nextCode >= 0xDC00 && nextCode <= 0xDFFF) {
              cleanCodes.add(code);
              cleanCodes.add(nextCode);
              i++;
              continue;
            }
          }
          cleanCodes.add(0xFFFD); // Replacement character
        } else {
          cleanCodes.add(code);
        }
      }
      return String.fromCharCodes(cleanCodes);
    }
  }
}
