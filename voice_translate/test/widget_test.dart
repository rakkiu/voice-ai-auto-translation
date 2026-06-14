import 'package:flutter_test/flutter_test.dart';
import 'package:voice_translate/core/models/language.dart';

void main() {
  test('Language enum opposite', () {
    expect(Language.vi.opposite, Language.en);
    expect(Language.en.opposite, Language.vi);
  });

  test('Language properties', () {
    expect(Language.vi.locale, 'vi-VN');
    expect(Language.en.locale, 'en-US');
    expect(Language.vi.whisperCode, 'vi');
    expect(Language.en.whisperCode, 'en');
  });
}
