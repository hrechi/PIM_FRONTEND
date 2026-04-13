class VoiceNumberParser {
  static final RegExp _digitPattern = RegExp(r'\b\d+(?:[.,]\d+)?\b');

  static const Map<String, int> _cardinalWords = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
    'hundred': 100,
    'thousand': 1000,
    'un': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'onze': 11,
    'douze': 12,
    'treize': 13,
    'quatorze': 14,
    'quinze': 15,
    'seize': 16,
    'vingt': 20,
    'trente': 30,
    'quarante': 40,
    'cinquante': 50,
    'soixante': 60,
    'cent': 100,
    'mille': 1000,
  };

  static const Map<String, int> _ordinalWords = <String, int>{
    'first': 1,
    'second': 2,
    'third': 3,
    'fourth': 4,
    'fifth': 5,
    'sixth': 6,
    'seventh': 7,
    'eighth': 8,
    'ninth': 9,
    'tenth': 10,
    'premier': 1,
    'deuxieme': 2,
    'troisieme': 3,
    'quatrieme': 4,
    'cinquieme': 5,
  };

  static const Set<String> _decimalMarkers = <String>{
    'point',
    'dot',
    'comma',
    'virgule',
  };

  static const Set<String> _connectors = <String>{
    'and',
    'et',
  };

  static double? parseNumberFromText(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return null;
    }

    final digitMatch = _digitPattern.firstMatch(normalized);
    if (digitMatch != null) {
      final parsed = double.tryParse(
        digitMatch.group(0)!.replaceAll(',', '.'),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final tokens = normalized
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    for (int start = 0; start < tokens.length; start++) {
      final parsed = _tryParseFromTokens(tokens, start);
      if (parsed != null) {
        return parsed.value;
      }
    }

    return null;
  }

  static int? parseOneBasedIndex(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return null;
    }

    final digitMatch = RegExp(r'\b\d+\b').firstMatch(normalized);
    if (digitMatch != null) {
      final value = int.tryParse(digitMatch.group(0)!);
      if (value != null && value > 0) {
        return value;
      }
    }

    final tokens = normalized
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    for (int i = 0; i < tokens.length; i++) {
      final ordinal = _ordinalWords[tokens[i]];
      if (ordinal != null && ordinal > 0) {
        return ordinal;
      }
    }

    final parsedNumber = parseNumberFromText(normalized);
    if (parsedNumber == null) {
      return null;
    }

    final rounded = parsedNumber.round();
    if ((parsedNumber - rounded).abs() > 0.0001 || rounded <= 0) {
      return null;
    }

    return rounded;
  }

  static _ParsedNumber? _tryParseFromTokens(List<String> tokens, int start) {
    int current = 0;
    int total = 0;
    bool seenAny = false;

    for (int i = start; i < tokens.length; i++) {
      final token = tokens[i];

      final ordinal = _ordinalWords[token];
      if (!seenAny && ordinal != null) {
        return _ParsedNumber(ordinal.toDouble());
      }

      if (_connectors.contains(token)) {
        if (!seenAny) {
          break;
        }
        continue;
      }

      if (_decimalMarkers.contains(token)) {
        if (!seenAny) {
          break;
        }

        final decimalDigits = StringBuffer();
        for (int j = i + 1; j < tokens.length; j++) {
          final next = tokens[j];

          if (_connectors.contains(next)) {
            continue;
          }

          if (RegExp(r'^\d+$').hasMatch(next)) {
            decimalDigits.write(next);
            continue;
          }

          final cardinal = _cardinalWords[next];
          if (cardinal != null) {
            if (cardinal < 10) {
              decimalDigits.write(cardinal.toString());
              continue;
            }

            if (cardinal < 100) {
              final text = cardinal.toString();
              decimalDigits.write(text);
              continue;
            }
          }

          break;
        }

        if (decimalDigits.isEmpty) {
          break;
        }

        final whole = (total + current).toString();
        final value = double.tryParse('$whole.${decimalDigits.toString()}');
        if (value == null) {
          return null;
        }

        return _ParsedNumber(value);
      }

      final cardinal = _cardinalWords[token];
      if (cardinal == null) {
        break;
      }

      seenAny = true;
      if (cardinal == 100) {
        if (current == 0) {
          current = 1;
        }
        current *= 100;
        continue;
      }

      if (cardinal == 1000) {
        if (current == 0) {
          current = 1;
        }
        total += current * 1000;
        current = 0;
        continue;
      }

      current += cardinal;
    }

    if (!seenAny) {
      return null;
    }

    return _ParsedNumber((total + current).toDouble());
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'["`]+'), ' ')
        .replaceAll(RegExp(r'[،;:!?؟!]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ParsedNumber {
  const _ParsedNumber(this.value);

  final double value;
}
