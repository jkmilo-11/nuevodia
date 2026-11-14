import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuevodia/widgets/currency_input_formatter.dart';

void main() {
  const formatter = CurrencyInputFormatter();

  test('groups thousands and preserves decimal values', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(
        text: '1234567.89',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );

    expect(result.text, '1,234,567.89');
    expect(parseCurrencyText(result.text), 1234567.89);
  });

  test('keeps a trailing decimal separator while typing', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '1,234',
        selection: TextSelection.collapsed(offset: 5),
      ),
      const TextEditingValue(
        text: '1,234.',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(result.text, '1,234.');
  });

  test('allows appending digits after an inserted thousands separator', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '1,234',
        selection: TextSelection.collapsed(offset: 5),
      ),
      const TextEditingValue(
        text: '1,2345',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );

    expect(result.text, '12,345');
  });

  test('accepts a comma as a decimal separator', () {
    expect(formatCurrencyText('1234,56'), '1,234.56');
    expect(parseCurrencyText('1,234.56'), 1234.56);
  });
}
