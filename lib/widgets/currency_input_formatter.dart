import 'package:flutter/services.dart';

class _CurrencyParts {
  const _CurrencyParts({
    required this.integerDigits,
    required this.fractionDigits,
    required this.decimalSeparatorIndex,
  });

  final String integerDigits;
  final String fractionDigits;
  final int decimalSeparatorIndex;

  bool get hasDecimal => decimalSeparatorIndex >= 0;
}

_CurrencyParts _currencyParts(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^0-9,.]'), '');
  final commaIndex = sanitized.lastIndexOf(',');
  final periodIndex = sanitized.lastIndexOf('.');
  var decimalIndex = -1;

  if (commaIndex >= 0 && periodIndex >= 0) {
    decimalIndex = commaIndex > periodIndex ? commaIndex : periodIndex;
  } else if (commaIndex >= 0) {
    final isThousandsSeparator = RegExp(r'^\d{1,3}(,\d{3})+$')
        .hasMatch(sanitized);
    if (!isThousandsSeparator) {
      decimalIndex = commaIndex;
    }
  } else if (periodIndex >= 0) {
    decimalIndex = periodIndex;
  }

  final integerPart = decimalIndex < 0
      ? sanitized
      : sanitized.substring(0, decimalIndex);
  final fractionPart = decimalIndex < 0
      ? ''
      : sanitized.substring(decimalIndex + 1);
  return _CurrencyParts(
    integerDigits: integerPart.replaceAll(RegExp(r'[^0-9]'), ''),
    fractionDigits: fractionPart.replaceAll(RegExp(r'[^0-9]'), ''),
    decimalSeparatorIndex: decimalIndex,
  );
}

List<int> _groupingCommaOffsets(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^0-9,.]'), '');
  final commaIndices = <int>[];
  for (var index = 0; index < sanitized.length; index++) {
    if (sanitized[index] == ',') commaIndices.add(index);
  }
  if (commaIndices.isEmpty) return const [];

  final lastComma = commaIndices.last;
  final lastPeriod = sanitized.lastIndexOf('.');
  final lastCommaIsDecimal =
      lastComma > lastPeriod &&
      !RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(sanitized);

  final groupingIndices = lastCommaIsDecimal
      ? commaIndices.take(commaIndices.length - 1)
      : commaIndices;
  return groupingIndices
      .map(
        (index) => sanitized
            .substring(0, index)
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length,
      )
      .toList();
}

String _removeExistingGroupingCommas(String oldValue, String newValue) {
  final offsets = _groupingCommaOffsets(oldValue);
  if (offsets.isEmpty) return newValue;

  final result = StringBuffer();
  var digitCount = 0;
  for (final character in newValue.split('')) {
    if (character == ',' && offsets.contains(digitCount)) continue;
    result.write(character);
    if (RegExp(r'[0-9]').hasMatch(character)) digitCount++;
  }
  return result.toString();
}

String formatCurrencyText(String value) {
  final parts = _currencyParts(value);
  if (parts.integerDigits.isEmpty && !parts.hasDecimal) return '';
  final integerDigits = parts.integerDigits;

  final groupedInteger = integerDigits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  return !parts.hasDecimal
      ? groupedInteger
      : '$groupedInteger.${parts.fractionDigits}';
}

double? parseCurrencyText(String value) {
  final parts = _currencyParts(value);
  if (parts.integerDigits.isEmpty && !parts.hasDecimal) return null;
  final normalized = parts.hasDecimal
      ? '${parts.integerDigits}.${parts.fractionDigits}'
      : parts.integerDigits;
  return double.tryParse(normalized);
}

class CurrencyInputFormatter extends TextInputFormatter {
  const CurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sourceText = _removeExistingGroupingCommas(
      oldValue.text,
      newValue.text,
    );
    final formatted = formatCurrencyText(sourceText);
    final cursorOffset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final source = sourceText.replaceAll(RegExp(r'[^0-9,.]'), '');
    final sourceBeforeCursor = _removeExistingGroupingCommas(
      oldValue.text,
      newValue.text.substring(0, cursorOffset),
    ).replaceAll(RegExp(r'[^0-9,.]'), '');
    final parts = _currencyParts(source);
    final decimalBeforeCursor =
        parts.hasDecimal &&
        sourceBeforeCursor.length > parts.decimalSeparatorIndex;
    final integerDigitsBeforeCursor =
        (decimalBeforeCursor
                ? sourceBeforeCursor.substring(0, parts.decimalSeparatorIndex)
                : sourceBeforeCursor)
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length;

    final formattedInteger = formatted.split('.').first;
    var cursor = 0;
    var digitsSeen = 0;
    while (cursor < formattedInteger.length &&
        digitsSeen < integerDigitsBeforeCursor) {
      if (RegExp(r'[0-9]').hasMatch(formattedInteger[cursor])) {
        digitsSeen++;
      }
      cursor++;
    }

    if (decimalBeforeCursor) {
      final formattedDecimalIndex = formatted.indexOf('.');
      final fractionDigitsBeforeCursor = sourceBeforeCursor
          .substring(parts.decimalSeparatorIndex + 1)
          .replaceAll(RegExp(r'[^0-9]'), '')
          .length;
      cursor = formattedDecimalIndex + 1 + fractionDigitsBeforeCursor;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
